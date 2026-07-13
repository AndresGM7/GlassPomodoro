import SwiftUI
import AppKit

// MARK: - Session Presets (basados en evidencia)
// 25 = Pomodoro clásico (Cirillo) — tareas con resistencia
// 45 = bloque académico / DeskTime top-10% — estudio
// 90 = ciclo ultradiano (Kleitman) / deliberate practice (Ericsson) — deep work

enum SessionPreset: String, CaseIterable {
    case quick = "QUICK"
    case flow = "FLOW"
    case deep = "DEEP"

    var focusMinutes: Double {
        switch self {
        case .quick: return 25
        case .flow: return 45
        case .deep: return 90
        }
    }

    var breakMinutes: Double {
        switch self {
        case .quick: return 5
        case .flow: return 12
        case .deep: return 20
        }
    }

    var longBreakMinutes: Double {
        switch self {
        case .quick: return 15
        case .flow: return 25
        case .deep: return 30
        }
    }

    var subtitle: String {
        switch self {
        case .quick: return "Pomodoro · resistencia"
        case .flow: return "Estudio · lectura técnica"
        case .deep: return "Deep work · ultradiano"
        }
    }

    // ── Tema por preset: paleta CALMA (sin rojos ni tonos de alarma)
    var tint: Color {
        switch self {
        case .quick: return Color(red: 0.45, green: 0.85, blue: 0.80)   // seafoam sereno
        case .flow:  return Color(red: 0.55, green: 0.85, blue: 0.58)   // verde salvia
        case .deep:  return Color(red: 0.58, green: 0.58, blue: 0.95)   // índigo suave
        }
    }

    var secondaryTint: Color {
        switch self {
        case .quick: return Color(red: 0.45, green: 0.65, blue: 0.95)   // azul calmo
        case .flow:  return Color(red: 0.35, green: 0.75, blue: 0.70)   // teal bosque
        case .deep:  return Color(red: 0.78, green: 0.62, blue: 0.95)   // lavanda
        }
    }
}

// MARK: - Session Phases

enum Phase: String, CaseIterable {
    case focus = "FOCUS"
    case shortBreak = "BREAK"
    case longBreak = "LONG BREAK"
}

// MARK: - Quotes (solo en transiciones, nunca durante focus)

struct FocusQuote {
    let text: String
    let author: String

    static let all: [FocusQuote] = [
        .init(text: "Lo que no se mide, no se puede mejorar.", author: "Peter Drucker"),
        .init(text: "Correlación no implica causalidad.", author: "Econometría 101"),
        .init(text: "En el largo plazo, todos estamos muertos.", author: "J.M. Keynes"),
        .init(text: "Deep work es la superpotencia del siglo XXI.", author: "Cal Newport"),
        .init(text: "Los datos vencen a las opiniones.", author: "Jim Barksdale"),
        .init(text: "Todo modelo está mal; algunos son útiles.", author: "George Box"),
        .init(text: "La disciplina es el puente entre metas y logros.", author: "Jim Rohn"),
        .init(text: "El interés compuesto es la octava maravilla.", author: "atrib. Einstein"),
        .init(text: "Si no podés explicarlo, no lo entendés.", author: "R. Feynman"),
        .init(text: "El mercado puede ser irracional más tiempo del que vos podés ser solvente.", author: "J.M. Keynes"),
        .init(text: "Sin datos, sos solo otra persona con una opinión.", author: "W.E. Deming"),
        .init(text: "La naturaleza no da saltos.", author: "Leibniz / Marshall"),
    ]

    static func random() -> FocusQuote { all.randomElement()! }
}

// MARK: - Timer Engine

@MainActor
final class TimerEngine: ObservableObject {
    @Published var preset: SessionPreset = .quick
    @Published var sessionsUntilLongBreak: Int = 4

    @Published private(set) var phase: Phase = .focus
    @Published private(set) var remaining: TimeInterval = 25 * 60
    @Published private(set) var isRunning = false
    @Published private(set) var completedFocusSessions = 0
    @Published private(set) var currentQuote: FocusQuote = .random()
    @Published var justCompletedSession = false   // dispara celebración breve

    /// callback para registrar sesiones en StatsStore (se conecta en la App)
    var onFocusCompleted: ((Int) -> Void)?

    private var timer: Timer?
    private var endDate: Date?

    // ── Tema activo (deriva del preset; breaks suavizan aún más)
    var tint: Color {
        switch phase {
        case .focus: return preset.tint
        case .shortBreak: return Color(red: 0.60, green: 0.88, blue: 0.75)  // menta calma
        case .longBreak: return Color(red: 0.72, green: 0.68, blue: 0.92)   // lavanda calma
        }
    }

    var secondaryTint: Color {
        switch phase {
        case .focus: return preset.secondaryTint
        case .shortBreak: return Color(red: 0.45, green: 0.75, blue: 0.85)
        case .longBreak: return Color(red: 0.85, green: 0.70, blue: 0.85)
        }
    }

    var phaseDuration: TimeInterval {
        switch phase {
        case .focus: return preset.focusMinutes * 60
        case .shortBreak: return preset.breakMinutes * 60
        case .longBreak: return preset.longBreakMinutes * 60
        }
    }

    var progress: Double {
        guard phaseDuration > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / phaseDuration))
    }

    /// Intensidad del fondo: crece suavemente con el progreso (0.35 → 1.0).
    /// En pausa o break baja para transmitir calma.
    var backgroundIntensity: Double {
        guard phase == .focus else { return 0.30 }
        guard isRunning else { return 0.25 }
        return 0.35 + 0.65 * progress
    }

    /// Final gentle pulse: últimos 60s de focus — aviso sereno, no alarma.
    var isFinalStretch: Bool {
        phase == .focus && isRunning && remaining <= 60 && remaining > 0
    }

    var timeString: String {
        let total = Int(remaining.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var focusMinutesToday: Int {
        completedFocusSessions * Int(preset.focusMinutes)
    }

    // MARK: Controls

    func apply(preset newPreset: SessionPreset) {
        pause()
        preset = newPreset
        phase = .focus
        remaining = phaseDuration
    }

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        endDate = Date().addingTimeInterval(remaining)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        endDate = nil
    }

    func reset() {
        pause()
        remaining = phaseDuration
    }

    func skip() { advancePhase() }

    func select(phase newPhase: Phase) {
        pause()
        phase = newPhase
        remaining = phaseDuration
    }

    private func tick() {
        guard let end = endDate else { return }
        remaining = max(0, end.timeIntervalSinceNow)
        if remaining <= 0 {
            notifyPhaseEnd()
            advancePhase()
        }
    }

    private func advancePhase() {
        pause()
        switch phase {
        case .focus:
            completedFocusSessions += 1
            onFocusCompleted?(Int(preset.focusMinutes))   // registra en stats
            justCompletedSession = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                justCompletedSession = false
            }
            phase = (completedFocusSessions % sessionsUntilLongBreak == 0) ? .longBreak : .shortBreak
            currentQuote = .random()
        case .shortBreak, .longBreak:
            phase = .focus
        }
        remaining = phaseDuration
    }

    private func notifyPhaseEnd() {
        NSSound(named: "Glass")?.play()
    }
}
