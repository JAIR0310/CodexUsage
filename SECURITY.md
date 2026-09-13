# Security Policy

## Supported version

Security fixes are applied to the current public release line. Older development snapshots are not supported.

## Reporting a vulnerability

Please do not open a public issue for a vulnerability that could expose credentials, authentication state, private local data, or enable code execution.

Until a dedicated security contact is configured for the repository, use GitHub's private vulnerability reporting feature if it is enabled. If private reporting is unavailable, avoid publishing exploit details and contact the repository maintainer through a private channel first.

## Scope

Codex Usage does not collect OpenAI passwords, API keys, or session tokens. It relies on the locally installed ChatGPT/Codex environment and communicates with a child `codex app-server --stdio` process.
