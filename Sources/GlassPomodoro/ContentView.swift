import SwiftUI

struct ContentView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var stats: StatsStore
    @State private var newTask = ""

    var body: some View {
        ZStack {
            ThematicBackground(
                tint: engine.tint,
                secondary: engine.secondaryTint,
                isRunning: engine.isRunning,
                intensity: engine.backgroundIntensity,
                finalStretch: engine.isFinalStretch
            )

            VStack(spacing: 13) {
                header
                statusStrip
                motivationRow
                presetPicker
                tagStrip

                ZStack {
                    TechDial(
                        progress: engine.progress,
                        timeString: engine.timeString,
                        phaseLabel: engine.phase.rawValue,
                        tint: engine.tint,
                        secondary: engine.secondaryTint,
                        isRunning: engine.isRunning,
                        finalStretch: engine.isFinalStretch
                    )
                    .frame(maxWidth: 310)

                    // HUD brackets sci-fi enmarcando el dial
                    HUDBrackets(tint: engine.tint, pulse: engine.isRunning)
                        .frame(maxWidth: 350, maxHeight: 350)

                    // Celebración al completar sesión
                    if engine.justCompletedSession {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(.green)
                                .shadow(color: .green.opacity(0.8), radius: 12)
                            Text("SESSION COMPLETE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(.white)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Color.green.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.4), value: engine.justCompletedSession)

                focusStrip
                quoteView
                controls
                Divider().overlay(Color.white.opacity(0.08))
                taskPanel
            }
            .padding(24)
            .background(panelBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.clear)
                    .overlay(Scanlines().clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)))
                    .allowsHitTesting(false)
            )
            .padding(26)
        }
        .animation(.easeInOut(duration: 0.5), value: engine.phase)
        .animation(.easeInOut(duration: 0.4), value: engine.preset)
        .animation(.easeInOut(duration: 0.25), value: taskStore.tasks)
    }

    // MARK: - Motivation row (streak + daily goal + weekly activity)

    private var motivationRow: some View {
        HStack(spacing: 14) {
            StreakBadge(streak: stats.streak, tint: engine.tint)
            Spacer()
            GoalRing(
                done: stats.sessionsToday(sessionMinutes: Int(engine.preset.focusMinutes)),
                goal: stats.dailyGoalSessions,
                tint: engine.tint
            )
            Spacer()
            ActivityBars(
                values: stats.last7Days,
                goalMinutes: stats.dailyGoalSessions * Int(engine.preset.focusMinutes),
                tint: engine.tint
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    // MARK: - Header (branding terminal-style)

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 0) {
                Text("GROOVINAPPS")
                    .foregroundStyle(engine.tint)
                Text("//")
                    .foregroundStyle(.white.opacity(0.30))
                Text("POMODORO")
                    .foregroundStyle(.white.opacity(0.90))
            }
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .tracking(2.5)
            .shadow(color: engine.tint.opacity(0.4), radius: 8)

            Spacer()

            Text("v1.4")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
        }
    }

    /// Barra de estado tipo terminal financiero: métricas de la jornada
    private var statusStrip: some View {
        HStack(spacing: 0) {
            metric("SESSIONS", "\(engine.completedFocusSessions)")
            divider
            metric("FOCUS TIME", "\(engine.focusMinutesToday)m")
            divider
            metric("TASKS", "\(taskStore.tasks.filter(\.done).count)/\(taskStore.tasks.count)")
            divider
            metric("MODE", engine.preset.rawValue)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func metric(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(engine.tint)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.10)).frame(width: 1, height: 14)
    }

    // MARK: - Presets

    private var presetPicker: some View {
        HStack(spacing: 8) {
            ForEach(SessionPreset.allCases, id: \.self) { preset in
                Button {
                    engine.apply(preset: preset)
                } label: {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Text(preset.rawValue)
                                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            Text("\(Int(preset.focusMinutes))′")
                                .font(.system(size: 10.5, weight: .light, design: .monospaced))
                        }
                        Text(preset.subtitle)
                            .font(.system(size: 7.5, design: .monospaced))
                            .opacity(0.55)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(engine.preset == preset ? preset.tint.opacity(0.18) : .white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(
                                engine.preset == preset ? preset.tint.opacity(0.75) : preset.tint.opacity(0.18),
                                lineWidth: 1
                            )
                    )
                    .foregroundStyle(engine.preset == preset ? preset.tint : .white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tag de skill (v1.4 — deliberate practice: qué estás practicando)

    /// Selector del skill que se practica en esta sesión (Ericsson: well-defined goals).
    /// El tag persiste como default entre sesiones y lanzamientos.
    private var tagStrip: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag")
                .font(.system(size: 10))
                .foregroundStyle(engine.tint.opacity(0.7))
            Text("SKILL")
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            Picker("", selection: $stats.currentTag) {
                ForEach(StatsStore.roadmapTags, id: \.self) { tag in
                    Text(tag).tag(tag)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(engine.tint)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))

            Spacer()

            // minutos de la semana en el tag activo — feedback inmediato (Csikszentmihalyi)
            Text("\(stats.minutesThisWeek(tag: stats.currentTag))m esta semana")
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundStyle(engine.tint.opacity(0.75))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    // MARK: - Focus actual (la intención de ESTA sesión)

    @ViewBuilder
    private var focusStrip: some View {
        if let task = taskStore.focusedTask {
            HStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.system(size: 11))
                    .foregroundStyle(engine.tint)
                Text(task.title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                Spacer()
                Button {
                    taskStore.toggle(task)
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(engine.tint.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Marcar completada")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(engine.tint.opacity(0.10))
                    .overlay(Capsule().strokeBorder(engine.tint.opacity(0.35), lineWidth: 1))
            )
            .transition(.opacity)
        } else {
            Text("sin foco — agregá una tarea abajo")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
                .padding(.vertical, 8)
        }
    }

    // MARK: - Quote (solo breaks)

    @ViewBuilder
    private var quoteView: some View {
        if engine.phase != .focus {
            VStack(spacing: 3) {
                Text("\u{201C}\(engine.currentQuote.text)\u{201D}")
                    .font(.system(size: 11.5, weight: .light, design: .serif))
                    .italic()
                    .multilineTextAlignment(.center)
                Text("— \(engine.currentQuote.author)")
                    .font(.system(size: 9.5, design: .monospaced))
                    .opacity(0.5)
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 18)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 16) {
            GlassButton(icon: "arrow.counterclockwise", size: 42, tint: .white.opacity(0.65)) {
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
                        .frame(width: 64, height: 64)
                        .shadow(color: engine.tint.opacity(0.55), radius: 14, y: 4)
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(.black.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            GlassButton(icon: "forward.end", size: 42, tint: .white.opacity(0.65)) {
                engine.skip()
            }
        }
    }

    // MARK: - Task panel (patrón Session: lista corta, 1 foco)

    private var taskPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TODAY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                if taskStore.tasks.contains(where: \.done) {
                    Button("limpiar hechas") { taskStore.clearDone() }
                        .buttonStyle(.plain)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            // Quick add (patrón Todoist: 1 campo, Enter)
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 10))
                    .foregroundStyle(engine.tint.opacity(0.7))
                TextField("nueva intención… (Enter)", text: $newTask)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .onSubmit {
                        taskStore.add(newTask)
                        newTask = ""
                    }
                if taskStore.tasks.count >= TaskStore.maxTasks {
                    Text("máx \(TaskStore.maxTasks)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.orange.opacity(0.6))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )

            // Lista (máx 7 — scroll no debería hacer falta)
            ForEach(taskStore.tasks) { task in
                HStack(spacing: 9) {
                    Button {
                        taskStore.toggle(task)
                    } label: {
                        Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 13))
                            .foregroundStyle(task.done ? engine.tint : .white.opacity(0.3))
                    }
                    .buttonStyle(.plain)

                    Text(task.title)
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundStyle(task.done ? .white.opacity(0.3) : .white.opacity(0.8))
                        .strikethrough(task.done, color: .white.opacity(0.3))
                        .lineLimit(1)

                    Spacer()

                    if taskStore.focusedTaskID == task.id && !task.done {
                        Text("FOCUS")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(engine.tint)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(engine.tint.opacity(0.15)))
                    } else if !task.done {
                        Button {
                            taskStore.focus(task)
                        } label: {
                            Image(systemName: "scope")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        .buttonStyle(.plain)
                        .help("Hacer foco de la sesión")
                    }

                    Button {
                        taskStore.remove(task)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.2))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Panel background

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.black.opacity(0.25))
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.4),
                                     engine.tint.opacity(0.2),
                                     .white.opacity(0.04)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: engine.tint.opacity(0.12), radius: 36)
            .shadow(color: .black.opacity(0.45), radius: 28, y: 12)
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
                .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
