import AppKit
import CodexUsageCore
import Foundation
import SwiftUI

struct TitaniumContentView: View {
  @ObservedObject var model: RateLimitViewModel

  var body: some View {
    ZStack {
      TitaniumPanel(snapshot: model.snapshot)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()

      TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
        WholeWindowLightSweep(time: animationSeconds(for: timeline.date))
          .allowsHitTesting(false)
          .ignoresSafeArea()
      }
    }
    .contentShape(Rectangle())
    .preferredColorScheme(.dark)
    .onAppear { model.start() }
    .onDisappear { model.stop() }
    .background(WindowConfigurator())
  }

  private func animationSeconds(for date: Date) -> Double {
    date.timeIntervalSinceReferenceDate
      .truncatingRemainder(dividingBy: 20_000)
  }
}

private struct TitaniumPanel: View {
  let snapshot: CodexQuotaSnapshot?

  var body: some View {
    GeometryReader { proxy in
      let contentScale = min(
        proxy.size.width / VisualTokens.designSize.width,
        proxy.size.height / VisualTokens.designSize.height
      )

      ZStack {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
          let seconds = animationTime(timeline.date)

          ZStack {
            LiquidTitaniumSurface(time: seconds)
            DeepSpaceGlow(time: seconds)
            LiquidMetalMorphField(time: seconds)
            SlowMetalBands(time: seconds)
            LiquidLightRibbons(time: seconds)
            IrregularLightTrails(time: seconds)
            AmbientParticleField(time: seconds)
            LiquidCrest(time: seconds)
            PanelInternalGlow(time: seconds)
          }
          .frame(width: proxy.size.width, height: proxy.size.height)
          .allowsHitTesting(false)
        }

        ZStack {
          panelForeground
          R19OpticalFieldOverlay()
        }
        .frame(
          width: VisualTokens.designSize.width,
          height: VisualTokens.designSize.height,
          alignment: .topLeading
        )
        .scaleEffect(contentScale)
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipShape(
        RoundedRectangle(cornerRadius: VisualTokens.panelCorner, style: .continuous)
      )
      .overlay { LiquidMetalEdgeGlow() }
    }
  }

  private var panelForeground: some View {
    ZStack(alignment: .topLeading) {
      HStack(spacing: VisualTokens.Header.gap) {
        TitaniumRing()
          .frame(width: VisualTokens.Header.ringSize, height: VisualTokens.Header.ringSize)

        Text("Codex Usage")
          .font(
            .system(
              size: VisualTokens.Header.titleSize,
              weight: VisualTokens.Header.titleWeight,
              design: .default
            )
          )
          .tracking(VisualTokens.Header.tracking)
          .foregroundStyle(
            LinearGradient(
              colors: [
                .white,
                Color(red: 0.93, green: 0.94, blue: 0.95),
                Color(red: 0.72, green: 0.75, blue: 0.79),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .shadow(
            color: .white.opacity(VisualTokens.Header.titleGlowOpacity),
            radius: VisualTokens.Header.titleGlow,
            y: -1
          )
          .shadow(color: .black.opacity(0.56), radius: 3, y: 2)
      }
      .frame(
        width: VisualTokens.designSize.width - VisualTokens.Header.x,
        height: VisualTokens.Header.ringSize,
        alignment: .leading
      )
      .position(
        x: VisualTokens.Header.x
          + (VisualTokens.designSize.width - VisualTokens.Header.x) / 2,
        y: VisualTokens.Header.y + VisualTokens.Header.ringSize / 2
      )

      QuotaCard(
        label: "5 小时",
        value: percentText(snapshot?.fiveHour),
        reset: fiveHourResetText(snapshot?.fiveHour),
        style: VisualTokens.leftCard,
        accent: .warm
      )
      .frame(width: VisualTokens.leftCard.w, height: VisualTokens.leftCard.h)
      .position(
        x: VisualTokens.leftCard.x + VisualTokens.leftCard.w / 2,
        y: VisualTokens.leftCard.y + VisualTokens.leftCard.h / 2
      )

      QuotaCard(
        label: "7 天",
        value: percentText(snapshot?.weekly),
        reset: weeklyResetText(snapshot?.weekly),
        style: VisualTokens.rightCard,
        accent: .cool
      )
      .frame(width: VisualTokens.rightCard.w, height: VisualTokens.rightCard.h)
      .position(
        x: VisualTokens.rightCard.x + VisualTokens.rightCard.w / 2,
        y: VisualTokens.rightCard.y + VisualTokens.rightCard.h / 2
      )

      LinearGradient(
        colors: [
          .clear,
          .white.opacity(VisualTokens.Divider.opacity),
          .white.opacity(VisualTokens.Divider.opacity * 0.45),
          .clear,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(width: 1, height: VisualTokens.Divider.h)
      .position(
        x: VisualTokens.Divider.x + 0.5,
        y: VisualTokens.Divider.y + VisualTokens.Divider.h / 2
      )
    }
    .frame(
      width: VisualTokens.designSize.width,
      height: VisualTokens.designSize.height,
      alignment: .topLeading
    )
  }

  private func percentText(_ window: QuotaWindow?) -> String {
    guard let remaining = window?.remainingPercent else { return "--%" }
    if abs(remaining.rounded() - remaining) < 0.001 {
      return "\(Int(remaining.rounded()))%"
    }
    return String(format: "%.1f%%", remaining)
  }

  private func fiveHourResetText(_ window: QuotaWindow?) -> String {
    guard let timestamp = window?.resetsAt else { return "--:-- 重置" }
    return "\(formatReset(timestamp, pattern: "HH:mm")) 重置"
  }

  private func weeklyResetText(_ window: QuotaWindow?) -> String {
    guard let timestamp = window?.resetsAt else { return "--月--日 --:-- 重置" }
    return "\(formatReset(timestamp, pattern: "M月d日 HH:mm")) 重置"
  }

  private func formatReset(_ timestamp: TimeInterval, pattern: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = pattern
    return formatter.string(from: Date(timeIntervalSince1970: timestamp))
  }
}

private enum QuotaAccent {
  case warm
  case cool

  var glow: Color {
    switch self {
    case .warm:
      return Color(red: 1.0, green: 0.74, blue: 0.43)
    case .cool:
      return Color(red: 0.42, green: 0.75, blue: 1.0)
    }
  }
}

private struct QuotaCard: View {
  let label: String
  let value: String
  let reset: String
  let style: VisualTokens.Card
  let accent: QuotaAccent

  var body: some View {
    ZStack(alignment: .topLeading) {
      // The card is a translucent glass sheet. The liquid-metal surface below must remain
      // visible through it; tint and blur only separate the information plane from the base.
      RoundedRectangle(cornerRadius: style.radius, style: .continuous)
        .fill(.ultraThinMaterial)
        .opacity(style.glassMaterialOpacity)

      RoundedRectangle(cornerRadius: style.radius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              .white.opacity(style.glassMaterialOpacity * 0.10),
              Color(red: 0.76, green: 0.81, blue: 0.86)
                .opacity(style.glassMaterialOpacity * 0.035),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      RoundedRectangle(cornerRadius: style.radius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [style.base1, style.base2, style.base3],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      RoundedRectangle(cornerRadius: style.radius, style: .continuous)
        .fill(
          RadialGradient(
            colors: [
              .white.opacity(style.topSheen),
              .white.opacity(style.topSheen * 0.16),
              .clear,
            ],
            center: .topLeading,
            startRadius: 0,
            endRadius: 190
          )
        )
        .blendMode(.screen)

      RoundedRectangle(cornerRadius: style.radius, style: .continuous)
        .fill(
          RadialGradient(
            colors: [
              style.accent.opacity(style.accentInner),
              style.accent.opacity(style.accentInner * 0.16),
              .clear,
            ],
            center: .bottomTrailing,
            startRadius: 0,
            endRadius: 205
          )
        )
        .blendMode(.plusLighter)

      RoundedRectangle(cornerRadius: style.radius, style: .continuous)
        .fill(Color.black.opacity(style.glassTintOpacity))

      Text(label)
        .font(.system(size: style.labelSize, weight: .medium, design: .default))
        .foregroundStyle(.white.opacity(style.labelOpacity))
        .shadow(color: .black.opacity(0.44), radius: 2, y: 1)
        .offset(x: style.padX, y: style.labelY)

      Text(value)
        .font(.system(size: style.valueSize, weight: .medium, design: .default))
        .monospacedDigit()
        .foregroundStyle(
          LinearGradient(
            colors: [
              .white,
              style.value,
              .white.opacity(0.91),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .shadow(color: style.accent.opacity(style.valueGlowOpacity), radius: style.valueGlow)
        .shadow(color: .white.opacity(0.08), radius: 2, y: -1)
        .shadow(color: .black.opacity(0.36), radius: 3, y: 2)
        .lineLimit(1)
        .minimumScaleFactor(0.70)
        .offset(x: style.padX, y: style.valueY)

      Text(reset)
        .font(.system(size: style.resetSize, weight: .regular, design: .default))
        .monospacedDigit()
        .foregroundStyle(.white.opacity(style.resetOpacity))
        .lineLimit(1)
        .minimumScaleFactor(0.76)
        .padding(.leading, style.padX)
        .padding(.bottom, style.resetBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
    .clipShape(RoundedRectangle(cornerRadius: style.radius, style: .continuous))
    // R19 edge optics are applied once at the calibrated full-panel optical-field layer.
    .shadow(color: style.accent.opacity(style.outerGlowOpacity), radius: style.outerGlow, y: 2)
    .shadow(color: .black.opacity(style.shadowOpacity), radius: style.shadowBlur, y: style.shadowY)
  }
}

private struct TitaniumRing: View {
  var body: some View {
    ZStack {
      Circle()
        .fill(.ultraThinMaterial)
        .opacity(VisualTokens.Header.ringGlassOpacity * 0.76)

      Circle()
        .fill(Color.black.opacity(VisualTokens.R19Optics.Ring.holeOpacity))
        .frame(
          width: VisualTokens.R19Optics.Ring.holeDiameter,
          height: VisualTokens.R19Optics.Ring.holeDiameter
        )
        .shadow(color: .black.opacity(0.70), radius: VisualTokens.R19Optics.Ring.holeFeatherGlow)

      Circle()
        .stroke(
          AngularGradient(
            gradient: Gradient(stops: ringStops),
            center: .center,
            startAngle: .degrees(-118),
            endAngle: .degrees(242)
          ),
          lineWidth: VisualTokens.R19Optics.Ring.auraStroke
        )
        .blur(radius: VisualTokens.R19Optics.Ring.auraBlur)
        .opacity(VisualTokens.R19Optics.Ring.auraOpacity)
        .blendMode(.plusLighter)

      Circle()
        .stroke(
          AngularGradient(
            gradient: Gradient(stops: ringStops),
            center: .center,
            startAngle: .degrees(-118),
            endAngle: .degrees(242)
          ),
          lineWidth: VisualTokens.R19Optics.Ring.mainStroke
        )
        .shadow(color: .black.opacity(0.34), radius: 1.2, y: 1)

      Circle()
        .trim(
          from: VisualTokens.R19Optics.Ring.warmArcStart,
          to: VisualTokens.R19Optics.Ring.warmArcEnd
        )
        .stroke(
          Color(red: 1.0, green: 0.79, blue: 0.49)
            .opacity(VisualTokens.Header.ringSpecularOpacity),
          style: StrokeStyle(
            lineWidth: VisualTokens.R19Optics.Ring.specularWidth,
            lineCap: .round
          )
        )
        .shadow(
          color: Color(red: 1.0, green: 0.65, blue: 0.25)
            .opacity(VisualTokens.Header.ringWarmGlowOpacity),
          radius: VisualTokens.R19Optics.Ring.warmGlowRadius,
          x: 2,
          y: 2
        )
        .blendMode(.plusLighter)

      Circle()
        .trim(
          from: VisualTokens.R19Optics.Ring.whiteArcStart,
          to: VisualTokens.R19Optics.Ring.whiteArcEnd
        )
        .stroke(
          .white.opacity(VisualTokens.Header.ringSpecularOpacity),
          style: StrokeStyle(
            lineWidth: VisualTokens.R19Optics.Ring.specularWidth * 0.90,
            lineCap: .round
          )
        )
        .shadow(color: .white.opacity(0.42), radius: VisualTokens.R19Optics.Ring.whiteGlowRadius)
        .blendMode(.screen)

      Circle()
        .stroke(.white.opacity(0.44), lineWidth: 0.75)
        .padding(0.7)
        .blendMode(.screen)

      Circle()
        .stroke(Color.black.opacity(0.34), lineWidth: 0.9)
        .padding(VisualTokens.R19Optics.Ring.mainStroke + 0.55)
    }
  }

  private var ringStops: [Gradient.Stop] {
    [
      .init(color: Color(red: 0.95, green: 0.97, blue: 0.98), location: 0.00),
      .init(color: .white, location: 0.16),
      .init(color: Color(red: 0.76, green: 0.79, blue: 0.81), location: 0.33),
      .init(color: Color(red: 0.92, green: 0.84, blue: 0.72), location: 0.47),
      .init(color: Color(red: 1.0, green: 0.70, blue: 0.34), location: 0.61),
      .init(color: Color(red: 0.52, green: 0.55, blue: 0.58), location: 0.72),
      .init(color: Color(red: 0.69, green: 0.79, blue: 0.87), location: 0.84),
      .init(color: Color(red: 0.93, green: 0.95, blue: 0.97), location: 1.00),
    ]
  }
}

private struct LiquidTitaniumSurface: View {
  let time: Double

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let t = time
      let drift = CGFloat(sin(t * (2 * .pi / VisualTokens.Animation.liquidPeriod)))

      ZStack {
        RoundedRectangle(cornerRadius: VisualTokens.panelCorner, style: .continuous)
          .fill(
            LinearGradient(
              colors: [
                VisualTokens.Material.base1,
                VisualTokens.Material.base2,
                VisualTokens.Material.base3,
                VisualTokens.Material.base4,
              ],
              startPoint: UnitPoint(x: 0.03 + 0.035 * drift, y: 0.02),
              endPoint: UnitPoint(x: 0.97 - 0.025 * drift, y: 0.98)
            )
          )

        // Full-height side reflections are intentionally softer than the local hot spots.
        Ellipse()
          .fill(
            Color(red: 1.0, green: 0.74, blue: 0.43)
              .opacity(VisualTokens.Material.leftEdgeGlow)
          )
          .frame(width: max(130, size.width * 0.22), height: max(430, size.height * 1.18))
          .blur(radius: 58)
          .position(x: -size.width * 0.025 + drift * 9, y: size.height * 0.50)
          .blendMode(.plusLighter)

        Ellipse()
          .fill(
            Color(red: 0.42, green: 0.75, blue: 1.0)
              .opacity(VisualTokens.Material.rightEdgeGlow)
          )
          .frame(width: max(140, size.width * 0.23), height: max(440, size.height * 1.20))
          .blur(radius: 60)
          .position(x: size.width * 1.025 - drift * 9, y: size.height * 0.50)
          .blendMode(.plusLighter)

        Ellipse()
          .fill(
            Color(red: 1.0, green: 0.75, blue: 0.46)
              .opacity(VisualTokens.Material.warmOpacity)
          )
          .frame(width: size.width * 0.44, height: size.height * 0.48)
          .blur(radius: 54)
          .position(x: size.width * 0.07 + drift * 7, y: size.height * 0.08)
          .blendMode(.plusLighter)

        Ellipse()
          .fill(
            Color(red: 0.45, green: 0.77, blue: 1.0)
              .opacity(VisualTokens.Material.coolOpacity)
          )
          .frame(width: size.width * 0.46, height: size.height * 0.50)
          .blur(radius: 56)
          .position(x: size.width * 0.94 - drift * 7, y: size.height * 0.13)
          .blendMode(.plusLighter)

        LinearGradient(
          colors: [
            .white.opacity(VisualTokens.Material.topEdgeGlow),
            .clear,
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(width: size.width, height: size.height * 0.15)
        .position(x: size.width * 0.50, y: size.height * 0.075)
        .blendMode(.screen)

        Ellipse()
          .fill(.white.opacity(VisualTokens.Material.topRightWhite))
          .frame(width: size.width * 0.34, height: size.height * 0.28)
          .blur(radius: 42)
          .position(x: size.width * 0.70 - drift * 4, y: size.height * 0.02)
          .blendMode(.screen)

        Ellipse()
          .fill(.white.opacity(VisualTokens.Material.topWhite))
          .frame(width: size.width * 0.70, height: max(110, size.height * 0.29))
          .blur(radius: 50)
          .position(x: size.width * 0.52, y: -size.height * 0.02 + drift * 4)
          .blendMode(.screen)

        Ellipse()
          .fill(
            Color(red: 1.0, green: 0.72, blue: 0.38)
              .opacity(VisualTokens.Material.bottomWarm)
          )
          .frame(width: size.width * 0.52, height: max(118, size.height * 0.32))
          .blur(radius: 48)
          .position(x: size.width * 0.18 + drift * 9, y: size.height * 1.03)
          .blendMode(.plusLighter)

        Ellipse()
          .fill(
            Color(red: 0.39, green: 0.73, blue: 1.0)
              .opacity(VisualTokens.Material.bottomCool)
          )
          .frame(width: size.width * 0.54, height: max(118, size.height * 0.32))
          .blur(radius: 50)
          .position(x: size.width * 0.84 - drift * 9, y: size.height * 1.03)
          .blendMode(.plusLighter)

        Ellipse()
          .fill(.white.opacity(VisualTokens.Material.bottomWhite))
          .frame(width: size.width * 0.86, height: size.height * 0.28)
          .blur(radius: 54)
          .position(x: size.width * 0.50, y: size.height * 1.06)
          .blendMode(.screen)

        Ellipse()
          .fill(.black.opacity(VisualTokens.Material.centerDark))
          .frame(width: size.width * 0.62, height: size.height * 0.70)
          .blur(radius: 62)
          .position(x: size.width * 0.50, y: size.height * 0.52)
          .blendMode(.multiply)
      }
      .clipShape(RoundedRectangle(cornerRadius: VisualTokens.panelCorner, style: .continuous))
    }
  }
}

private struct LiquidMetalMorphField: View {
  let time: Double

  var body: some View {
    Canvas { context, size in
      let folds: [(CGFloat, CGFloat, CGFloat, Double, Color, Double)] = [
        (0.18, 34, 48, 0.0, Color.white, 0.13),
        (0.43, 41, 58, 1.7, Color(red: 0.70, green: 0.84, blue: 1.0), 0.11),
        (0.70, 34, 52, 3.6, Color(red: 1.0, green: 0.79, blue: 0.56), 0.105),
        (0.88, 24, 42, 5.1, Color.white, 0.08),
      ]

      for (index, fold) in folds.enumerated() {
        let phase = time * (0.040 + Double(index) * 0.003) + fold.3
        let path = foldPath(
          size: size,
          centerY: fold.0,
          amplitude: fold.1,
          phase: phase,
          drift: CGFloat(sin(time * (0.033 + Double(index) * 0.002) + fold.3)) * 26
        )

        context.drawLayer { layer in
          layer.addFilter(.blur(radius: 25))
          layer.stroke(path, with: .color(Color.black.opacity(0.17)), lineWidth: fold.2 * 1.25)
        }

        context.drawLayer { layer in
          layer.addFilter(.blur(radius: 17))
          layer.stroke(
            path,
            with: .linearGradient(
              Gradient(colors: [
                .clear,
                fold.4.opacity(fold.5),
                Color.white.opacity(fold.5 * 1.50),
                fold.4.opacity(fold.5 * 0.80),
                .clear,
              ]),
              startPoint: CGPoint(x: 0, y: size.height * fold.0 - fold.2),
              endPoint: CGPoint(x: size.width, y: size.height * fold.0 + fold.2)
            ),
            lineWidth: fold.2
          )
        }

        context.drawLayer { layer in
          layer.addFilter(.blur(radius: 4))
          layer.stroke(path, with: .color(fold.4.opacity(fold.5 * 0.82)), lineWidth: 1.3)
        }
      }
    }
    .blendMode(.softLight)
    .allowsHitTesting(false)
  }

  private func foldPath(
    size: CGSize,
    centerY: CGFloat,
    amplitude: CGFloat,
    phase: Double,
    drift: CGFloat
  ) -> Path {
    var path = Path()
    let samples = 120

    for index in 0...samples {
      let p = CGFloat(index) / CGFloat(samples)
      let x = p * size.width
      let slowWave = CGFloat(sin(Double(p) * 5.2 + phase)) * amplitude
      let mediumWave = CGFloat(cos(Double(p) * 9.6 - phase * 0.70)) * amplitude * 0.28
      let travel = CGFloat(sin(Double.pi * Double(p))) * drift
      let y = size.height * centerY + slowWave + mediumWave + travel

      if index == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }

    return path
  }
}

private struct LiquidCrest: View {
  let time: Double

  var body: some View {
    Canvas { context, size in
      let phase = time * (2 * .pi / VisualTokens.Animation.crestPeriod)
      let drift = CGFloat(sin(phase)) * size.width * 0.018
      let lift = CGFloat(cos(phase * 0.82)) * size.height * 0.015
      let primary = crestPath(size: size, drift: drift, lift: lift, phase: phase)
      let secondary = crestPath(
        size: size,
        drift: -drift * 0.35,
        lift: lift + size.height * 0.018,
        phase: phase + 1.2
      )

      context.drawLayer { layer in
        layer.addFilter(.blur(radius: 15))
        layer.stroke(primary, with: .color(.white.opacity(0.12)), lineWidth: 19)
        layer.stroke(
          primary,
          with: .color(Color(red: 1.0, green: 0.74, blue: 0.43).opacity(0.09)),
          lineWidth: 13
        )
        layer.stroke(
          primary,
          with: .color(Color(red: 0.43, green: 0.76, blue: 1.0).opacity(0.10)),
          lineWidth: 11
        )
      }

      context.drawLayer { layer in
        layer.addFilter(.blur(radius: 3))
        layer.stroke(
          primary,
          with: .linearGradient(
            Gradient(colors: [
              Color(red: 1.0, green: 0.79, blue: 0.54).opacity(0.95),
              .white.opacity(0.90),
              Color(red: 0.55, green: 0.82, blue: 1.0).opacity(0.95),
            ]),
            startPoint: CGPoint(x: size.width * 0.28, y: 0),
            endPoint: CGPoint(x: size.width, y: size.height * 0.22)
          ),
          lineWidth: 2.45
        )
        layer.stroke(secondary, with: .color(.white.opacity(0.38)), lineWidth: 1.1)
      }

      context.stroke(
        secondary,
        with: .color(Color(red: 1.0, green: 0.76, blue: 0.47).opacity(0.30)),
        lineWidth: 0.8
      )
    }
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
  }

  private func crestPath(
    size: CGSize,
    drift: CGFloat,
    lift: CGFloat,
    phase: Double
  ) -> Path {
    var path = Path()
    let start = CGPoint(
      x: size.width * 0.30 + drift * 0.25,
      y: size.height * 0.012 + lift * 0.15
    )
    let end = CGPoint(
      x: size.width + 24,
      y: size.height * (0.175 + 0.012 * CGFloat(sin(phase))) + lift
    )
    let control1 = CGPoint(
      x: size.width * 0.46 + drift * 0.20,
      y: -size.height * 0.025 + lift * 0.20
    )
    let control2 = CGPoint(
      x: size.width * 0.70 + drift,
      y: size.height * 0.30 + lift
    )

    path.move(to: start)
    path.addCurve(to: end, control1: control1, control2: control2)
    return path
  }
}

private struct PanelInternalGlow: View {
  let time: Double

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let warmPulse = 0.88 + 0.12 * sin(time * 0.075)
      let coolPulse = 0.88 + 0.12 * cos(time * 0.068)

      ZStack {
        Ellipse()
          .fill(Color(red: 1.0, green: 0.73, blue: 0.42).opacity(0.10 * warmPulse))
          .frame(width: size.width * 0.28, height: size.height * 0.72)
          .blur(radius: 54)
          .position(x: 0, y: size.height * 0.48)

        Ellipse()
          .fill(Color(red: 0.42, green: 0.74, blue: 1.0).opacity(0.11 * coolPulse))
          .frame(width: size.width * 0.30, height: size.height * 0.74)
          .blur(radius: 58)
          .position(x: size.width, y: size.height * 0.48)
      }
      .blendMode(.plusLighter)
    }
    .allowsHitTesting(false)
  }
}

private struct SlowMetalBands: View {
  let time: Double

  var body: some View {
    Canvas { context, size in
      drawBand(
        context: &context,
        size: size,
        centerY: 0.26,
        amplitude: 27,
        phase: time * 0.048,
        lineWidth: 24,
        color: .white.opacity(0.038)
      )

      drawBand(
        context: &context,
        size: size,
        centerY: 0.62,
        amplitude: 21,
        phase: time * 0.041 + 2.2,
        lineWidth: 18,
        color: Color(red: 0.58, green: 0.79, blue: 1.0).opacity(0.040)
      )

      drawBand(
        context: &context,
        size: size,
        centerY: 0.80,
        amplitude: 17,
        phase: time * 0.036 + 4.0,
        lineWidth: 14,
        color: Color(red: 1.0, green: 0.76, blue: 0.47).opacity(0.036)
      )
    }
    .blur(radius: 9)
    .allowsHitTesting(false)
  }

  private func drawBand(
    context: inout GraphicsContext,
    size: CGSize,
    centerY: CGFloat,
    amplitude: CGFloat,
    phase: Double,
    lineWidth: CGFloat,
    color: Color
  ) {
    var path = Path()
    let samples = 90

    for index in 0...samples {
      let p = CGFloat(index) / CGFloat(samples)
      let x = p * size.width
      let y =
        size.height * centerY
        + CGFloat(sin(Double(p) * 6.5 + phase)) * amplitude
        + CGFloat(cos(Double(p) * 13.0 - phase * 0.68)) * amplitude * 0.22

      if index == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }

    context.stroke(path, with: .color(color), lineWidth: lineWidth)
  }
}

private struct LiquidLightRibbons: View {
  let time: Double

  var body: some View {
    Canvas { context, size in
      drawRibbon(
        context: &context,
        size: size,
        yFraction: 0.24,
        phase: time * 0.052,
        amplitude: 21,
        width: 7,
        color: Color(red: 0.72, green: 0.88, blue: 1.0).opacity(0.10)
      )

      drawRibbon(
        context: &context,
        size: size,
        yFraction: 0.73,
        phase: time * 0.043 + 2.3,
        amplitude: 17,
        width: 6,
        color: Color(red: 1.0, green: 0.79, blue: 0.51).opacity(0.09)
      )
    }
    .blur(radius: 4)
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
  }

  private func drawRibbon(
    context: inout GraphicsContext,
    size: CGSize,
    yFraction: CGFloat,
    phase: Double,
    amplitude: CGFloat,
    width: CGFloat,
    color: Color
  ) {
    var path = Path()
    let samples = 110

    for index in 0...samples {
      let p = CGFloat(index) / CGFloat(samples)
      let x = p * size.width
      let wave = CGFloat(sin(Double(p) * 6.8 + phase)) * amplitude
      let secondary = CGFloat(cos(Double(p) * 11.0 - phase * 0.62)) * amplitude * 0.24
      let y = size.height * yFraction + wave + secondary

      if index == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }

    context.drawLayer { layer in
      layer.addFilter(.blur(radius: 12))
      layer.stroke(path, with: .color(color.opacity(0.70)), lineWidth: width * 2.4)
    }
    context.stroke(path, with: .color(color), lineWidth: width)
    context.stroke(path, with: .color(.white.opacity(0.10)), lineWidth: 0.9)
  }
}

private struct LiquidMetalEdgeGlow: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: VisualTokens.panelCorner, style: .continuous)
        .strokeBorder(
          LinearGradient(
            colors: [
              Color(red: 1.0, green: 0.77, blue: 0.48).opacity(VisualTokens.Edge.warmOpacity),
              .white.opacity(VisualTokens.Edge.whiteOpacity),
              Color(red: 0.54, green: 0.80, blue: 1.0).opacity(VisualTokens.Edge.coolOpacity),
              .white.opacity(0.46),
              Color(red: 1.0, green: 0.74, blue: 0.42)
                .opacity(VisualTokens.Edge.warmOpacity * 0.86),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: VisualTokens.Edge.line
        )
        .shadow(
          color: Color(red: 0.46, green: 0.76, blue: 1.0).opacity(0.48),
          radius: VisualTokens.Edge.blur,
          x: VisualTokens.Edge.coolInset
        )
        .shadow(
          color: Color(red: 1.0, green: 0.73, blue: 0.42).opacity(0.50),
          radius: VisualTokens.Edge.blur,
          x: -VisualTokens.Edge.warmInset
        )

      RoundedRectangle(cornerRadius: max(1, VisualTokens.panelCorner - 2.5), style: .continuous)
        .strokeBorder(.white.opacity(0.28), lineWidth: 0.8)
        .padding(3)

      RoundedRectangle(cornerRadius: VisualTokens.panelCorner + 2, style: .continuous)
        .strokeBorder(
          LinearGradient(
            colors: [
              .white.opacity(0.18),
              Color(red: 0.50, green: 0.79, blue: 1.0).opacity(0.25),
              .white.opacity(0.04),
              Color(red: 1.0, green: 0.73, blue: 0.42).opacity(0.24),
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
          ),
          lineWidth: 4.6
        )
        .blur(radius: 3.5)
        .opacity(0.72)
    }
    .allowsHitTesting(false)
  }
}

private struct WholeWindowLightSweep: View {
  let time: Double

  var body: some View {
    Canvas { context, size in
      drawBeam(context: &context, size: size)
    }
    .blendMode(.screen)
  }

  private func drawBeam(context: inout GraphicsContext, size: CGSize) {
    let period = VisualTokens.Animation.sweepPeriod
    let rawProgress = (time / period).truncatingRemainder(dividingBy: 1.0)
    let progress = rawProgress < 0 ? rawProgress + 1.0 : rawProgress
    let eased = 0.5 - 0.5 * cos(progress * .pi)
    let centerX = size.width * CGFloat(-0.32 + eased * 1.64)
    let phase = time * 0.071

    var path = Path()
    let samples = 72

    for index in 0...samples {
      let p = CGFloat(index) / CGFloat(samples)
      let y = size.height * (-0.22 + p * 1.44)
      let curve =
        CGFloat(sin(Double(p) * 4.8 + phase)) * size.width * 0.046
        + CGFloat(cos(Double(p) * 8.7 - phase * 0.57)) * size.width * 0.018
      let lean = (p - 0.5) * size.width * CGFloat(0.15 + 0.035 * sin(phase * 0.43))
      let x = centerX + curve + lean

      if index == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }

    context.drawLayer { layer in
      layer.addFilter(.blur(radius: 46))
      layer.stroke(
        path,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.58, green: 0.79, blue: 1.0).opacity(0.025),
            Color.white.opacity(0.15),
            Color(red: 1.0, green: 0.79, blue: 0.54).opacity(0.09),
          ]),
          startPoint: CGPoint(x: centerX, y: 0),
          endPoint: CGPoint(x: centerX, y: size.height)
        ),
        lineWidth: max(100, size.width * 0.17)
      )
    }

    context.drawLayer { layer in
      layer.addFilter(.blur(radius: 18))
      layer.stroke(
        path,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.68, green: 0.86, blue: 1.0).opacity(0.07),
            Color.white.opacity(0.24),
            Color(red: 1.0, green: 0.84, blue: 0.62).opacity(0.12),
          ]),
          startPoint: CGPoint(x: centerX, y: 0),
          endPoint: CGPoint(x: centerX, y: size.height)
        ),
        lineWidth: max(38, size.width * 0.060)
      )
    }
  }
}

private struct DeepSpaceGlow: View {
  let time: Double

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let warmDrift = CGFloat(sin(time * 0.043)) * 18
      let coolDrift = CGFloat(cos(time * 0.039)) * 18

      ZStack {
        Ellipse()
          .fill(Color(red: 1.0, green: 0.72, blue: 0.40).opacity(0.10))
          .frame(width: size.width * 0.46, height: size.height * 0.28)
          .blur(radius: 50)
          .position(x: size.width * 0.19 + warmDrift, y: size.height * 0.91)

        Ellipse()
          .fill(Color(red: 0.40, green: 0.72, blue: 1.0).opacity(0.11))
          .frame(width: size.width * 0.48, height: size.height * 0.30)
          .blur(radius: 54)
          .position(x: size.width * 0.84 + coolDrift, y: size.height * 0.88)
      }
      .blendMode(.plusLighter)
    }
    .allowsHitTesting(false)
  }
}

private struct IrregularLightTrails: View {
  let time: Double

  var body: some View {
    Canvas { context, size in
      drawTrail(
        in: &context,
        size: size,
        yFraction: 0.30,
        phase: time * 0.041,
        amplitude: 32,
        color: Color(red: 0.63, green: 0.82, blue: 1.0).opacity(0.085),
        lineWidth: 3.5
      )

      drawTrail(
        in: &context,
        size: size,
        yFraction: 0.80,
        phase: time * 0.036 + 2.2,
        amplitude: 26,
        color: Color(red: 1.0, green: 0.76, blue: 0.46).opacity(0.080),
        lineWidth: 3.2
      )
    }
    .blur(radius: 0.9)
    .allowsHitTesting(false)
  }

  private func drawTrail(
    in context: inout GraphicsContext,
    size: CGSize,
    yFraction: CGFloat,
    phase: Double,
    amplitude: CGFloat,
    color: Color,
    lineWidth: CGFloat
  ) {
    var path = Path()
    let samples = 80

    for index in 0...samples {
      let nx = CGFloat(index) / CGFloat(samples)
      let x = nx * size.width
      let wave = CGFloat(sin(Double(nx) * 7.4 + phase * 1.2)) * amplitude
      let secondaryWave = CGFloat(sin(Double(nx) * 3.1 - phase * 0.66)) * amplitude * 0.34
      let y = size.height * yFraction + wave + secondaryWave

      if index == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }

    context.drawLayer { layer in
      layer.addFilter(.blur(radius: 13))
      layer.stroke(path, with: .color(color.opacity(0.70)), lineWidth: lineWidth * 2.4)
    }
    context.drawLayer { layer in
      layer.addFilter(.blur(radius: 3))
      layer.stroke(path, with: .color(color), lineWidth: lineWidth)
    }
  }
}

private struct AmbientParticleField: View {
  let time: Double

  var body: some View {
    Canvas { context, size in
      for index in 0..<24 {
        let i = Double(index)
        let seedX = fract(sin(i * 17.17 + 1.7) * 41_758.31)
        let seedY = fract(sin(i * 39.31 + 7.1) * 12_731.83)
        let seedR = fract(sin(i * 11.91 + 4.2) * 9_173.11)
        let seedHue = fract(sin(i * 27.13 + 5.8) * 16_723.09)

        let driftX = sin(time * 0.034 + i * 0.73) * 9
        let driftY = cos(time * 0.029 + i * 0.47) * 7
        let x = CGFloat(seedX) * size.width + CGFloat(driftX)
        let y = CGFloat(seedY) * size.height + CGFloat(driftY)
        let radius = CGFloat(0.45 + seedR * 1.45)
        let alpha = 0.035 + seedR * 0.080

        let particleColor: Color =
          if seedHue < 0.33 {
            Color(red: 1.0, green: 0.78, blue: 0.50)
          } else if seedHue > 0.72 {
            Color(red: 0.58, green: 0.80, blue: 1.0)
          } else {
            .white
          }

        context.drawLayer { layer in
          if radius > 1.2 {
            layer.addFilter(.blur(radius: 1.8))
          }
          layer.fill(
            Path(
              ellipseIn: CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2,
                height: radius * 2
              )
            ),
            with: .color(particleColor.opacity(alpha))
          )
        }
      }
    }
    .allowsHitTesting(false)
  }

  private func fract(_ value: Double) -> Double {
    value - floor(value)
  }
}

private func animationTime(_ date: Date) -> Double {
  date.timeIntervalSinceReferenceDate
    .truncatingRemainder(dividingBy: 20_000)
}
