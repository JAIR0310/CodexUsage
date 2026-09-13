#!/usr/bin/env python3
from __future__ import annotations
import json, re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
tokens = json.loads((ROOT/'Design/VisualTokens.json').read_text())
swift = (ROOT/'Sources/CodexUsage/TitaniumViews.swift').read_text()
field_swift = (ROOT/'Sources/CodexUsage/R19OpticalField.generated.swift').read_text()
html = (ROOT/'Design/VisualValidation/proxy_template.html').read_text()
errors=[]
def check(cond,msg):
    if not cond: errors.append(msg)

for side in ('left','right'):
    c=tokens['cards'][side]
    check(0.2 <= c['glassMaterialOpacity'] <= 0.8, f'{side}: glassMaterialOpacity')
    check(c['glassTintOpacity'] <= 0.15, f'{side}: glassTintOpacity too opaque')
    check(c['outerGlowOpacity'] <= 0.08, f'{side}: uniform outer glow must stay suppressed')
    for key in ('c1','c2','c3'):
        m=re.fullmatch(r'rgba\(\d+,\d+,\d+,([0-9.]+)\)',c[key].replace(' ',''))
        check(m is not None and float(m.group(1)) <= 0.35, f'{side}:{key} is not translucent')
h=tokens['header']
check(0.05 <= h['ringGlassOpacity'] <= 0.55,'ringGlassOpacity')
check(h['ringTintOpacity'] <= 0.18,'ringTintOpacity too opaque')
check(h['ringSpecularOpacity'] >= 0.8,'ringSpecularOpacity too weak')
field=tokens.get('r19OpticalField',{}).get('fields',{}).get('panel',{})
check(field.get('rank') == 64,'R19 full-panel optical field missing/rank mismatch')
check('R19OpticalFieldOverlay()' in swift,'Swift R19 optical-field overlay missing')
check('vDSP_mmul' in field_swift,'Swift optical-field reconstruction missing')
check('mixBlendMode' in html and 'r19OpticalField' in html,'Proxy R19 optical-field blend missing')
if errors:
    print('GLASS_MATERIAL_FAIL')
    for e in errors: print('-',e)
    raise SystemExit(1)
print('GLASS_MATERIAL_PASS')
print('cards=translucent glass; edge optics=R19 calibrated full-panel multiply/screen field; ring=glass + refractive field')
