#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
tokens=json.loads((ROOT/'Design/VisualTokens.json').read_text())
swift=(ROOT/'Sources/CodexUsage/TitaniumViews.swift').read_text()
proxy=(ROOT/'Design/VisualValidation/proxy_template.html').read_text()
report=json.loads((ROOT/'Design/VisualValidation/R19-Final/edge_optics_report.json').read_text())
errs=[]
def ck(v,m):
    if not v: errs.append(m)
for side in ('left','right'):
    c=tokens['cards'][side]
    ck(c['outerGlowOpacity'] <= 0.08, f'{side}: legacy uniform outer glow too strong')
    ck(c['borderGlowOpacity'] == 0.0, f'{side}: legacy card border glow must be disabled')
    ck(c['borderSpecularOpacity'] == 0.0, f'{side}: legacy card specular must be disabled')
field=tokens.get('r19OpticalField',{}).get('fields',{}).get('panel',{})
ck(field.get('rank')==64,'R19 calibrated rank-64 optical field missing')
ck('R19OpticalFieldOverlay()' in swift,'Swift R19 optical-field integration missing')
ck('R18GlassCardOptics(style: style, accent: accent)' not in swift,'legacy per-card optics still active')
ck('r19-optics-field' in proxy,'proxy R19 optical-field canvas missing')
ck(report.get('pass') is True,'approved edge optics evaluator v2 report is not PASS')
for region in ('ring','left_card','right_card'):
    ck(report.get('region_pass',{}).get(region) is True,f'{region}: evaluator v2 not PASS')
if errs:
    print('EDGE_OPTICS_FAIL')
    for e in errs: print('-',e)
    raise SystemExit(1)
print('EDGE_OPTICS_PASS')
print('approved evaluator v2: ring + left_card + right_card PASS; R19 field integrated in proxy and Swift')
