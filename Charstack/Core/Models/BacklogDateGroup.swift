import Foundation

/// Groups backlog tasks by relative date for display in BacklogView.
///
/// Tasks are categorized as "Today", "Yesterday", "This Week", or "Older"
/// based on their `plannedDate` relative to the current date.
enum BacklogDateGroup: Identifiable, CaseIterable, Comparable {
    case today
    case yesterday
    case thisWeek
    case older

    var id: String { displayName }

    /// Human-readable group label for section headers.
    var displayName: String {
        switch self {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .thisWeek: "This Week"
        case .older: "Older"
        }
    }

    /// SF Symbol name for the group header.
    var systemImageName: String {
        switch self {
        case .today: "clock"
        case .yesterday: "clock.arrow.circlepath"
        case .thisWeek: "calendar"
        case .older: "archivebox"
        }
    }

    /// Sort order for display (today first, older last).
    private var sortOrder: Int {
        switch self {
        case .today: 0
        case .yesterday: 1
        case .thisWeek: 2
        case .older: 3
        }
    }

    static func < (lhs: BacklogDateGroup, rhs: BacklogDateGroup) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    /// Determines which group a given date belongs to, relative to today.
    static func group(for date: Date) -> BacklogDateGroup {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return .today
        } else if calendar.isDateInYesterday(date) {
            return .yesterday
        } else if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
                  date >= startOfWeek {
            return .thisWeek
        } else {
            return .older
        }
    }
}
