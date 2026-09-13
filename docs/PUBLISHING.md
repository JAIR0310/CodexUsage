# GitHub publishing checklist

Recommended initial repository settings:

- Repository name: `CodexUsage`
- Visibility: Public
- Default branch: `main`
- Description: `A standalone macOS app—independent of ChatGPT—that displays your current Codex quota and updates it in real time.`
- Suggested topics: `macos`, `swift`, `swiftui`, `codex`, `usage-monitor`, `appkit`
- Do not initialize the remote with another README, LICENSE, or .gitignore; this source tree already contains them.

Before the first push:

1. Run the checks in `README.md` on macOS.
2. Confirm `git status` contains only intended source files.
3. Search once for credentials and local absolute paths.
4. Confirm the repository uses MIT License and the neutral bundle identifier `app.codexusage.CodexUsage`.
5. Enable GitHub private vulnerability reporting if desired.
