import Foundation
import Observation
import SwiftData

/// ViewModel managing the Today dashboard state.
///
/// Fetches today's tasks for active regions (Morning, Afternoon, Evening)
/// and provides region-level summaries for the RegionCard components.
/// Backlog is managed by its own tab and BacklogViewModel.
/// All data flows through TaskService.
@Observable
@MainActor
final class TodayViewModel {

    // MARK: - State

    /// Tasks for today, grouped by region.
    var tasksByRegion: [Region: [CharstackTask]] = [:]

    /// Whether the initial data load is in progress.
    var isLoading = false

    /// The most recent error, if any. Cleared on next successful load.
    var errorMessage: String?

    /// Number of tasks rolled over from previous days (shown after rollover).
    var rolledOverCount: Int?

    // MARK: - Dependencies

    private let taskService: TaskService

    init(taskService: TaskService) {
        self.taskService = taskService
    }

    // MARK: - Data Loading

    /// Loads today's tasks from the service layer and groups them by active region.
    ///
    /// Only fetches for active regions (Morning, Afternoon, Evening).
    /// Backlog is managed separately by BacklogViewModel.
    func loadTodaysTasks() {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let today = Date()
            var grouped: [Region: [CharstackTask]] = [:]

            for region in Region.activeRegions {
                grouped[region] = try taskService.fetchTasks(for: today, in: region)
            }

            tasksByRegion = grouped
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Performs day rollover (moves overdue tasks to backlog) then reloads.
    func performDayRollover() {
        do {
            let count = try taskService.performDayRollover()
            rolledOverCount = count > 0 ? count : nil
            loadTodaysTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Toggles a task's completion status and reloads.
    func toggleTaskCompletion(identifier: UUID) {
        do {
            try taskService.toggleTaskCompletion(identifier: identifier)
            loadTodaysTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes a task and reloads.
    func deleteTask(identifier: UUID) {
        do {
            try taskService.deleteTask(identifier: identifier)
            loadTodaysTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Computed Properties

    /// Tasks for a specific region (empty array if none).
    func tasks(for region: Region) -> [CharstackTask] {
        tasksByRegion[region] ?? []
    }

    /// Total tasks across all active regions (excludes backlog).
    var totalActiveTaskCount: Int {
        Region.activeRegions.reduce(0) { $0 + tasks(for: $1).count }
    }

    /// Total completed tasks across all active regions.
    var completedActiveTaskCount: Int {
        Region.activeRegions.reduce(0) { sum, region in
            sum + tasks(for: region).filter { $0.status == .done }.count
        }
    }

    /// Overall daily completion fraction (0.0...1.0).
    var dailyCompletionFraction: Double {
        guard totalActiveTaskCount > 0 else { return 0 }
        return Double(completedActiveTaskCount) / Double(totalActiveTaskCount)
    }

    /// Clears the rolled-over count banner.
    func dismissRolloverBanner() {
        rolledOverCount = nil
    }
}
