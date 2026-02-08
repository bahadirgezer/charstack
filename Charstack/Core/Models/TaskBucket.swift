import Foundation

/// The priority bucket a task belongs to within a region.
///
/// The 1-3-5 rule is enforced per active region:
/// - **must**: 1 critical task — the single outcome that matters most.
/// - **complementary**: Up to 3 supporting tasks.
/// - **misc**: Up to 5 small, low-friction tasks.
/// - **unassigned**: Unassigned bucket, used for Backlog tasks.
enum TaskBucket: String, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case must
    case complementary
    case misc
    case unassigned = "none"

    nonisolated var id: String { rawValue }

    /// Human-readable name for display in UI.
    nonisolated var displayName: String {
        switch self {
        case .must: "Must Do"
        case .complementary: "Complementary"
        case .misc: "Misc"
        case .unassigned: "Unassigned"
        }
    }

    /// Short label for compact UI (e.g., region card badges).
    nonisolated var shortLabel: String {
        switch self {
        case .must: "Must"
        case .complementary: "Comp"
        case .misc: "Misc"
        case .unassigned: "—"
        }
    }

    /// Maximum number of tasks allowed in this bucket per region.
    /// Returns `Int.max` for `.unassigned` (Backlog tasks are unconstrained).
    nonisolated var maxCount: Int {
        switch self {
        case .must: 1
        case .complementary: 3
        case .misc: 5
        case .unassigned: Int.max
        }
    }

    /// Sort order for display (Must first, None last).
    nonisolated var sortOrder: Int {
        switch self {
        case .must: 0
        case .complementary: 1
        case .misc: 2
        case .unassigned: 3
        }
    }

    /// The three constrained bucket types (excludes `.unassigned`).
    nonisolated static var constrainedBuckets: [Self] {
        [.must, .complementary, .misc]
    }

    /// Total maximum tasks per region under the 1-3-5 rule (1 + 3 + 5 = 9).
    nonisolated static var totalMaxPerRegion: Int {
        Self.constrainedBuckets.reduce(0) { $0 + $1.maxCount }
    }

    nonisolated static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
