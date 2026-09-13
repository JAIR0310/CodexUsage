#!/usr/bin/env python3
from pathlib import Path
import json
import plistlib
import sys

root = Path(__file__).resolve().parents[1]
errors: list[str] = []


def require(path: str) -> Path:
    p = root / path
    if not p.exists():
        errors.append(f"missing: {path}")
    return p


info_path = require("Packaging/Info.plist")
if info_path.exists():
    info = plistlib.loads(info_path.read_bytes())
    expected = {
        "CFBundleIdentifier": "app.codexusage.CodexUsage",
        "CFBundleVersion": "19",
        "CFBundleShortVersionString": "1.12.0",
        "LSMinimumSystemVersion": "14.0",
    }
    for key, value in expected.items():
        if str(info.get(key)) != value:
            errors.append(f"{key}: expected {value!r}, got {info.get(key)!r}")

for required in [
    "README.md",
    "README.zh-CN.md",
    "LICENSE",
    "SECURITY.md",
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    "PRIVACY.md",
    "Package.swift",
    "build_macos.command",
    "install_macos.command",
    "Design/VisualTokens.json",
    "Design/R19OpticalField.json",
    "Design/VisualValidation/proxy_template.html",
    "Design/VisualValidation/R19-Final/r19_proxy_candidate.png",
    "Design/VisualValidation/R19-Final/edge_optics_report.json",
]:
    require(required)

visual_path = root / "Design/VisualTokens.json"
field_path = root / "Design/R19OpticalField.json"
if visual_path.exists() and field_path.exists():
    visual = json.loads(visual_path.read_text())
    field = json.loads(field_path.read_text())
    if "r19Optics" not in visual:
        errors.append("VisualTokens.json missing r19Optics")
    if "r19OpticalField" not in visual:
        errors.append("VisualTokens.json missing r19OpticalField")
    if "r18Optics" in visual:
        errors.append("VisualTokens.json still contains r18Optics")
    if visual.get("r19OpticalField") != field:
        errors.append("VisualTokens optical field differs from Design/R19OpticalField.json")
    if field.get("fields", {}).get("panel", {}).get("rank") != 64:
        errors.append("R19 panel optical-field rank is not 64")

swift = (root / "Sources/CodexUsage/TitaniumViews.swift").read_text()
generated = (root / "Sources/CodexUsage/VisualTokens.generated.swift").read_text()
field_swift = (root / "Sources/CodexUsage/R19OpticalField.generated.swift").read_text()
generator = (root / "Tools/generate_visual_tokens.py").read_text()

for label, text in [
    ("generator", generator),
    ("TitaniumViews.swift", swift),
    ("VisualTokens.generated.swift", generated),
]:
    if "R18Optics" in text:
        errors.append(f"{label} still contains R18Optics")

if "R19Optics" not in generator or "R19Optics" not in generated:
    errors.append("R19Optics is not consistently present in generator/generated output")
if "R19OpticalFieldOverlay" not in swift or "R19OpticalFieldOverlay" not in field_swift:
    errors.append("R19 optical-field overlay is not integrated")
if "R18GlassCardOptics(style: style, accent: accent)" in swift:
    errors.append("legacy per-card optics overlay is still active")
if "vDSP_mmul" not in field_swift or "multiplyAttenuation" not in field_swift:
    errors.append("generated R19 optical-field implementation is incomplete")

# Public build intentionally has no project-defined minimum window size.
app_swift = (root / "Sources/CodexUsage/CodexUsageApp.swift").read_text()
for marker in ["minWidth:", "minHeight:", "window.minSize", "contentMinSize"]:
    if marker in swift or marker in app_swift:
        errors.append(f"project-defined minimum window constraint still present: {marker}")

build = (root / "build_macos.command").read_text()
install = (root / "install_macos.command").read_text()
for label, text in [("build_macos.command", build), ("install_macos.command", install)]:
    if "app.codexusage.CodexUsage" not in text:
        errors.append(f"{label} missing public bundle identifier")

if "R19OpticalField.generated.swift" not in build:
    errors.append("build_macos.command does not compile R19 optical field")
if "sudo" in install:
    errors.append("install_macos.command must not require sudo/admin password")
if "$HOME/Applications" not in install:
    errors.append("install_macos.command must install into user-level ~/Applications")
if ".backup-" in install or "backup-" in install:
    errors.append("install_macos.command must not create old-app backup copies")
if 'EXPECTED_BUILD="19"' not in install or 'EXPECTED_MARKETING="1.12.0"' not in install:
    errors.append("install_macos.command release values are stale")

report_path = root / "Design/VisualValidation/R19-Final/edge_optics_report.json"
if report_path.exists():
    report = json.loads(report_path.read_text())
    if report.get("pass") is not True:
        errors.append("approved evaluator report is not PASS")
    for region in ("ring", "left_card", "right_card"):
        if report.get("region_pass", {}).get(region) is not True:
            errors.append(f"approved evaluator report region not PASS: {region}")

# Public tree should not contain internal history or personal identifiers.
if (root / "History").exists():
    errors.append("internal History directory must not be present in the public tree")
for path in root.rglob("*"):
    if path.resolve() == Path(__file__).resolve():
        continue
    if not path.is_file() or path.suffix.lower() in {".png", ".jpg", ".jpeg", ".zip"}:
        continue
    try:
        text = path.read_text(errors="ignore")
    except Exception:
        continue
    if "/Users/" in text or "/home/" in text:
        errors.append(f"local absolute path found: {path.relative_to(root)}")

if errors:
    print("FAIL")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("PASS: public R19 release consistency")
