import Foundation

/// The lifecycle status of a task.
///
/// Tasks progress from `todo` → `inProgress` → `done`.
/// The `deferred` status is used when a task is rolled over to Backlog at day boundary.
enum TaskStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case todo
    case inProgress
    case done
    case deferred

    nonisolated var id: String { rawValue }

    /// Human-readable name for display in UI.
    nonisolated var displayName: String {
        switch self {
        case .todo: "To Do"
        case .inProgress: "In Progress"
        case .done: "Done"
        case .deferred: "Deferred"
        }
    }

    /// Whether this status represents an incomplete task (eligible for rollover).
    nonisolated var isIncomplete: Bool {
        switch self {
        case .todo, .inProgress: true
        case .done, .deferred: false
        }
    }

    /// Whether this status counts toward the 1-3-5 bucket limit.
    /// Only active (non-done, non-deferred) tasks count against limits.
    nonisolated var countsTowardBucketLimit: Bool {
        switch self {
        case .todo, .inProgress: true
        case .done, .deferred: false
        }
    }
}
