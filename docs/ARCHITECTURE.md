# Architecture

Codex Usage is intentionally small and split into three layers:

- `CodexUsageCore`: rate-limit data structures and parsing.
- `CodexUsageTransport`: newline-delimited JSON-RPC communication with `codex app-server --stdio`.
- `CodexUsage`: native macOS UI, window configuration, polling view model, and R19 visual rendering.

The application does not inject into or modify ChatGPT.app. It locates ChatGPT's bundled `codex` executable, creates a separate App Server child process, initializes it, and periodically calls `account/rateLimits/read`.

The UI and transport lifecycles are separated: the animation layer does not drive rate-limit requests, and a temporary read failure does not clear the last valid values.

## Visual system

`Design/VisualTokens.json` is the current layout/material source. `Design/R19OpticalField.json` contains the frozen 720×408 rank-64 optical field. The corresponding Swift files are generated into `Sources/CodexUsage/`.

The native renderer reconstructs the optical field using Accelerate/vDSP and applies Multiply/Screen blending in SwiftUI. The deterministic Chromium proxy is retained only as a validation aid; it is not a macOS runtime dependency.
