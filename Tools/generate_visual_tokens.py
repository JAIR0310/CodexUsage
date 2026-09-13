#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, re
from pathlib import Path

def f(v):
    if isinstance(v,int): return str(v)
    return (f"{float(v):.6f}").rstrip('0').rstrip('.') if '.' in f"{float(v):.6f}" else str(v)

def css_color(expr:str):
    expr=expr.strip()
    if expr.startswith('#'):
        s=expr[1:]
        if len(s)==6:
            r,g,b=[int(s[i:i+2],16)/255 for i in (0,2,4)];a=1
        elif len(s)==8:
            r,g,b,a=[int(s[i:i+2],16)/255 for i in (0,2,4,6)]
        else: raise ValueError(expr)
    else:
        m=re.fullmatch(r'rgba\((\d+),(\d+),(\d+),([0-9.]+)\)',expr.replace(' ',''))
        if not m: raise ValueError(expr)
        r,g,b=[int(m.group(i))/255 for i in (1,2,3)];a=float(m.group(4))
    base=f"Color(red: {f(r)}, green: {f(g)}, blue: {f(b)})"
    return base if abs(a-1)<1e-9 else base+f".opacity({f(a)})"

def swift_weight(v):
    n=float(v)
    if n < 150: return ".ultraLight"
    if n < 250: return ".thin"
    if n < 350: return ".light"
    if n < 450: return ".regular"
    if n < 550: return ".medium"
    if n < 650: return ".semibold"
    if n < 750: return ".bold"
    if n < 850: return ".heavy"
    return ".black"

def rgb_triplet(s:str):
    r,g,b=[int(x.strip())/255 for x in s.split(',')]
    return f"Color(red: {f(r)}, green: {f(g)}, blue: {f(b)})"

ap=argparse.ArgumentParser();ap.add_argument('--input',required=True);ap.add_argument('--output',required=True);a=ap.parse_args()
d=json.loads(Path(a.input).read_text())
h=d['header'];m=d['material'];e=d['edge'];an=d['animation'];L=d['cards']['left'];R=d['cards']['right'];dv=d['divider'];r19=d.get('r19Optics',{})
lines=[]
A=lines.append
A('// Generated from Design/VisualTokens.json. Do not edit by hand.')
A('import SwiftUI')
A('')
A('enum VisualTokens {')
A(f'  static let designSize = CGSize(width: {f(d["canvas"]["width"])}, height: {f(d["canvas"]["height"])})')
A(f'  static let panelCorner: CGFloat = {f(d["panel"]["corner"])}')
A('')
A('  enum Header {')
for key in ['x','y','gap','ringSize','ringStroke','ringGlow','ringSpecularWidth','titleSize','tracking','titleGlow']:
    A(f'    static let {key}: CGFloat = {f(h[key])}')
for key, default in [
    ('ringWarmGlowOpacity', 0.42),
    ('ringCoolGlowOpacity', 0.12),
    ('ringOuterHighlight', 0.78),
    ('ringInnerHighlight', 0.42),
    ('ringDarkEdge', 0.62),
    ('ringGlassOpacity', 0.32),
    ('ringTintOpacity', 0.10),
    ('ringRimGlowOpacity', 0.56),
    ('ringSpecularOpacity', 0.90),
]:
    A(f'    static let {key}: Double = {f(h.get(key, default))}')
A(f'    static let titleWeight: Font.Weight = {swift_weight(h.get("titleWeight", 400))}')
A(f'    static let titleGlowOpacity: Double = {f(h["titleGlowOpacity"])}')
A('  }')
A('')
A('  struct Card {')
for key in ['x','y','w','h','radius','padX','labelY','labelSize','valueY','valueSize','resetBottom','resetSize','shadowY','shadowBlur','outerGlow','borderWidth','innerBlur','valueGlow','backdropBlur','borderGlowBlur','borderSpecularWidth']:
    A(f'    let {key}: CGFloat')
for key in ['labelOpacity','resetOpacity','topSheen','accentInner','shadowOpacity','outerGlowOpacity','borderOpacity','innerWhite','valueGlowOpacity','glassMaterialOpacity','glassTintOpacity','borderGlowOpacity','borderSpecularOpacity','innerRimOpacity']:
    A(f'    let {key}: Double')
A('    let base1: Color');A('    let base2: Color');A('    let base3: Color');A('    let accent: Color');A('    let border: Color');A('    let value: Color')
A('  }')

def card(name,c):
    A(f'  static let {name}Card = Card(')
    vals=[]
    for key in ['x','y','w','h','radius','padX','labelY','labelSize','valueY','valueSize','resetBottom','resetSize','shadowY','shadowBlur','outerGlow','borderWidth','innerBlur','valueGlow','backdropBlur','borderGlowBlur','borderSpecularWidth']:
        vals.append(f'    {key}: {f(c[key])}')
    for key in ['labelOpacity','resetOpacity','topSheen','accentInner','shadowOpacity','outerGlowOpacity','borderOpacity','innerWhite','valueGlowOpacity','glassMaterialOpacity','glassTintOpacity','borderGlowOpacity','borderSpecularOpacity','innerRimOpacity']:
        vals.append(f'    {key}: {f(c[key])}')
    vals += [f'    base1: {css_color(c["c1"])}',f'    base2: {css_color(c["c2"])}',f'    base3: {css_color(c["c3"])}',f'    accent: {rgb_triplet(c["accentRgb"])}',f'    border: {rgb_triplet(c["borderRgb"])}',f'    value: {css_color(c["valueColor"])}']
    A(',\n'.join(vals));A('  )')
card('left',L);card('right',R)
A('')
A('  enum Divider {')
for key in ['x','y','h']:
    A(f'    static let {key}: CGFloat = {f(dv[key])}')
A(f'    static let opacity: Double = {f(dv["opacity"])}')
A('  }')
A('')
A('  enum Material {')
for key in ['warmSpread','warmX','warmY','coolSpread','coolX','coolY','angle']:
    A(f'    static let {key}: CGFloat = {f(m[key])}')
for key in ['warmOpacity','coolOpacity','topWhite','contrast','brightness','saturation','leftEdgeGlow','rightEdgeGlow','bottomWarm','bottomCool','bottomWhite','centerDark','topEdgeGlow','topRightWhite']:
    A(f'    static let {key}: Double = {f(m.get(key,0))}')
for i,key in enumerate(['c1','c2','c3','c4'],1): A(f'    static let base{i}: Color = {css_color(m[key])}')
A('  }')
A('')
A('  enum Edge {')
for key in ['line','warmInset','coolInset','blur','outerBlur']:
    A(f'    static let {key}: CGFloat = {f(e[key])}')
for key in ['whiteOpacity','warmOpacity','coolOpacity','outerOpacity']:
    A(f'    static let {key}: Double = {f(e[key])}')
A('  }')
A('')
A('  enum R19Optics {')
A('    enum Ring {')
for key in ['holeDiameter','holeFeatherGlow','mainStroke','auraStroke','auraBlur','specularWidth','warmGlowRadius','whiteGlowRadius']:
    A(f'      static let {key}: CGFloat = {f(r19["ring"][key])}')
for key in ['holeOpacity','auraOpacity','warmArcStart','warmArcEnd','whiteArcStart','whiteArcEnd']:
    A(f'      static let {key}: Double = {f(r19["ring"][key])}')
A('    }')
A('    enum LeftCard {')
for key in ['focusX','focusY','focusWidth','focusHeight','focusRotation','focusBlur','beamX','beamY','beamWidth','beamHeight','beamRotation','beamBlur','detailBeamX','detailBeamY','detailBeamWidth','detailBeamHeight','detailBeamRotation','detailBeamBlur']:
    A(f'      static let {key}: CGFloat = {f(r19["leftCard"][key])}')
for key in ['rimOpacity','innerRimOpacity','coreOpacity','haloOpacity','focusOpacity','beamOpacity','detailBeamOpacity']:
    A(f'      static let {key}: Double = {f(r19["leftCard"][key])}')
A('    }')
A('    enum RightCard {')
for key in ['focusX','focusY','focusWidth','focusHeight','focusRotation','focusBlur','focus2X','focus2Y','focus2Width','focus2Height','focus2Blur','topBeamX','topBeamY','topBeamWidth','topBeamHeight','topBeamBlur','sideBeamX','sideBeamY','sideBeamWidth','sideBeamHeight','sideBeamBlur']:
    A(f'      static let {key}: CGFloat = {f(r19["rightCard"][key])}')
for key in ['rimOpacity','innerRimOpacity','coreOpacity','haloOpacity','focusOpacity','focus2Opacity','topBeamOpacity','sideBeamOpacity']:
    A(f'      static let {key}: Double = {f(r19["rightCard"][key])}')
A('    }')
A('  }')
A('')
A('  enum Animation {')
for key in ['liquidPeriod','sweepPeriod','crestPeriod','particlePeriod']:
    A(f'    static let {key}: Double = {f(an[key])}')
A('  }')
A('}')
Path(a.output).write_text('\n'.join(lines)+'\n')
print(a.output)
