#!/usr/bin/env python3
"""Deterministic Chromium screenshot helper for UI visual proxy validation."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from playwright.sync_api import sync_playwright

TOKEN_MARKER = "__VISUAL_TOKENS_JSON__"
TIME_MARKER = "__SNAPSHOT_TIME_SECONDS__"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--html", required=True, help="HTML proxy template")
    ap.add_argument("--output", required=True, help="PNG output")
    ap.add_argument("--tokens", help="Optional JSON visual tokens")
    ap.add_argument("--width", type=int, required=True)
    ap.add_argument("--height", type=int, required=True)
    ap.add_argument("--scale", type=float, default=1.0)
    ap.add_argument("--time", type=float, default=0.0, help="Fixed animation time in seconds")
    ap.add_argument("--selector", default="#snapshot-root")
    ap.add_argument("--wait-ms", type=int, default=100)
    args = ap.parse_args()

    html_path = Path(args.html).resolve()
    html = html_path.read_text(encoding="utf-8")

    tokens = {}
    if args.tokens:
        tokens = json.loads(Path(args.tokens).read_text(encoding="utf-8"))
    html = html.replace(TOKEN_MARKER, json.dumps(tokens, ensure_ascii=False))
    html = html.replace(TIME_MARKER, repr(float(args.time)))

    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        chromium_path = "/usr/bin/chromium"
        browser = p.chromium.launch(headless=True, executable_path=chromium_path)
        page = browser.new_page(
            viewport={"width": args.width, "height": args.height},
            device_scale_factor=args.scale,
        )
        # Use set_content instead of file:// navigation because some sandboxed
        # environments block local-file URLs even when Chromium is available.
        page.set_content(html, wait_until="load")
        page.wait_for_timeout(args.wait_ms)
        locator = page.locator(args.selector)
        if locator.count() > 0:
            locator.first.screenshot(path=str(output), animations="disabled")
        else:
            page.screenshot(path=str(output), full_page=False, animations="disabled")
        browser.close()

    print(output)


if __name__ == "__main__":
    main()
