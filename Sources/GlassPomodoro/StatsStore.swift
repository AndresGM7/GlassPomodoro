import SwiftUI
import Foundation

/// Historial de sesiones + streak + meta diaria (mecánicas Duolingo/Apple Rings).
@MainActor
final class StatsStore: ObservableObject {
    /// minutos de focus completados por día (clave = yyyy-MM-dd)
    @Published private(set) var dailyMinutes: [String: Int] = [:] { didSet { save() } }
    @Published var dailyGoalSessions: Int = 4   // meta: 4 sesiones/día

    private let key = "glasspomodoro.stats.v1"
    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() { load() }

    private func dayKey(_ date: Date = Date()) -> String { df.string(from: date) }

    /// registra una sesión de focus completada
    func record(minutes: Int) {
        let k = dayKey()
        dailyMinutes[k, default: 0] += minutes
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
}
