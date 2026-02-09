import Foundation
import Observation
import SwiftData

/// ViewModel managing the state for a single region's detailed task list.
///
/// Provides task data grouped by bucket, handles CRUD operations within the region,
/// and enforces 1-3-5 constraints via TaskService.
@Observable
@MainActor
final class RegionFocusViewModel {

    // MARK: - State

    /// The region this view manages.
    let region: Region

    /// All tasks in this region for today, sorted by bucket then sort order.
    var tasks: [CharstackTask] = []

    /// Whether data is currently loading.
    var isLoading = false

    /// The most recent error message, if any.
    var errorMessage: String?

    /// The task currently being edited, if any.
    var taskBeingEdited: CharstackTask?

    /// Whether the edit sheet is presented.
    var isEditSheetPresented = false

    // MARK: - Dependencies

    private let taskService: TaskService

    init(region: Region, taskService: TaskService) {
        self.region = region
        self.taskService = taskService
    }

    // MARK: - Data Loading

    /// Loads tasks for this region and today's date.
    func loadTasks() {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if region == .backlog {
                tasks = try taskService.fetchBacklogTasks()
            } else {
                tasks = try taskService.fetchTasks(for: Date(), in: region)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - CRUD Operations

    /// Creates a new task in this region with the given title and bucket.
    func addTask(title: String, bucket: TaskBucket) {
        do {
            let task = CharstackTask(
                title: title,
                region: region,
                bucket: region.isConstrained ? bucket : .unassigned,
                plannedDate: Date()
            )
            try taskService.createTask(task)
            loadTasks()
        } catch let error as TaskServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Toggles a task's completion status.
    func toggleTaskCompletion(identifier: UUID) {
        do {
            try taskService.toggleTaskCompletion(identifier: identifier)
            loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes a task permanently.
    func deleteTask(identifier: UUID) {
        do {
            try taskService.deleteTask(identifier: identifier)
            loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Updates a task's title and notes.
    func updateTask(identifier: UUID, title: String, notes: String?) {
        do {
            try taskService.updateTaskContent(identifier: identifier, title: title, notes: notes)
            loadTasks()
        } catch let error as TaskServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Moves a task to a different region and bucket.
    func moveTask(identifier: UUID, toRegion targetRegion: Region, bucket: TaskBucket) {
        do {
            try taskService.moveTask(identifier: identifier, toRegion: targetRegion, bucket: bucket)
            loadTasks()
        } catch let error as TaskServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Computed Properties

    /// Tasks filtered by bucket, for section display.
    func tasks(for bucket: TaskBucket) -> [CharstackTask] {
        tasks.filter { $0.bucket == bucket }
    }

    /// Remaining capacity for a given bucket in this region.
    func remainingCapacity(for bucket: TaskBucket) -> Int {
        do {
            return try taskService.remainingCapacity(in: region, bucket: bucket, on: Date())
        } catch {
            return 0
        }
    }

    /// Total task count in this region.
    var totalTaskCount: Int {
        tasks.count
    }

    /// Completed task count in this region.
    var completedTaskCount: Int {
        tasks.filter { $0.status == .done }.count
    }

    /// Opens the edit sheet for a task.
    func beginEditing(_ task: CharstackTask) {
        taskBeingEdited = task
        isEditSheetPresented = true
    }

    /// Clears the error message.
    func dismissError() {
        errorMessage = nil
    }
}
