import SwiftUI
import AppKit

/// FIX bug #2: sin esto, macOS termina la app al cerrar la última ventana
/// y el ícono desaparece de la barra de menú.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false   // la app vive en el menu bar aunque cierres la ventana
    }
}

@main
struct GlassPomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var engine = TimerEngine()
    @StateObject private var taskStore = TaskStore()

    var body: some Scene {
        // Ventana principal (id para reabrirla desde el menu bar)
        Window("GroovinApps Pomodoro", id: "main") {
            ContentView()
                .environmentObject(engine)
                .environmentObject(taskStore)
                .frame(minWidth: 560, minHeight: 780)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // Menu bar (pestaña de arriba) — timer visible + controles rápidos
        MenuBarExtra {
            MenuBarView()
                .environmentObject(engine)
                .environmentObject(taskStore)
        } label: {
            // Lo que se ve en la barra: icono + tiempo restante
            HStack(spacing: 4) {
                Image(systemName: engine.isRunning ? "timer" : "timer.circle")
                Text(engine.isRunning || engine.progress > 0 ? engine.timeString : "")
                    .font(.system(.body, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
    }
}

/// Vista compacta que vive en el menu bar
struct MenuBarView: View {
    @EnvironmentObject var engine: TimerEngine
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 14) {
            Text(engine.phase.rawValue)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(engine.tint)

            Text(engine.timeString)
                .font(.system(size: 34, weight: .thin, design: .monospaced))
                .monospacedDigit()

            // Progreso lineal compacto
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.1))
                    Capsule()
                        .fill(engine.tint)
                        .frame(width: geo.size.width * engine.progress)
                        .shadow(color: engine.tint.opacity(0.8), radius: 4)
                }
            }
            .frame(height: 4)

            HStack(spacing: 12) {
                Button(engine.isRunning ? "Pause" : "Start") { engine.toggle() }
                    .keyboardShortcut(.space, modifiers: [])
                Button("Reset") { engine.reset() }
                Button("Skip") { engine.skip() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Divider()

            // Presets rápidos desde el menu bar
            HStack(spacing: 8) {
                ForEach(SessionPreset.allCases, id: \.self) { preset in
                    Button("\(Int(preset.focusMinutes))m") {
                        engine.apply(preset: preset)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: engine.preset == preset ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(engine.preset == preset ? engine.tint : .secondary)
                }
                Spacer()
                Text("\(engine.completedFocusSessions) done")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            HStack {
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "macwindow")
                        Text("Open App")
                    }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(engine.tint)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}
