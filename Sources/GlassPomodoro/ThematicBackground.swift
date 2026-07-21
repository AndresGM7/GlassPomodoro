import SwiftUI

/// Fondo animado v2 — movimiento continuo garantizado via TimelineView.
/// Capas: aurora pulsante → grid perspectiva tipo tron → curva de mercado viva
/// → partículas → símbolos de dominios orbitando con deriva senoidal.
struct ThematicBackground: View {
    let tint: Color
    let secondary: Color
    let isRunning: Bool
    var intensity: Double = 0.6      // 0.25 pausado → 1.0 fin de sesión
    var finalStretch: Bool = false   // últimos 60s: pulso suave global

    var body: some View {
        // paused: cuando el timer no corre, congela el redibujado (30fps → 0)
        // y el CPU baja de ~40% a ~0% en idle. FIX bug CPU.
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isRunning)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // Pulso final: oscilación lenta de intensidad (aviso, no alarma)
            let effIntensity = finalStretch
                ? intensity * (0.85 + 0.15 * sin(t * 2.0))
                : intensity
            ZStack {
                // Capa 1: base oscura
                LinearGradient(
                    colors: [Color(red: 0.03, green: 0.04, blue: 0.09),
                             Color(red: 0.08, green: 0.06, blue: 0.16)],
                    startPoint: .top, endPoint: .bottom
                )

                // Capa 2: aurora que respira y se mueve
                AuroraLayer(t: t, tint: tint, secondary: secondary)
                    .opacity(0.5 + effIntensity * 0.5)

                // Capa 3: grid en perspectiva
                PerspectiveGrid(t: t, tint: tint, speedFactor: 0.5 + effIntensity)
                    .opacity(0.4 + effIntensity * 0.6)

                // Capa 4: curva de mercado
                LiveMarketCurve(t: t, tint: tint)
                    .opacity(0.5 + effIntensity * 0.5)

                // Capa 5: partículas (más densas con el progreso)
                ParticleField(t: t, tint: tint, secondary: secondary,
                              density: effIntensity)

                // Capa 6: símbolos de dominios
                DomainSymbolsLayer(t: t, tint: tint, isRunning: isRunning)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Capa 2: Aurora viva

private struct AuroraLayer: View {
    let t: TimeInterval
    let tint: Color
    let secondary: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle()
                    .fill(tint.opacity(0.45))
                    .frame(width: w * 0.8)
                    .blur(radius: 90)
                    .offset(x: sin(t * 0.13) * w * 0.25 - w * 0.2,
                            y: cos(t * 0.09) * h * 0.20 - h * 0.25)
                Circle()
                    .fill(secondary.opacity(0.38))
                    .frame(width: w * 0.7)
                    .blur(radius: 100)
                    .offset(x: cos(t * 0.11) * w * 0.28 + w * 0.22,
                            y: sin(t * 0.15) * h * 0.22 + h * 0.28)
                Circle()
                    .fill(Color(red: 0.15, green: 0.95, blue: 0.6).opacity(0.20))
                    .frame(width: w * 0.5)
                    .blur(radius: 80)
                    .offset(x: sin(t * 0.17 + 2) * w * 0.3,
                            y: cos(t * 0.12 + 1) * h * 0.3)
            }
        }
    }
}

// MARK: - Capa 3: Grid perspectiva (synthwave)

private struct PerspectiveGrid: View {
    let t: TimeInterval
    let tint: Color
    var speedFactor: Double = 1.0

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let horizonY = h * 0.62
            let vanishX = w / 2

            // Líneas verticales que convergen al punto de fuga
            for i in stride(from: -10, through: 10, by: 1) {
                let bottomX = vanishX + CGFloat(i) * w * 0.16
                var path = Path()
                path.move(to: CGPoint(x: vanishX, y: horizonY))
                path.addLine(to: CGPoint(x: bottomX, y: h))
                context.stroke(path, with: .color(tint.opacity(0.10)), lineWidth: 0.8)
            }

            // Líneas horizontales que "avanzan" hacia el espectador (loop con t)
            let speed = 0.35 * speedFactor
            for i in 0..<14 {
                let phase = (Double(i) / 14.0 + t * speed / 14.0).truncatingRemainder(dividingBy: 1.0)
                // easing: cerca del horizonte densas, abajo espaciadas
                let y = horizonY + pow(phase, 2.2) * (h - horizonY)
                let alpha = 0.03 + phase * 0.14
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: w, y: y))
                context.stroke(path, with: .color(tint.opacity(alpha)), lineWidth: phase > 0.85 ? 1.4 : 0.8)
            }

            // Línea de horizonte con glow
            var horizon = Path()
            horizon.move(to: CGPoint(x: 0, y: horizonY))
            horizon.addLine(to: CGPoint(x: w, y: horizonY))
            context.stroke(horizon, with: .color(tint.opacity(0.25)), lineWidth: 1.2)
        }
        .opacity(0.85)
        .allowsHitTesting(false)
    }
}

// MARK: - Capa 4: Curva de mercado viva

private struct LiveMarketCurve: View {
    let t: TimeInterval
    let tint: Color

    private func value(at x: Double) -> Double {
        // Suma de senos = pseudo random walk suave y continuo
        return 0.5
            + 0.16 * sin(x * 1.7 + t * 0.5)
            + 0.10 * sin(x * 3.3 - t * 0.33)
            + 0.06 * sin(x * 7.1 + t * 0.21)
            + 0.04 * sin(x * 13.7 - t * 0.6)
    }

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let baseY = h * 0.34
            let amp = h * 0.16
            let n = 90

            var line = Path()
            var fill = Path()
            for i in 0...n {
                let fx = Double(i) / Double(n)
                let x = fx * w
                let y = baseY + (value(at: fx * 6 + t * 0.12) - 0.5) * amp * 2
                if i == 0 {
                    line.move(to: CGPoint(x: x, y: y))
                    fill.move(to: CGPoint(x: x, y: y))
                } else {
                    line.addLine(to: CGPoint(x: x, y: y))
                    fill.addLine(to: CGPoint(x: x, y: y))
                }
            }
            // Área bajo la curva con gradiente sutil
            fill.addLine(to: CGPoint(x: w, y: baseY + amp * 1.6))
            fill.addLine(to: CGPoint(x: 0, y: baseY + amp * 1.6))
            fill.closeSubpath()
            context.fill(fill, with: .linearGradient(
                Gradient(colors: [tint.opacity(0.10), .clear]),
                startPoint: CGPoint(x: 0, y: baseY - amp),
                endPoint: CGPoint(x: 0, y: baseY + amp * 1.6)
            ))
            context.stroke(line, with: .color(tint.opacity(0.55)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))

            // Punto "último precio" pulsante en el borde derecho
            let lastY = baseY + (value(at: 6 + t * 0.12) - 0.5) * amp * 2
            let pulse = 3.5 + sin(t * 4) * 1.5
            let dot = Path(ellipseIn: CGRect(x: w - 14 - pulse / 2, y: lastY - pulse / 2, width: pulse, height: pulse))
            context.fill(dot, with: .color(tint))
            let halo = Path(ellipseIn: CGRect(x: w - 14 - pulse * 1.6, y: lastY - pulse * 1.6, width: pulse * 3.2, height: pulse * 3.2))
            context.fill(halo, with: .color(tint.opacity(0.25)))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Capa 5: Partículas ascendentes

private struct ParticleField: View {
    let t: TimeInterval
    let tint: Color
    let secondary: Color
    var density: Double = 0.6   // 0-1: cuántas partículas se muestran

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let maxCount = 48
            let count = Int(14 + density * Double(maxCount - 14))

            for i in 0..<count {
                let seed = Double(i) * 127.31
                let speed = 0.018 + (seed.truncatingRemainder(dividingBy: 1.0)) * 0.03
                let xBase = (seed * 0.618).truncatingRemainder(dividingBy: 1.0)
                let phase = (t * speed + seed).truncatingRemainder(dividingBy: 1.0)
                let y = h * (1.05 - phase * 1.1)
                let x = w * xBase + sin(t * 0.4 + seed) * 22
                let sizeP = 1.2 + (seed.truncatingRemainder(dividingBy: 3.0))
                let alpha = 0.35 * sin(phase * .pi)  // fade in/out
                let color = i % 3 == 0 ? secondary : tint

                let rect = CGRect(x: x, y: y, width: sizeP, height: sizeP)
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Capa 6: Símbolos de dominios (deriva senoidal amplia y visible)

private struct DomainSpec {
    let content: Content
    let baseX: Double     // 0-1
    let baseY: Double
    let size: CGFloat
    let ampX: Double      // amplitud de deriva en px
    let ampY: Double
    let speed: Double
    let phase: Double
    let opacity: Double

    enum Content {
        case text(String)
        case symbol(String)
    }
}

private struct DomainSymbolsLayer: View {
    let t: TimeInterval
    let tint: Color
    let isRunning: Bool

    private static let specs: [DomainSpec] = [
        // Econometría
        .init(content: .text("β̂ = (X′X)⁻¹X′y"), baseX: 0.13, baseY: 0.13, size: 14, ampX: 30, ampY: 22, speed: 0.21, phase: 0.0, opacity: 0.65),
        .init(content: .text("E[y|x]"), baseX: 0.86, baseY: 0.22, size: 16, ampX: 26, ampY: 30, speed: 0.17, phase: 1.1, opacity: 0.55),
        .init(content: .text("σ²"), baseX: 0.24, baseY: 0.82, size: 20, ampX: 34, ampY: 24, speed: 0.25, phase: 2.3, opacity: 0.50),
        .init(content: .text("∇θJ(θ)"), baseX: 0.79, baseY: 0.74, size: 15, ampX: 28, ampY: 32, speed: 0.19, phase: 3.0, opacity: 0.60),
        // Macro
        .init(content: .text("IS·LM"), baseX: 0.07, baseY: 0.52, size: 13, ampX: 24, ampY: 28, speed: 0.15, phase: 0.7, opacity: 0.48),
        .init(content: .text("π = πₑ + κ(y−ȳ)"), baseX: 0.62, baseY: 0.07, size: 12, ampX: 32, ampY: 18, speed: 0.13, phase: 1.9, opacity: 0.52),
        // AI / agentes
        .init(content: .symbol("brain"), baseX: 0.93, baseY: 0.48, size: 18, ampX: 22, ampY: 34, speed: 0.23, phase: 0.4, opacity: 0.55),
        .init(content: .symbol("cpu"), baseX: 0.14, baseY: 0.33, size: 16, ampX: 28, ampY: 26, speed: 0.18, phase: 2.8, opacity: 0.50),
        .init(content: .symbol("point.3.connected.trianglepath.dotted"), baseX: 0.51, baseY: 0.90, size: 17, ampX: 36, ampY: 20, speed: 0.22, phase: 1.4, opacity: 0.55),
        // Data science
        .init(content: .symbol("chart.line.uptrend.xyaxis"), baseX: 0.37, baseY: 0.10, size: 16, ampX: 30, ampY: 24, speed: 0.20, phase: 3.6, opacity: 0.50),
        .init(content: .symbol("chart.bar.xaxis"), baseX: 0.91, baseY: 0.88, size: 14, ampX: 26, ampY: 28, speed: 0.16, phase: 0.9, opacity: 0.45),
        // Programmatic
        .init(content: .text("bid = f(p̂ᵥ)"), baseX: 0.30, baseY: 0.58, size: 13, ampX: 34, ampY: 26, speed: 0.24, phase: 2.0, opacity: 0.55),
        .init(content: .symbol("megaphone"), baseX: 0.70, baseY: 0.40, size: 13, ampX: 24, ampY: 30, speed: 0.14, phase: 4.2, opacity: 0.40),
        // Naturaleza
        .init(content: .symbol("leaf.fill"), baseX: 0.06, baseY: 0.90, size: 16, ampX: 40, ampY: 30, speed: 0.12, phase: 0.2, opacity: 0.50),
        .init(content: .symbol("tree"), baseX: 0.55, baseY: 0.28, size: 14, ampX: 28, ampY: 22, speed: 0.11, phase: 1.6, opacity: 0.42),
        .init(content: .symbol("wind"), baseX: 0.44, baseY: 0.72, size: 14, ampX: 44, ampY: 18, speed: 0.26, phase: 2.6, opacity: 0.45),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(Self.specs.enumerated()), id: \.offset) { _, spec in
                    let dx = sin(t * spec.speed + spec.phase) * spec.ampX
                    let dy = cos(t * spec.speed * 0.8 + spec.phase * 1.3) * spec.ampY
                    let rot = sin(t * spec.speed * 0.5 + spec.phase) * 6
                    let flicker = 0.85 + 0.15 * sin(t * 0.7 + spec.phase * 2)

                    Group {
                        switch spec.content {
                        case .text(let str):
                            Text(str)
                                .font(.system(size: spec.size, weight: .light, design: .serif))
                                .italic()
                        case .symbol(let name):
                            Image(systemName: name)
                                .font(.system(size: spec.size, weight: .light))
                        }
                    }
                    .foregroundStyle(tint.opacity(spec.opacity * flicker * (isRunning ? 1.0 : 0.55)))
                    .shadow(color: tint.opacity(0.6), radius: 6)
                    .rotationEffect(.degrees(rot))
                    .position(x: geo.size.width * spec.baseX + dx,
                              y: geo.size.height * spec.baseY + dy)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
