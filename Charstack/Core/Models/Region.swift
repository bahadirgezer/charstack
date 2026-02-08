import Foundation

/// Represents a time-of-day section for organizing daily tasks.
///
/// Charstack divides the day into three active regions (Morning, Afternoon, Evening)
/// plus a Backlog for deferred/accumulated tasks. Each active region enforces the 1-3-5 rule.
enum Region: String, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case morning
    case afternoon
    case evening
    case backlog

    nonisolated var id: String { rawValue }

    /// Human-readable name for display in UI.
    nonisolated var displayName: String {
        switch self {
        case .morning: "Morning"
        case .afternoon: "Afternoon"
        case .evening: "Evening"
        case .backlog: "Backlog"
        }
    }

    /// SF Symbol name representing the region.
    nonisolated var systemImageName: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.stars.fill"
        case .backlog: "tray.full.fill"
        }
    }

    /// Sort order for consistent display (Morning first, Backlog last).
    nonisolated var sortOrder: Int {
        switch self {
        case .morning: 0
        case .afternoon: 1
        case .evening: 2
        case .backlog: 3
        }
    }

    /// Whether this region enforces the 1-3-5 constraint.
    /// Backlog is unconstrained by default.
    nonisolated var isConstrained: Bool {
        self != .backlog
    }

    /// The three active (non-backlog) regions, in order.
    nonisolated static var activeRegions: [Self] {
        [.morning, .afternoon, .evening]
    }

    nonisolated static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
