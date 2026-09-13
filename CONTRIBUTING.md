# Contributing

Contributions are welcome.

## Before opening a pull request

1. Keep changes focused and avoid unrelated visual or data-layer modifications.
2. Run `swift test`.
3. Run the release/visual consistency checks documented in `README.md`.
4. Do not commit credentials, local absolute paths, build products, archived app bundles, or historical visual experiment outputs.
5. For UI changes, include a clear before/after description and explain which visual validation checks were run.

## Generated files

`Sources/CodexUsage/VisualTokens.generated.swift` and `Sources/CodexUsage/R19OpticalField.generated.swift` are generated artifacts. When changing their source JSON, regenerate them with the corresponding scripts in `Tools/` and commit both the source and generated output.
