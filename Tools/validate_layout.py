#!/usr/bin/env python3
from __future__ import annotations
import argparse
import json
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument("--tokens", required=True)
a = ap.parse_args()
t = json.loads(Path(a.tokens).read_text())
DW = float(t["canvas"]["width"])
DH = float(t["canvas"]["height"])

boxes = {
    "header_ring": (t["header"]["x"], t["header"]["y"], t["header"]["ringSize"], t["header"]["ringSize"]),
    "left_card": (t["cards"]["left"]["x"], t["cards"]["left"]["y"], t["cards"]["left"]["w"], t["cards"]["left"]["h"]),
    "right_card": (t["cards"]["right"]["x"], t["cards"]["right"]["y"], t["cards"]["right"]["w"], t["cards"]["right"]["h"]),
    "divider": (t["divider"]["x"], t["divider"]["y"], 1, t["divider"]["h"]),
}

for name, (x, y, w, h) in boxes.items():
    assert x >= 0 and y >= 0 and x + w <= DW and y + h <= DH, (
        f"{name} outside design canvas: {(x, y, w, h)} vs {(DW, DH)}"
    )

# There is no project-defined minimum window size. Verify aspect-fit behavior
# across both very small windows and normal acceptance sizes.
for W, H in [
    (160, 120),
    (240, 160),
    (320, 200),
    (400, 250),
    (500, 304),
    (560, 340),
    (720, 408),
    (960, 540),
    (1200, 500),
    (1200, 800),
]:
    s = min(W / DW, H / DH)
    ox = (W - DW * s) / 2
    oy = (H - DH * s) / 2
    for name, (x, y, w, h) in boxes.items():
        X = ox + x * s
        Y = oy + y * s
        R = X + w * s
        B = Y + h * s
        assert X >= -1e-6 and Y >= -1e-6 and R <= W + 1e-6 and B <= H + 1e-6, (
            f"{name} clipped at {W}x{H}: {(X, Y, R, B)}"
        )
    print(f"{W}x{H}=PASS scale={s:.6f} origin=({ox:.3f},{oy:.3f})")

print("LAYOUT_PASS")
