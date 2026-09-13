// Generated from Design/VisualTokens.json. Do not edit by hand.
import SwiftUI

enum VisualTokens {
  static let designSize = CGSize(width: 720, height: 408)
  static let panelCorner: CGFloat = 38

  enum Header {
    static let x: CGFloat = 65
    static let y: CGFloat = 54
    static let gap: CGFloat = 28
    static let ringSize: CGFloat = 68
    static let ringStroke: CGFloat = 7.2
    static let ringGlow: CGFloat = 10
    static let ringSpecularWidth: CGFloat = 2.25
    static let titleSize: CGFloat = 37
    static let tracking: CGFloat = 0.15
    static let titleGlow: CGFloat = 6
    static let ringWarmGlowOpacity: Double = 0.72
    static let ringCoolGlowOpacity: Double = 0.16
    static let ringOuterHighlight: Double = 0.92
    static let ringInnerHighlight: Double = 0.44
    static let ringDarkEdge: Double = 0.14
    static let ringGlassOpacity: Double = 0.22
    static let ringTintOpacity: Double = 0.055
    static let ringRimGlowOpacity: Double = 0.72
    static let ringSpecularOpacity: Double = 0.98
    static let titleWeight: Font.Weight = .regular
    static let titleGlowOpacity: Double = 0.14
  }

  struct Card {
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
    let h: CGFloat
    let radius: CGFloat
    let padX: CGFloat
    let labelY: CGFloat
    let labelSize: CGFloat
    let valueY: CGFloat
    let valueSize: CGFloat
    let resetBottom: CGFloat
    let resetSize: CGFloat
    let shadowY: CGFloat
    let shadowBlur: CGFloat
    let outerGlow: CGFloat
    let borderWidth: CGFloat
    let innerBlur: CGFloat
    let valueGlow: CGFloat
    let backdropBlur: CGFloat
    let borderGlowBlur: CGFloat
    let borderSpecularWidth: CGFloat
    let labelOpacity: Double
    let resetOpacity: Double
    let topSheen: Double
    let accentInner: Double
    let shadowOpacity: Double
    let outerGlowOpacity: Double
    let borderOpacity: Double
    let innerWhite: Double
    let valueGlowOpacity: Double
    let glassMaterialOpacity: Double
    let glassTintOpacity: Double
    let borderGlowOpacity: Double
    let borderSpecularOpacity: Double
    let innerRimOpacity: Double
    let base1: Color
    let base2: Color
    let base3: Color
    let accent: Color
    let border: Color
    let value: Color
  }
  static let leftCard = Card(
    x: 52,
    y: 150,
    w: 307,
    h: 232,
    radius: 27,
    padX: 37,
    labelY: 30,
    labelSize: 30,
    valueY: 83,
    valueSize: 78,
    resetBottom: 27,
    resetSize: 25,
    shadowY: 12,
    shadowBlur: 20,
    outerGlow: 16,
    borderWidth: 0.95,
    innerBlur: 15,
    valueGlow: 16,
    backdropBlur: 16,
    borderGlowBlur: 8,
    borderSpecularWidth: 1.35,
    labelOpacity: 0.84,
    resetOpacity: 0.57,
    topSheen: 0.12,
    accentInner: 0.105,
    shadowOpacity: 0.28,
    outerGlowOpacity: 0,
    borderOpacity: 0,
    innerWhite: 0.035,
    valueGlowOpacity: 0.34,
    glassMaterialOpacity: 0.42,
    glassTintOpacity: 0.1,
    borderGlowOpacity: 0,
    borderSpecularOpacity: 0,
    innerRimOpacity: 0,
    base1: Color(red: 0.309804, green: 0.286275, blue: 0.262745).opacity(0.26),
    base2: Color(red: 0.078431, green: 0.086275, blue: 0.094118).opacity(0.22),
    base3: Color(red: 0.192157, green: 0.176471, blue: 0.164706).opacity(0.24),
    accent: Color(red: 1, green: 0.745098, blue: 0.435294),
    border: Color(red: 1, green: 0.890196, blue: 0.745098),
    value: Color(red: 1, green: 0.980392, blue: 0.945098)
  )
  static let rightCard = Card(
    x: 391,
    y: 150,
    w: 305,
    h: 232,
    radius: 27,
    padX: 37,
    labelY: 30,
    labelSize: 30,
    valueY: 83,
    valueSize: 78,
    resetBottom: 27,
    resetSize: 25,
    shadowY: 12,
    shadowBlur: 20,
    outerGlow: 16,
    borderWidth: 0.95,
    innerBlur: 15,
    valueGlow: 17,
    backdropBlur: 16,
    borderGlowBlur: 8,
    borderSpecularWidth: 1.35,
    labelOpacity: 0.82,
    resetOpacity: 0.57,
    topSheen: 0.11,
    accentInner: 0.1,
    shadowOpacity: 0.27,
    outerGlowOpacity: 0,
    borderOpacity: 0,
    innerWhite: 0.035,
    valueGlowOpacity: 0.38,
    glassMaterialOpacity: 0.36,
    glassTintOpacity: 0.085,
    borderGlowOpacity: 0,
    borderSpecularOpacity: 0,
    innerRimOpacity: 0,
    base1: Color(red: 0.172549, green: 0.227451, blue: 0.286275).opacity(0.24),
    base2: Color(red: 0.058824, green: 0.082353, blue: 0.109804).opacity(0.21),
    base3: Color(red: 0.121569, green: 0.196078, blue: 0.270588).opacity(0.24),
    accent: Color(red: 0.415686, green: 0.74902, blue: 1),
    border: Color(red: 0.737255, green: 0.894118, blue: 1),
    value: Color(red: 0.92549, green: 0.968627, blue: 1)
  )

  enum Divider {
    static let x: CGFloat = 374
    static let y: CGFloat = 170
    static let h: CGFloat = 190
    static let opacity: Double = 0.28
  }

  enum Material {
    static let warmSpread: CGFloat = 74
    static let warmX: CGFloat = 4
    static let warmY: CGFloat = 8
    static let coolSpread: CGFloat = 78
    static let coolX: CGFloat = 97
    static let coolY: CGFloat = 16
    static let angle: CGFloat = 132
    static let warmOpacity: Double = 0.29
    static let coolOpacity: Double = 0.29
    static let topWhite: Double = 0.19
    static let contrast: Double = 1.08
    static let brightness: Double = 0.91
    static let saturation: Double = 0.88
    static let leftEdgeGlow: Double = 0.4
    static let rightEdgeGlow: Double = 0.25
    static let bottomWarm: Double = 0.17
    static let bottomCool: Double = 0.16
    static let bottomWhite: Double = 0.055
    static let centerDark: Double = 0.14
    static let topEdgeGlow: Double = 0.3
    static let topRightWhite: Double = 0.14
    static let base1: Color = Color(red: 0.2, green: 0.239216, blue: 0.286275)
    static let base2: Color = Color(red: 0.035294, green: 0.062745, blue: 0.094118)
    static let base3: Color = Color(red: 0.090196, green: 0.145098, blue: 0.211765)
    static let base4: Color = Color(red: 0.066667, green: 0.101961, blue: 0.141176)
  }

  enum Edge {
    static let line: CGFloat = 1.55
    static let warmInset: CGFloat = 10
    static let coolInset: CGFloat = 10
    static let blur: CGFloat = 20
    static let outerBlur: CGFloat = 7
    static let whiteOpacity: Double = 0.9
    static let warmOpacity: Double = 0.82
    static let coolOpacity: Double = 0.8
    static let outerOpacity: Double = 0.24
  }

  enum R19Optics {
    enum Ring {
      static let holeDiameter: CGFloat = 26
      static let holeFeatherGlow: CGFloat = 2
      static let mainStroke: CGFloat = 7.8
      static let auraStroke: CGFloat = 14
      static let auraBlur: CGFloat = 5.8
      static let specularWidth: CGFloat = 2.5
      static let warmGlowRadius: CGFloat = 9
      static let whiteGlowRadius: CGFloat = 4
      static let holeOpacity: Double = 0.88
      static let auraOpacity: Double = 0.7
      static let warmArcStart: Double = 0.54
      static let warmArcEnd: Double = 0.8
      static let whiteArcStart: Double = 0.01
      static let whiteArcEnd: Double = 0.27
    }
    enum LeftCard {
      static let focusX: CGFloat = 296
      static let focusY: CGFloat = 232
      static let focusWidth: CGFloat = 184
      static let focusHeight: CGFloat = 106
      static let focusRotation: CGFloat = 58
      static let focusBlur: CGFloat = 27
      static let beamX: CGFloat = 278
      static let beamY: CGFloat = 198
      static let beamWidth: CGFloat = 10
      static let beamHeight: CGFloat = 82
      static let beamRotation: CGFloat = -30
      static let beamBlur: CGFloat = 5
      static let detailBeamX: CGFloat = 290
      static let detailBeamY: CGFloat = 215
      static let detailBeamWidth: CGFloat = 4
      static let detailBeamHeight: CGFloat = 54
      static let detailBeamRotation: CGFloat = -30
      static let detailBeamBlur: CGFloat = 2.8
      static let rimOpacity: Double = 0.28
      static let innerRimOpacity: Double = 0.11
      static let coreOpacity: Double = 0.24
      static let haloOpacity: Double = 0.1
      static let focusOpacity: Double = 0.24
      static let beamOpacity: Double = 0.24
      static let detailBeamOpacity: Double = 0.32
    }
    enum RightCard {
      static let focusX: CGFloat = 302
      static let focusY: CGFloat = 24
      static let focusWidth: CGFloat = 142
      static let focusHeight: CGFloat = 178
      static let focusRotation: CGFloat = 0
      static let focusBlur: CGFloat = 27
      static let focus2X: CGFloat = 312
      static let focus2Y: CGFloat = 72
      static let focus2Width: CGFloat = 72
      static let focus2Height: CGFloat = 174
      static let focus2Blur: CGFloat = 24
      static let topBeamX: CGFloat = 289
      static let topBeamY: CGFloat = 4
      static let topBeamWidth: CGFloat = 78
      static let topBeamHeight: CGFloat = 9
      static let topBeamBlur: CGFloat = 4.5
      static let sideBeamX: CGFloat = 314
      static let sideBeamY: CGFloat = 48
      static let sideBeamWidth: CGFloat = 9
      static let sideBeamHeight: CGFloat = 92
      static let sideBeamBlur: CGFloat = 5
      static let rimOpacity: Double = 0.27
      static let innerRimOpacity: Double = 0.11
      static let coreOpacity: Double = 0.23
      static let haloOpacity: Double = 0.11
      static let focusOpacity: Double = 0.4
      static let focus2Opacity: Double = 0.24
      static let topBeamOpacity: Double = 0.42
      static let sideBeamOpacity: Double = 0.42
    }
  }

  enum Animation {
    static let liquidPeriod: Double = 64
    static let sweepPeriod: Double = 28
    static let crestPeriod: Double = 58
    static let particlePeriod: Double = 72
  }
}
