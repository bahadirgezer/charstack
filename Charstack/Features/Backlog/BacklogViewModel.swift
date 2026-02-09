import Foundation
import Observation
import SwiftData

/// ViewModel managing the Backlog tab's state.
///
/// Fetches backlog tasks grouped by date category ("Today", "Yesterday",
/// "This Week", "Older") via TaskService's grouped query. Supports
/// move-to-region, delete, and completion toggle operations.
@Observable
@MainActor
final class BacklogViewModel {

    // MARK: - State

    /// Backlog tasks grouped by date category, ordered chronologically.
    var groupedTasks: [(group: BacklogDateGroup, tasks: [CharstackTask])] = []

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

    init(taskService: TaskService) {
        self.taskService = taskService
    }

    // MARK: - Data Loading

    /// Loads backlog tasks grouped by date category.
    func loadBacklogTasks() {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            groupedTasks = try taskService.fetchGroupedBacklogTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Actions

    /// Moves a backlog task to a target region and bucket.
    func moveTask(identifier: UUID, toRegion targetRegion: Region, bucket: TaskBucket) {
        do {
            try taskService.moveTask(identifier: identifier, toRegion: targetRegion, bucket: bucket)
            loadBacklogTasks()
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
            loadBacklogTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes a task permanently.
    func deleteTask(identifier: UUID) {
        do {
            try taskService.deleteTask(identifier: identifier)
            loadBacklogTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Updates a task's title and notes.
    func updateTask(identifier: UUID, title: String, notes: String?) {
        do {
            try taskService.updateTaskContent(identifier: identifier, title: title, notes: notes)
            loadBacklogTasks()
        } catch let error as TaskServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Computed Properties

    /// Total number of backlog tasks across all groups.
    var totalTaskCount: Int {
        groupedTasks.reduce(0) { $0 + $1.tasks.count }
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
