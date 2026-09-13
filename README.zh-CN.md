# Codex Usage

一个轻量、原生的 macOS 小工具，用于显示 Codex 的 **5 小时额度**与 **7 天额度**剩余百分比和重置时间。

![Codex Usage R19 预览](Design/VisualValidation/R19-Final/r19_proxy_candidate.png)

> 社区项目，与 OpenAI 无隶属、背书或官方维护关系。

## 功能

- 只显示 5 小时、7 天两组 Codex 额度及重置时间。
- 每 1 秒刷新一次；单次读取失败时保留最近一次有效值。
- 复用 ChatGPT 桌面 App 内置的 Codex App Server，不修改 `/Applications/ChatGPT.app`。
- 原生 SwiftUI/AppKit 界面，使用液态钛金属、透明玻璃与 R19 边缘光学效果。
- 保留 macOS 原生拖动与缩放，并取消工程人为设置的最小窗口尺寸限制。
- 安装到当前用户的 `~/Applications/Codex Usage.app`，不需要管理员密码。
- 在目标 Mac 本机构建时支持 Apple Silicon 与 Intel 架构。

## 系统要求

- macOS 14 或更高版本。
- ChatGPT 桌面 App 安装在 `/Applications/ChatGPT.app`。
- ChatGPT/Codex 已正常登录。
- 已安装可通过 `xcrun` 调用的 macOS Swift 工具链。

程序使用：

```text
/Applications/ChatGPT.app/Contents/Resources/codex
```

启动独立的 `codex app-server --stdio` 子进程，通过 `account/rateLimits/read` 读取额度；5 小时和 7 天额度严格按 `300` / `10080` 分钟窗口识别，不依赖响应中的固定顺序。

## 从源码安装

克隆仓库后执行：

```zsh
cd CodexUsage
xattr -dr com.apple.quarantine . 2>/dev/null || true
chmod u+x build_macos.command install_macos.command
./install_macos.command
```

安装脚本会：

1. 在本机编译并进行 ad-hoc 临时签名；
2. 校验 App Bundle 元数据与签名；
3. 在动现有安装之前先准备并验证新版暂存副本；
4. 直接覆盖 `~/Applications/Codex Usage.app`，不生成旧版备份；
5. 再次验签并启动新版。

不会写入系统级 `/Applications`，也不会调用 `sudo`。

## 仅构建

```zsh
chmod u+x build_macos.command
./build_macos.command
```

生成位置：

```text
build/Codex Usage.app
```

## 测试与验证

核心与传输层测试：

```zsh
swift test
```

R19 当前发布一致性及视觉实现检查：

```zsh
python3 Tools/check_release_consistency.py
python3 Tools/validate_layout.py --tokens Design/VisualTokens.json
python3 Tools/validate_glass_material.py
python3 Tools/validate_edge_optics.py
```

公开仓库仅保留当前 R19 的视觉参数、R19 光学场、确定性代理模板、最终代理候选与最终评测报告；旧版本、历史实验和中间验证图片已从公开工程中清理。

## 隐私

Codex Usage 不要求、记录或保存 OpenAI 密码、API Key 或登录 Token。身份认证仍由本机已安装的 ChatGPT/Codex 环境负责。本工具只启动自己的本地 Codex App Server 子进程并读取额度数据。

## Bundle ID

公开工程统一使用中性的 Bundle ID：

```text
app.codexusage.CodexUsage
```

工程元数据中不包含个人用户名或本地开发者 ID。

## 许可证

MIT License（MIT 许可证），见 [LICENSE](LICENSE)。
