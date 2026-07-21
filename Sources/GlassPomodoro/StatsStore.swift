import SwiftUI
import Foundation

// MARK: - Session Record (v1.4 — deliberate practice: cada sesión con tag + intención)

/// Una sesión de focus completada, con su contexto de deliberate practice:
/// qué skill se practicó (tag) y cuál era el objetivo del bloque (intention).
/// Evidencia: Ericsson 1993 — practice sin well-defined goals no mejora performance.
struct SessionRecord: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let minutes: Int
    let preset: String        // QUICK / FLOW / DEEP
    let tag: String           // skill del roadmap (ej: "S2 Observability")
    let intention: String?    // focused task al momento de completar
}

/// Historial de sesiones + streak + meta diaria (mecánicas Duolingo/Apple Rings).
@MainActor
final class StatsStore: ObservableObject {
    /// minutos de focus completados por día (clave = yyyy-MM-dd)
    @Published private(set) var dailyMinutes: [String: Int] = [:] { didSet { save() } }
    @Published var dailyGoalSessions: Int = 4   // meta: 4 sesiones/día

    // ── v1.4: sesiones individuales con tag + intención
    @Published private(set) var sessions: [SessionRecord] = [] { didSet { saveSessions() } }
    /// tag activo — default semanal; persiste entre lanzamientos
    @Published var currentTag: String {
        didSet { UserDefaults.standard.set(currentTag, forKey: tagKey) }
    }

    /// Tags seed = roadmap 12 semanas (editable a futuro; por ahora lista fija + General)
    static let roadmapTags: [String] = [
        "S1 Async/GIL",
        "S2 Observability",
        "S3 Testing",
        "S4 ML Pipeline CI/CD",
        "S5 API Design",
        "S6 SQL/Índices",
        "S7 RL para RTB",
        "S8 RAG/Retrieval",
        "S9 Evals/Guardrails",
        "S10 System Design",
        "S11 Security/OWASP",
        "S12 Síntesis",
        "Trabajo",
        "General",
    ]

    private let key = "glasspomodoro.stats.v1"
    private let sessionsKey = "glasspomodoro.sessions.v1"
    private let tagKey = "glasspomodoro.currentTag.v1"
    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        currentTag = UserDefaults.standard.string(forKey: tagKey) ?? "General"
        load()
        loadSessions()
    }

    private func dayKey(_ date: Date = Date()) -> String { df.string(from: date) }

    /// registra una sesión de focus completada (con contexto de deliberate practice)
    func record(minutes: Int, preset: String = "", intention: String? = nil) {
        let k = dayKey()
        dailyMinutes[k, default: 0] += minutes
        sessions.append(SessionRecord(
            date: Date(),
            minutes: minutes,
            preset: preset,
            tag: currentTag,
            intention: intention
        ))
    }

    var minutesToday: Int { dailyMinutes[dayKey()] ?? 0 }

    /// sesiones equivalentes hoy (aprox por bloques de 25)
    func sessionsToday(sessionMinutes: Int) -> Int {
        guard sessionMinutes > 0 else { return 0 }
        return minutesToday / sessionMinutes
    }

    /// streak: días consecutivos (incluyendo hoy si ya hay actividad) con >0 min
    var streak: Int {
        var count = 0
        var day = Date()
        // si hoy no tiene actividad todavía, el streak arranca desde ayer
        if (dailyMinutes[dayKey(day)] ?? 0) == 0 {
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        }
        while (dailyMinutes[dayKey(day)] ?? 0) > 0 {
            count += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    /// últimos 7 días de minutos (para el activity chart), hoy al final
    var last7Days: [Int] {
        (0..<7).reversed().map { offset in
            let d = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            return dailyMinutes[dayKey(d)] ?? 0
        }
    }

    // MARK: v1.4 — analytics por tag

    /// minutos de esta semana (lunes-domingo) para un tag dado
    func minutesThisWeek(tag: String) -> Int {
        guard let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start
        else { return 0 }
        return sessions
            .filter { $0.date >= weekStart && $0.tag == tag }
            .reduce(0) { $0 + $1.minutes }
    }

    /// minutos de esta semana agrupados por tag (para el weekly review)
    var weekByTag: [(tag: String, minutes: Int)] {
        guard let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start
        else { return [] }
        let grouped = Dictionary(grouping: sessions.filter { $0.date >= weekStart }, by: \.tag)
        return grouped
            .map { (tag: $0.key, minutes: $0.value.reduce(0) { $0 + $1.minutes }) }
            .sorted { $0.minutes > $1.minutes }
    }

    // MARK: persistence
    private func save() {
        if let data = try? JSONEncoder().encode(dailyMinutes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([String: Int].self, from: data) {
            dailyMinutes = saved
        }
    }
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let saved = try? JSONDecoder().decode([SessionRecord].self, from: data) {
            sessions = saved
        }
    }
}
