import Foundation
import SwiftData

/// Errors thrown by `TaskService` when operations violate business rules.
enum TaskServiceError: LocalizedError, Equatable {
    /// The target bucket in the target region is already at capacity.
    case bucketFull(bucket: TaskBucket, region: Region)
    /// The task with the given identifier was not found.
    case taskNotFound(UUID)
    /// The task title is empty or whitespace-only.
    case emptyTitle
    /// A generic invalid operation with a description.
    case invalidOperation(String)

    var errorDescription: String? {
        switch self {
        // swiftlint:disable:next pattern_matching_keywords
        case .bucketFull(let bucket, let region):
            "\(region.displayName) already has the maximum \(bucket.maxCount) \(bucket.displayName) task(s)"
        case .taskNotFound(let identifier):
            "Task not found: \(identifier)"
        case .emptyTitle:
            "Task title cannot be empty"
        case .invalidOperation(let message):
            message
        }
    }
}

/// The service layer for all task-related operations.
///
/// `TaskService` owns all CRUD operations and business rule enforcement,
/// including the 1-3-5 constraint validation. Views and ViewModels should
/// never interact with SwiftData directly — all mutations go through this service.
///
/// Thread safety: `TaskService` operates on a `ModelContext`. SwiftData `ModelContext`
/// is not `Sendable`, so callers must ensure they use this service from the appropriate
/// actor (typically `@MainActor`).
@MainActor
final class TaskService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Creates a new task after validating the title and 1-3-5 constraints.
    ///
    /// - Parameter task: The task to insert. Must have a non-empty title.
    /// - Throws: `TaskServiceError.emptyTitle` if the title is blank.
    /// - Throws: `TaskServiceError.bucketFull` if the target region+bucket is at capacity.
    func createTask(_ task: CharstackTask) throws {
        try validateTitle(task.title)
        try validateBucketCapacity(
            region: task.region,
            bucket: task.bucket,
            plannedDate: task.plannedDate,
            excludingTaskIdentifier: nil
        )
        modelContext.insert(task)
        try modelContext.save()
    }

    // MARK: - Read

    /// Fetches all tasks planned for a given date, optionally filtered by region.
    ///
    /// - Parameters:
    ///   - date: The date to query (compared at day granularity).
    ///   - region: If provided, only tasks in this region are returned.
    /// - Returns: Tasks sorted by bucket (must first), then sort order.
    func fetchTasks(for date: Date, in region: Region? = nil) throws -> [CharstackTask] {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        var descriptor = FetchDescriptor<CharstackTask>()

        if let region {
            let regionRaw = region.rawValue
            descriptor.predicate = #Predicate<CharstackTask> { task in
                task.plannedDate >= startOfDay
                    && task.plannedDate <= endOfDay
                    && task.regionRawValue == regionRaw
            }
        } else {
            descriptor.predicate = #Predicate<CharstackTask> { task in
                task.plannedDate >= startOfDay
                    && task.plannedDate <= endOfDay
            }
        }

        descriptor.sortBy = [
            SortDescriptor(\.bucketRawValue, order: .forward),
            SortDescriptor(\.sortOrder, order: .forward),
            SortDescriptor(\.createdAt, order: .forward),
        ]

        return try modelContext.fetch(descriptor)
    }

    /// Fetches all backlog tasks (any date, region == backlog).
    ///
    /// - Returns: Backlog tasks sorted by creation date (newest first).
    func fetchBacklogTasks() throws -> [CharstackTask] {
        let backlogRaw = Region.backlog.rawValue
        var descriptor = FetchDescriptor<CharstackTask>(
            predicate: #Predicate<CharstackTask> { task in
                task.regionRawValue == backlogRaw
            }
        )
        descriptor.sortBy = [
            SortDescriptor(\.createdAt, order: .reverse)
        ]
        return try modelContext.fetch(descriptor)
    }

    /// Fetches backlog tasks grouped by date category ("Today", "Yesterday", "This Week", "Older").
    ///
    /// Groups are determined by each task's `plannedDate` relative to the current date.
    /// Groups are sorted chronologically (today first), tasks within each group by creation date (newest first).
    ///
    /// - Returns: An ordered array of (group, tasks) pairs. Only non-empty groups are included.
    func fetchGroupedBacklogTasks() throws -> [(group: BacklogDateGroup, tasks: [CharstackTask])] {
        let allBacklogTasks = try fetchBacklogTasks()

        var grouped: [BacklogDateGroup: [CharstackTask]] = [:]
        for task in allBacklogTasks {
            let group = BacklogDateGroup.group(for: task.plannedDate)
            grouped[group, default: []].append(task)
        }

        return grouped.sorted { $0.key < $1.key }.map { (group: $0.key, tasks: $0.value) }
    }

    /// Fetches a single task by its identifier.
    ///
    /// - Parameter identifier: The UUID of the task.
    /// - Returns: The task, or `nil` if not found.
    func fetchTask(byIdentifier identifier: UUID) throws -> CharstackTask? {
        var descriptor = FetchDescriptor<CharstackTask>(
            predicate: #Predicate<CharstackTask> { task in
                task.identifier == identifier
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Update

    /// Updates a task's title and notes.
    ///
    /// - Parameters:
    ///   - identifier: The UUID of the task to update.
    ///   - title: The new title (must be non-empty).
    ///   - notes: The new notes (optional).
    /// - Throws: `TaskServiceError.taskNotFound` if the task doesn't exist.
    /// - Throws: `TaskServiceError.emptyTitle` if the title is blank.
    func updateTaskContent(
        identifier: UUID,
        title: String,
        notes: String?
    ) throws {
        let task = try requireTask(byIdentifier: identifier)
        try validateTitle(title)
        task.title = title
        task.notes = notes
        task.updatedAt = Date()
        try modelContext.save()
    }

    /// Moves a task to a different region and bucket.
    ///
    /// - Parameters:
    ///   - identifier: The UUID of the task to move.
    ///   - targetRegion: The destination region.
    ///   - targetBucket: The destination bucket.
    /// - Throws: `TaskServiceError.bucketFull` if the destination is at capacity.
    func moveTask(
        identifier: UUID,
        toRegion targetRegion: Region,
        bucket targetBucket: TaskBucket
    ) throws {
        let task = try requireTask(byIdentifier: identifier)
        try validateBucketCapacity(
            region: targetRegion,
            bucket: targetBucket,
            plannedDate: task.plannedDate,
            excludingTaskIdentifier: task.identifier
        )
        task.assignToRegion(targetRegion, bucket: targetBucket)
        try modelContext.save()
    }

    /// Toggles a task's completion status.
    ///
    /// If the task is incomplete, it is marked as done. If already done, it is reverted to todo.
    ///
    /// - Parameter identifier: The UUID of the task.
    func toggleTaskCompletion(identifier: UUID) throws {
        let task = try requireTask(byIdentifier: identifier)
        if task.status == .done {
            task.markIncomplete()
        } else {
            task.markCompleted()
        }
        try modelContext.save()
    }

    /// Updates the sort order of a task within its region+bucket.
    ///
    /// - Parameters:
    ///   - identifier: The UUID of the task.
    ///   - newSortOrder: The new sort order value.
    func updateTaskSortOrder(identifier: UUID, newSortOrder: Int) throws {
        let task = try requireTask(byIdentifier: identifier)
        task.sortOrder = newSortOrder
        task.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Delete

    /// Permanently deletes a task.
    ///
    /// - Parameter identifier: The UUID of the task to delete.
    /// - Throws: `TaskServiceError.taskNotFound` if the task doesn't exist.
    func deleteTask(identifier: UUID) throws {
        let task = try requireTask(byIdentifier: identifier)
        modelContext.delete(task)
        try modelContext.save()
    }

    // MARK: - Constraint Queries

    /// Counts active (non-done, non-deferred) tasks in a specific region+bucket on a given day.
    ///
    /// - Parameters:
    ///   - region: The region to count in.
    ///   - bucket: The bucket to count in.
    ///   - date: The date to query.
    ///   - excludingTaskIdentifier: Optionally exclude a task (for move operations).
    /// - Returns: The count of active tasks.
    func countActiveTasks(
        in region: Region,
        bucket: TaskBucket,
        on date: Date,
        excludingTaskIdentifier: UUID? = nil
    ) throws -> Int {
        let tasks = try fetchTasks(for: date, in: region)
        return tasks.filter { task in
            task.bucket == bucket
                && task.status.countsTowardBucketLimit
                && task.identifier != excludingTaskIdentifier
        }.count
    }

    /// Returns the remaining capacity in a region+bucket for a given day.
    ///
    /// - Parameters:
    ///   - region: The region to check.
    ///   - bucket: The bucket to check.
    ///   - date: The date to query.
    /// - Returns: The number of additional tasks that can be added, or `Int.max` for unconstrained buckets.
    func remainingCapacity(
        in region: Region,
        bucket: TaskBucket,
        on date: Date
    ) throws -> Int {
        guard region.isConstrained, bucket != .unassigned else { return Int.max }
        let currentCount = try countActiveTasks(in: region, bucket: bucket, on: date)
        return max(0, bucket.maxCount - currentCount)
    }

    // MARK: - Day Rollover

    /// Performs day rollover: moves all incomplete tasks from active regions to backlog.
    ///
    /// This should be called on app launch and at day boundary transitions.
    /// Only tasks planned for dates before today are affected.
    /// Completed tasks are preserved in place (history).
    ///
    /// This operation is idempotent — calling it multiple times produces the same result.
    ///
    /// - Returns: The number of tasks moved to backlog.
    @discardableResult
    func performDayRollover() throws -> Int {
        let today = Date().startOfDay
        let todoRaw = TaskStatus.todo.rawValue
        let inProgressRaw = TaskStatus.inProgress.rawValue

        var descriptor = FetchDescriptor<CharstackTask>(
            predicate: #Predicate<CharstackTask> { task in
                task.plannedDate < today
                    && (task.statusRawValue == todoRaw || task.statusRawValue == inProgressRaw)
                    && (task.regionRawValue == "morning"
                        || task.regionRawValue == "afternoon"
                        || task.regionRawValue == "evening")
            }
        )
        descriptor.sortBy = [SortDescriptor(\.createdAt)]

        let overdueTasks = try modelContext.fetch(descriptor)

        for task in overdueTasks {
            task.deferToBacklog()
        }

        if !overdueTasks.isEmpty {
            try modelContext.save()
        }

        return overdueTasks.count
    }

    // MARK: - Private Helpers

    /// Fetches a task or throws `.taskNotFound`.
    private func requireTask(byIdentifier identifier: UUID) throws -> CharstackTask {
        guard let task = try fetchTask(byIdentifier: identifier) else {
            throw TaskServiceError.taskNotFound(identifier)
        }
        return task
    }

    /// Validates that a title is non-empty after trimming whitespace.
    private func validateTitle(_ title: String) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TaskServiceError.emptyTitle
        }
    }

    /// Validates that adding a task to the given region+bucket won't exceed the 1-3-5 limit.
    private func validateBucketCapacity(
        region: Region,
        bucket: TaskBucket,
        plannedDate: Date,
        excludingTaskIdentifier: UUID?
    ) throws {
        guard region.isConstrained, bucket != .unassigned else { return }

        let currentCount = try countActiveTasks(
            in: region,
            bucket: bucket,
            on: plannedDate,
            excludingTaskIdentifier: excludingTaskIdentifier
        )

        if currentCount >= bucket.maxCount {
            throw TaskServiceError.bucketFull(bucket: bucket, region: region)
        }
    }
}
