# Changelog

## 1.12.0 (R19)

- Added a repository-owned macOS app icon and wired it into the built App bundle.
- Removed unused legacy R18 card/ring rendering structs without changing the active R19 renderer.
- Replaced legacy per-card uniform edge glow with the R19 full-panel optical field.
- Added non-uniform warm/cool localized reflections and bloom around the ring and quota cards.
- Preserved native macOS drag/resize behavior and removed the project-defined minimum window size.
- Kept 1-second Codex rate-limit refresh, last-known-good fallback, and duration-based 5-hour / 7-day window detection.
- Public-source packaging uses the neutral bundle identifier `app.codexusage.CodexUsage`.
- Installer performs verified user-level overwrite installation without creating an old-app backup.
