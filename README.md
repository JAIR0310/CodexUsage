# Codex Usage

A lightweight native macOS utility that displays the remaining **5-hour** and **7-day** Codex usage limits, together with their reset times.

![Codex Usage R19 preview](Design/VisualValidation/R19-Final/r19_proxy_candidate.png)

> Community project. Not affiliated with, endorsed by, or maintained by OpenAI.

[简体中文说明](README.zh-CN.md)

## Features

- Shows only the two Codex quota windows that matter here: 5-hour and 7-day.
- Refreshes once per second while preserving the last valid value if a read temporarily fails.
- Uses the Codex App Server bundled with the installed ChatGPT desktop app; it does **not** modify ChatGPT.app.
- ChatGPT.app does **not** need to be running; Codex Usage launches its own separate Codex App Server child process from the installed bundle.
- Native SwiftUI/AppKit interface with liquid-titanium glass styling and deterministic R19 edge optics.
- Resizable native macOS window with no project-defined minimum window size.
- User-level installation to `~/Applications/Codex Usage.app`; no administrator password is required.
- Supports Apple Silicon and Intel Macs when built locally on the target Mac.

## Requirements

- macOS 14 or later.
- ChatGPT desktop app installed at `/Applications/ChatGPT.app`.
- A working Codex login in the ChatGPT desktop app.
- Xcode Command Line Tools / macOS Swift toolchain available through `xcrun`.

The app locates the bundled executable at:

```text
/Applications/ChatGPT.app/Contents/Resources/codex
```

and starts `codex app-server --stdio` as a private child process. It reads `account/rateLimits/read` and identifies the 5-hour and 7-day windows by their durations (`300` and `10080` minutes), rather than relying on response order.

## Install from source

Clone the repository, then run:

```zsh
cd CodexUsage
xattr -dr com.apple.quarantine . 2>/dev/null || true
chmod u+x build_macos.command install_macos.command
./install_macos.command
```

The installer:

1. builds and ad-hoc signs the app locally;
2. verifies the bundle metadata and signature;
3. stages the new build before touching an existing installation;
4. directly replaces `~/Applications/Codex Usage.app` without creating a backup copy;
5. verifies the installed app and launches it.

It does not write to `/Applications` and does not request `sudo`.

## Build only

```zsh
chmod u+x build_macos.command
./build_macos.command
```

The resulting app is created at:

```text
build/Codex Usage.app
```

## Tests and validation

Core and transport tests:

```zsh
swift test
```

Release consistency and current R19 visual implementation checks:

```zsh
python3 Tools/check_release_consistency.py
python3 Tools/validate_layout.py --tokens Design/VisualTokens.json
python3 Tools/validate_glass_material.py
python3 Tools/validate_edge_optics.py
```

The public repository keeps the current R19 visual tokens, R19 optical field, deterministic proxy template, approved R19 proxy candidate, and final evaluator report. Historical experiments and old-version validation assets are intentionally excluded.

## Project structure

```text
Sources/                      Swift application, data model and transport
Tests/                        Swift package tests
Design/VisualTokens.json      Current layout/material parameters
Design/R19OpticalField.json   Frozen R19 optical field parameters
Design/VisualValidation/      Current proxy/final validation evidence only
Tools/                        Generators and current validation scripts
Packaging/Info.plist          macOS application metadata
build_macos.command           Local build + ad-hoc signing
install_macos.command         User-level overwrite installer
```

## Privacy and security

Codex Usage does not ask for or store your OpenAI password, API key, or session token. Authentication remains owned by the installed ChatGPT/Codex environment. The utility starts its own local Codex App Server child process and reads rate-limit data from it. See [SECURITY.md](SECURITY.md) for vulnerability reporting guidance.

## Bundle identity

The public build uses the neutral bundle identifier:

```text
app.codexusage.CodexUsage
```

No personal username or local developer identifier is embedded in the public project metadata.

## License

MIT License. See [LICENSE](LICENSE).
