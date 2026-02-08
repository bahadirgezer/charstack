import Foundation
import SwiftData

/// The primary data model representing a single task in Charstack.
///
/// CloudKit-safe design:
/// - No `@Attribute(.unique)` — CloudKit sync requires no unique constraints.
/// - All properties have default values or are optional.
/// - All relationships are optional (none currently, but future-proofed).
///
/// Tasks belong to a `Region` (Morning/Afternoon/Evening/Backlog) and a `TaskBucket`
/// (must/complementary/misc/unassigned). The 1-3-5 rule is enforced at the service layer,
/// not at the model level.
@Model
final class CharstackTask {
    // MARK: - Identity

    /// Unique identifier. No `@Attribute(.unique)` for CloudKit compatibility.
    var identifier = UUID()

    // MARK: - Content

    /// Task title (required, non-empty).
    var title: String = ""

    /// Extended notes and details (optional).
    var notes: String?

    // MARK: - Classification

    /// Which region this task belongs to.
    var regionRawValue: String = Region.backlog.rawValue

    /// Which priority bucket within the region.
    var bucketRawValue: String = TaskBucket.unassigned.rawValue

    /// Current lifecycle status.
    var statusRawValue: String = TaskStatus.todo.rawValue

    // MARK: - Scheduling

    /// The date this task is planned for. Defaults to today.
    var plannedDate = Date()

    /// Display order within its region+bucket group (lower = higher in list).
    var sortOrder: Int = 0

    // MARK: - Timestamps

    /// When this task was originally created.
    var createdAt = Date()

    /// When this task was last modified.
    var updatedAt = Date()

    /// When this task was completed (nil if not yet done).
    var completedAt: Date?

    // MARK: - Computed Properties (Transient)

    /// Typed accessor for the task's region.
    var region: Region {
        get { Region(rawValue: regionRawValue) ?? .backlog }
        set { regionRawValue = newValue.rawValue }
    }

    /// Typed accessor for the task's bucket.
    var bucket: TaskBucket {
        get { TaskBucket(rawValue: bucketRawValue) ?? .unassigned }
        set { bucketRawValue = newValue.rawValue }
    }

    /// Typed accessor for the task's status.
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRawValue) ?? .todo }
        set { statusRawValue = newValue.rawValue }
    }

    /// Whether the task is overdue (planned for a past day and not done).
    var isOverdue: Bool {
        guard status.isIncomplete else { return false }
        return plannedDate.startOfDay < Date().startOfDay
    }

    // MARK: - Initialization

    init(
        identifier: UUID = UUID(),
        title: String,
        notes: String? = nil,
        region: Region = .backlog,
        bucket: TaskBucket = .unassigned,
        status: TaskStatus = .todo,
        plannedDate: Date = Date(),
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.notes = notes
        self.regionRawValue = region.rawValue
        self.bucketRawValue = bucket.rawValue
        self.statusRawValue = status.rawValue
        self.plannedDate = plannedDate
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }
}

// MARK: - Convenience Methods

extension CharstackTask {
    /// Marks the task as done and records the completion timestamp.
    func markCompleted() {
        status = .done
        completedAt = Date()
        updatedAt = Date()
    }

    /// Resets the task back to todo status and clears completion timestamp.
    func markIncomplete() {
        status = .todo
        completedAt = nil
        updatedAt = Date()
    }

    /// Moves the task to the backlog with deferred status and no bucket.
    func deferToBacklog() {
        region = .backlog
        bucket = .unassigned
        status = .deferred
        updatedAt = Date()
    }

    /// Assigns the task to a specific region and bucket.
    func assignToRegion(_ targetRegion: Region, bucket targetBucket: TaskBucket) {
        region = targetRegion
        bucket = targetBucket
        if status == .deferred {
            status = .todo
        }
        updatedAt = Date()
    }
}
