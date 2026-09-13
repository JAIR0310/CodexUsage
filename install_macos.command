#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_SCRIPT="$ROOT/build_macos.command"
BUILT_APP="$ROOT/build/Codex Usage.app"
INSTALL_DIR="$HOME/Applications"
INSTALL_APP="$INSTALL_DIR/Codex Usage.app"
STAGED_APP="$INSTALL_DIR/.Codex Usage.app.installing"
SYSTEM_APP="/Applications/Codex Usage.app"
EXPECTED_BUNDLE_ID="app.codexusage.CodexUsage"
EXPECTED_BUILD="19"
EXPECTED_MARKETING="1.12.0"

fail() {
  printf 'FAIL：%s\n' "$1" >&2
  exit 1
}

verify_app() {
  local app="$1"
  local info="$app/Contents/Info.plist"

  [ -d "$app" ] || fail "未找到 App：$app"
  codesign --verify --deep --strict --verbose=2 "$app"
  [ "$(plutil -extract CFBundleIdentifier raw "$info")" = "$EXPECTED_BUNDLE_ID" ] || fail 'Bundle Identifier 不一致。'
  [ "$(plutil -extract CFBundleVersion raw "$info")" = "$EXPECTED_BUILD" ] || fail 'CFBundleVersion 不一致。'
  [ "$(plutil -extract CFBundleShortVersionString raw "$info")" = "$EXPECTED_MARKETING" ] || fail 'CFBundleShortVersionString 不一致。'
  [ -x "$app/Contents/MacOS/CodexUsage" ] || fail 'App 主程序不可执行。'
}

printf '%s\n' '0/7 检查 macOS 安装环境...'
[ "$(uname -s)" = "Darwin" ] || fail '必须在 macOS 上执行。'
for cmd in xcrun codesign plutil ditto open pbcopy xattr chmod mkdir mv rm pgrep kill; do
  command -v "$cmd" >/dev/null 2>&1 || fail "未找到 $cmd。"
done
xcrun --sdk macosx --find swiftc >/dev/null 2>&1 || fail '未找到 macOS Swift 编译器。'
# 本安装链路不使用管理员提权，也不写入系统级 /Applications。
# 用户级安装位置：~/Applications/Codex Usage.app

printf '%s\n' '1/7 解除工程安全隔离并准备构建脚本...'
xattr -dr com.apple.quarantine "$ROOT" 2>/dev/null || true
chmod u+x "$BUILD_SCRIPT"

printf '%s\n' '2/7 构建并验证 R19 App...'
"$BUILD_SCRIPT"
verify_app "$BUILT_APP"

printf '%s\n' '3/7 准备无备份覆盖安装的暂存副本...'
mkdir -p "$INSTALL_DIR"
[ -d "$INSTALL_DIR" ] || fail "无法创建：$INSTALL_DIR"
[ -w "$INSTALL_DIR" ] || fail "当前用户无权写入：$INSTALL_DIR"
rm -rf "$STAGED_APP"
ditto "$BUILT_APP" "$STAGED_APP"
xattr -dr com.apple.quarantine "$STAGED_APP" 2>/dev/null || true
chmod u+x "$STAGED_APP/Contents/MacOS/CodexUsage"
verify_app "$STAGED_APP"

printf '%s\n' '4/7 关闭当前用户级旧实例（若正在运行）...'
OLD_EXE="$INSTALL_APP/Contents/MacOS/CodexUsage"
PIDS="$(pgrep -f "$OLD_EXE" 2>/dev/null || true)"
if [ -n "$PIDS" ]; then
  printf '正在关闭：%s\n' "$PIDS"
  for pid in ${(f)PIDS}; do
    kill -TERM "$pid" 2>/dev/null || true
  done
  for _ in {1..20}; do
    pgrep -f "$OLD_EXE" >/dev/null 2>&1 || break
    sleep 0.1
  done
  PIDS="$(pgrep -f "$OLD_EXE" 2>/dev/null || true)"
  if [ -n "$PIDS" ]; then
    for pid in ${(f)PIDS}; do
      kill -KILL "$pid" 2>/dev/null || true
    done
  fi
fi

printf '%s\n' '5/7 直接覆盖 ~/Applications/Codex Usage.app（不创建备份）...'
rm -rf "$INSTALL_APP"
mv "$STAGED_APP" "$INSTALL_APP"
xattr -dr com.apple.quarantine "$INSTALL_APP" 2>/dev/null || true
chmod u+x "$INSTALL_APP/Contents/MacOS/CodexUsage"

if [ -e "$SYSTEM_APP" ]; then
  printf '提示：检测到系统级安装：%s\n' "$SYSTEM_APP"
  printf '%s\n' '本脚本不会修改它，也不会请求管理员密码；本次只覆盖用户级 R19。'
fi

printf '%s\n' '6/7 覆盖安装后完整性验证...'
verify_app "$INSTALL_APP"

printf '%s\n' '7/7 启动用户级 R19...'
open -n "$INSTALL_APP"
printf '%s\n%s\n' "$ROOT" "$INSTALL_APP" | pbcopy
printf '\nPASS：R19 已构建、无备份覆盖安装并启动，全程无需管理员密码。\n工程：%s\nApp：%s\n工程路径和 App 路径已复制到剪贴板。\n' "$ROOT" "$INSTALL_APP"
