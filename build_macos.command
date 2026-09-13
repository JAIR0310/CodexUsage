#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/Codex Usage.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
MODULES="$BUILD/modules"

fail() {
  printf 'FAIL：%s\n' "$1" >&2
  return 1
}

printf '%s\n' '0/5 检查 macOS 构建环境...'
[ "$(uname -s)" = "Darwin" ] || fail '必须在 macOS 上构建。'
command -v xcrun >/dev/null 2>&1 || fail '未找到 xcrun。'
command -v codesign >/dev/null 2>&1 || fail '未找到 codesign。'
command -v plutil >/dev/null 2>&1 || fail '未找到 plutil。'
command -v otool >/dev/null 2>&1 || fail '未找到 otool。'
command -v pbcopy >/dev/null 2>&1 || fail '未找到 pbcopy。'
xcrun --sdk macosx --find swiftc >/dev/null 2>&1 || fail '未找到 macOS Swift 编译器。'
plutil -lint "$ROOT/Packaging/Info.plist" >/dev/null || fail 'Info.plist 校验失败。'

rm -rf "$BUILD"
mkdir -p "$MACOS" "$MODULES"

SDK="$(xcrun --sdk macosx --show-sdk-path)"
HOST_ARCH="$(uname -m)"
ARCH="${CODEX_USAGE_ARCH:-$HOST_ARCH}"
case "$ARCH" in
  arm64|x86_64) ;;
  *) fail "不支持的 Mac 架构：$ARCH" ;;
esac
TARGET="${ARCH}-apple-macosx14.0"
printf '目标架构：%s（当前主机：%s）\n' "$ARCH" "$HOST_ARCH"

printf '%s\n' '1/5 编译核心模块为静态对象...'
xcrun --sdk macosx swiftc \
  -O \
  -swift-version 6 \
  -parse-as-library \
  -sdk "$SDK" \
  -target "$TARGET" \
  -emit-object \
  -emit-module \
  -module-name CodexUsageCore \
  -emit-module-path "$MODULES/CodexUsageCore.swiftmodule" \
  "$ROOT/Sources/CodexUsageCore/RateLimitModels.swift" \
  -o "$BUILD/CodexUsageCore.o"

printf '%s\n' '2/5 编译传输模块为静态对象...'
xcrun --sdk macosx swiftc \
  -O \
  -swift-version 6 \
  -parse-as-library \
  -sdk "$SDK" \
  -target "$TARGET" \
  -I "$MODULES" \
  -emit-object \
  -emit-module \
  -module-name CodexUsageTransport \
  -emit-module-path "$MODULES/CodexUsageTransport.swiftmodule" \
  "$ROOT/Sources/CodexUsageTransport/CodexAppServerClient.swift" \
  -o "$BUILD/CodexUsageTransport.o"

printf '%s\n' '3/5 编译并链接原生 macOS App...'
xcrun --sdk macosx swiftc \
  -O \
  -swift-version 6 \
  -parse-as-library \
  -target "$TARGET" \
  -sdk "$SDK" \
  -I "$MODULES" \
  "$ROOT/Sources/CodexUsage/CodexUsageApp.swift" \
  "$ROOT/Sources/CodexUsage/CodexExecutableLocator.swift" \
  "$ROOT/Sources/CodexUsage/RateLimitViewModel.swift" \
  "$ROOT/Sources/CodexUsage/VisualTokens.generated.swift" \
  "$ROOT/Sources/CodexUsage/R19OpticalField.generated.swift" \
  "$ROOT/Sources/CodexUsage/TitaniumViews.swift" \
  "$BUILD/CodexUsageCore.o" \
  "$BUILD/CodexUsageTransport.o" \
  -framework AppKit \
  -framework SwiftUI \
  -o "$MACOS/CodexUsage"

cp "$ROOT/Packaging/Info.plist" "$CONTENTS/Info.plist"
chmod +x "$MACOS/CodexUsage"

printf '%s\n' '4/5 临时本机签名...'
codesign --force --sign - "$APP"

printf '%s\n' '5/5 完整性校验...'
codesign --verify --deep --strict --verbose=2 "$APP"
plutil -lint "$CONTENTS/Info.plist" >/dev/null
[ "$(plutil -extract CFBundleExecutable raw "$CONTENTS/Info.plist")" = 'CodexUsage' ] \
  || fail 'CFBundleExecutable 与主程序不一致。'
[ "$(plutil -extract CFBundleIdentifier raw "$CONTENTS/Info.plist")" = 'app.codexusage.CodexUsage' ] \
  || fail 'CFBundleIdentifier 不符合工程冻结值。'
[ "$(plutil -extract CFBundleVersion raw "$CONTENTS/Info.plist")" = '19' ] \
  || fail 'CFBundleVersion 不是 R19 冻结值 19。'
[ "$(plutil -extract CFBundleShortVersionString raw "$CONTENTS/Info.plist")" = '1.12.0' ] \
  || fail 'CFBundleShortVersionString 不是 R19 冻结值 1.12.0。'
[ -x "$MACOS/CodexUsage" ] || fail 'App 主程序不可执行。'

if find "$MACOS" -maxdepth 1 -type f ! -name 'CodexUsage' -print -quit | grep -q .; then
  fail 'Contents/MacOS 中出现了非预期运行库。'
fi

if find "$APP" -type f \( -name '*.dylib' -o -name '*.so' \) -print -quit | grep -q .; then
  fail 'App Bundle 中出现了非预期动态运行库。'
fi

if find "$APP" -type f \( -name '*.metallib' -o -name '*.air' \) -print -quit | grep -q .; then
  fail 'App Bundle 中不应再包含 Metal Toolchain 产物。'
fi

if otool -L "$MACOS/CodexUsage" | tail -n +2 | grep -F "$BUILD" >/dev/null; then
  fail '主程序仍引用构建目录路径。'
fi

printf '\nPASS：构建、签名、Bundle 完整性校验完成\n%s\n' "$APP"
printf '%s' "$APP" | pbcopy
