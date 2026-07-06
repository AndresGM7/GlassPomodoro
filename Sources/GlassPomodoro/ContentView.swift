import SwiftUI

struct ContentView: View {
    @EnvironmentObject var engine: TimerEngine

    var body: some View {
        ZStack {
            // Fondo temático — intensidad reactiva al progreso + pulso final
            ThematicBackground(
                tint: engine.tint,
                secondary: engine.secondaryTint,
                isRunning: engine.isRunning,
                intensity: engine.backgroundIntensity,
                finalStretch: engine.isFinalStretch
            )

            VStack(spacing: 18) {
                header

                // Selector de PRESET (25 / 45 / 90 — basados en evidencia)
                presetPicker

                // Dial central
                TechDial(
                    progress: engine.progress,
                    timeString: engine.timeString,
                    phaseLabel: engine.phase.rawValue,
                    tint: engine.tint,
                    secondary: engine.secondaryTint,
                    isRunning: engine.isRunning,
                    finalStretch: engine.isFinalStretch
                )
                .frame(maxWidth: 360)

                // Cita — SOLO en breaks (nunca durante focus, protege el flow)
                quoteView

                controls
                sessionDots
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black.opacity(0.22))          // translúcido real: el fondo SE VE
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.5),
                                             engine.tint.opacity(0.25),
                                             .white.opacity(0.05)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: engine.tint.opacity(0.15), radius: 40)
                    .shadow(color: .black.opacity(0.4), radius: 30, y: 14)
            )
            .padding(32)
        }
        .animation(.easeInOut(duration: 0.5), value: engine.phase)
        .animation(.easeInOut(duration: 0.4), value: engine.preset)
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            HStack(spacing: 0) {
                Text("GROOVINAPPS")
                    .foregroundStyle(engine.tint)
                Text("//")
                    .foregroundStyle(.white.opacity(0.35))
                Text("POMODORO")
                    .foregroundStyle(.white.opacity(0.85))
            }
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .tracking(3)
            .shadow(color: engine.tint.opacity(0.5), radius: 8)
            Spacer()
            // Deep work acumulado hoy
            Text("\(engine.focusMinutesToday) min today")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    /// Presets 25/45/90 con subtítulo del uso recomendado
    private var presetPicker: some View {
        HStack(spacing: 10) {
            ForEach(SessionPreset.allCases, id: \.self) { preset in
                Button {
                    engine.apply(preset: preset)
                } label: {
                    VStack(spacing: 3) {
                        HStack(spacing: 5) {
                            Text(preset.rawValue)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                            Text("\(Int(preset.focusMinutes))′")
                                .font(.system(size: 11, weight: .light, design: .monospaced))
                        }
                        Text(preset.subtitle)
                            .font(.system(size: 8, design: .monospaced))
                            .opacity(0.6)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(engine.preset == preset ? preset.tint.opacity(0.20) : .white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                engine.preset == preset ? preset.tint.opacity(0.8) : preset.tint.opacity(0.25),
                                lineWidth: 1
                            )
                    )
                    .foregroundStyle(engine.preset == preset ? preset.tint : .white.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Cita visible solo durante breaks — el focus se protege
    @ViewBuilder
    private var quoteView: some View {
        if engine.phase != .focus {
            VStack(spacing: 4) {
                Text("\u{201C}\(engine.currentQuote.text)\u{201D}")
                    .font(.system(size: 12, weight: .light, design: .serif))
                    .italic()
                    .multilineTextAlignment(.center)
                Text("— \(engine.currentQuote.author)")
                    .font(.system(size: 10, design: .monospaced))
                    .opacity(0.5)
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 20)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            // Espaciador invisible para que el layout no salte
            Color.clear.frame(height: 30)
        }
    }

    private var controls: some View {
        HStack(spacing: 18) {
            GlassButton(icon: "arrow.counterclockwise", size: 46, tint: .white.opacity(0.7)) {
                engine.reset()
            }

            Button {
                engine.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [engine.tint, engine.secondaryTint],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: engine.tint.opacity(0.6), radius: 16, y: 4)
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.black.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            GlassButton(icon: "forward.end", size: 46, tint: .white.opacity(0.7)) {
                engine.skip()
            }
        }
    }

    private var sessionDots: some View {
        HStack(spacing: 10) {
            ForEach(0..<engine.sessionsUntilLongBreak, id: \.self) { i in
                let filled = i < (engine.completedFocusSessions % engine.sessionsUntilLongBreak)
                    || (engine.completedFocusSessions > 0 && engine.completedFocusSessions % engine.sessionsUntilLongBreak == 0)
                Circle()
                    .fill(filled ? engine.tint : .white.opacity(0.12))
                    .frame(width: 8, height: 8)
                    .shadow(color: filled ? engine.tint.opacity(0.8) : .clear, radius: 5)
            }
            Text("\(engine.completedFocusSessions) sessions")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.leading, 6)
        }
    }
}

// MARK: - Componentes compartidos

struct GlassButton: View {
    let icon: String
    let size: CGFloat
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
