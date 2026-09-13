# Privacy

Codex Usage is designed to operate locally.

- It does not ask for an OpenAI password or API key.
- It does not maintain its own login database.
- It does not persist Codex account identifiers or usage history.
- It reads current rate-limit information through a local Codex App Server child process started from the Codex executable bundled with ChatGPT for macOS.
- It does not modify the ChatGPT application bundle.

Network behavior performed by the Codex App Server is governed by the installed ChatGPT/Codex software and the user's existing authenticated session.
