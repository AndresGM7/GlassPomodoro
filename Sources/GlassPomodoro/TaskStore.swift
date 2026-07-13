import SwiftUI
import Foundation

struct FocusTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var done: Bool = false
}

/// Lista corta de intenciones del día (patrón Session: máx 7, una es el foco).
@MainActor
final class TaskStore: ObservableObject {
    @Published var tasks: [FocusTask] = [] { didSet { save() } }
    @Published var focusedTaskID: UUID? { didSet { saveFocus() } }

    static let maxTasks = 7
    private let key = "glasspomodoro.tasks.v1"
    private let focusKey = "glasspomodoro.focusedTask.v1"

    init() { load() }

    var focusedTask: FocusTask? {
        guard let id = focusedTaskID else { return nil }
        return tasks.first { $0.id == id && !$0.done }
    }

    func add(_ title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, tasks.count < Self.maxTasks else { return }
        let task = FocusTask(title: clean)
        tasks.append(task)
        if focusedTaskID == nil { focusedTaskID = task.id }
    }

    func toggle(_ task: FocusTask) {
        guard let i = tasks.firstIndex(of: task) else { return }
        tasks[i].done.toggle()
        // si completaste el foco, pasa al siguiente pendiente
        if tasks[i].done, focusedTaskID == task.id {
            focusedTaskID = tasks.first(where: { !$0.done })?.id
        }
    }

    func focus(_ task: FocusTask) {
        guard !task.done else { return }
        focusedTaskID = task.id
    }

    func remove(_ task: FocusTask) {
        tasks.removeAll { $0.id == task.id }
        if focusedTaskID == task.id { focusedTaskID = tasks.first(where: { !$0.done })?.id }
    }

    func clearDone() { tasks.removeAll { $0.done } }

    // MARK: persistence (UserDefaults JSON)
    private func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private func saveFocus() {
        UserDefaults.standard.set(focusedTaskID?.uuidString, forKey: focusKey)
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([FocusTask].self, from: data) {
            tasks = saved
        }
        if let s = UserDefaults.standard.string(forKey: focusKey) {
            focusedTaskID = UUID(uuidString: s)
        }
    }
}
