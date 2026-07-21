import SwiftUI

/// Dial tech: ticks, arco con gradiente angular, glow, núcleo de vidrio.
/// Recibe el tema como parámetros (tint/secondary) — lo define el preset.
struct TechDial: View {
    let progress: Double
    let timeString: String
    let phaseLabel: String
    let tint: Color
    let secondary: Color
    let isRunning: Bool
    let finalStretch: Bool   // últimos 60s: pulso suave, no alarma

    var body: some View {
        // paused: sin timer corriendo no hay respiración que animar → 0 fps idle
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isRunning)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // Pulso sereno: respiración de 3s normal, 1.6s en final stretch
            let breatheSpeed = finalStretch ? 2.0 : 1.0
            let breathe = 1.0 + 0.025 * sin(t * breatheSpeed)
            let glowBoost = finalStretch ? (0.5 + 0.5 * sin(t * 2.5)) : 0.0

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                ZStack {
                    // Halo exterior
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tint.opacity((isRunning ? 0.30 : 0.12) + glowBoost * 0.15), .clear],
                                center: .center,
                                startRadius: size * 0.30,
                                endRadius: size * 0.55
                            )
                        )
                        .scaleEffect(breathe)

                    // Anillo de ticks
                    TickRing(progress: progress, tint: tint)
                        .frame(width: size * 0.94, height: size * 0.94)

                    // Track
                    Circle()
                        .stroke(Color.white.opacity(0.07),
                                style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                        .frame(width: size * 0.74, height: size * 0.74)

                    // Arco de progreso
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [tint, secondary, tint],
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round)
                        )
                        .frame(width: size * 0.74, height: size * 0.74)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: tint.opacity(0.85 + glowBoost * 0.15), radius: 12 + glowBoost * 8)
                        .shadow(color: secondary.opacity(0.4), radius: 26)

                    // Cabezal luminoso
                    ProgressHead(progress: progress, tint: tint)
                        .frame(width: size * 0.74, height: size * 0.74)

                    // Núcleo de vidrio
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: size * 0.58, height: size * 0.58)
                        .overlay(
                            Circle().strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.05), tint.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                        )
                        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)

                    // Contenido central
                    VStack(spacing: size * 0.015) {
                        Text(phaseLabel)
                            .font(.system(size: size * 0.035, weight: .semibold, design: .monospaced))
                            .tracking(size * 0.012)
                            .foregroundStyle(tint)

                        Text(timeString)
                            .font(.system(size: size * 0.135, weight: .thin, design: .monospaced))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(countsDown: true))
                            .monospacedDigit()

                        Text(finalStretch ? "◈ FINAL MINUTE" : (isRunning ? "● RUNNING" : "◦ PAUSED"))
                            .font(.system(size: size * 0.026, weight: .medium, design: .monospaced))
                            .foregroundStyle(isRunning ? tint : .white.opacity(0.35))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
}

private struct TickRing: View {
    let progress: Double
    let tint: Color

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2
            let tickCount = 72

            for i in 0..<tickCount {
                let frac = Double(i) / Double(tickCount)
                let angle = frac * 2 * .pi - .pi / 2
                let isMajor = i % 6 == 0
                let lit = frac <= progress

                let outer = radius
                let inner = radius - (isMajor ? radius * 0.075 : radius * 0.045)

                var path = Path()
                path.move(to: CGPoint(x: center.x + cos(angle) * inner,
                                      y: center.y + sin(angle) * inner))
                path.addLine(to: CGPoint(x: center.x + cos(angle) * outer,
                                         y: center.y + sin(angle) * outer))

                let color: Color = lit ? tint : Color.white.opacity(isMajor ? 0.25 : 0.10)
                context.stroke(path, with: .color(color),
                               style: StrokeStyle(lineWidth: isMajor ? 2.2 : 1.1, lineCap: .round))
            }
        }
    }
}

private struct ProgressHead: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            let angle = progress * 2 * .pi - .pi / 2
            let pos = CGPoint(x: geo.size.width / 2 + cos(angle) * r,
                              y: geo.size.height / 2 + sin(angle) * r)
            Circle()
                .fill(.white)
                .frame(width: 10, height: 10)
                .shadow(color: tint, radius: 8)
                .shadow(color: tint.opacity(0.8), radius: 16)
                .position(pos)
                .opacity(progress > 0.001 ? 1 : 0)
        }
    }
}
