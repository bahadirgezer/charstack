import Foundation
import SwiftData
import Testing
@testable import Charstack

@Suite("TaskService Tests")
@MainActor
struct TaskServiceTests {

    // MARK: - Helpers

    /// Creates an in-memory ModelContainer and returns a TaskService ready for testing.
    private func makeTaskService() throws -> TaskService {
        let container = try ModelContainerSetup.createTestingContainer()
        let modelContext = ModelContext(container)
        return TaskService(modelContext: modelContext)
    }

    /// Helper to create a task with sensible defaults for testing.
    private func makeTask(
        title: String = "Test Task",
        region: Region = .morning,
        bucket: TaskBucket = .misc,
        status: TaskStatus = .todo,
        plannedDate: Date = Date(),
        sortOrder: Int = 0
    ) -> CharstackTask {
        CharstackTask(
            title: title,
            region: region,
            bucket: bucket,
            status: status,
            plannedDate: plannedDate,
            sortOrder: sortOrder
        )
    }

    // MARK: - Create Tests

    @Test("Create task inserts into store and can be fetched back")
    func createAndFetchTask() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Buy groceries", region: .morning, bucket: .must)

        try service.createTask(task)

        let fetched = try service.fetchTasks(for: Date(), in: .morning)
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Buy groceries")
        #expect(fetched.first?.region == .morning)
        #expect(fetched.first?.bucket == .must)
    }

    @Test("Create task with empty title throws emptyTitle error")
    func createTaskWithEmptyTitle() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "   ", region: .morning, bucket: .must)

        #expect(throws: TaskServiceError.emptyTitle) {
            try service.createTask(task)
        }
    }

    @Test("Create task with whitespace-only title throws emptyTitle error")
    func createTaskWithWhitespaceTitle() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "\n\t  ", region: .morning, bucket: .must)

        #expect(throws: TaskServiceError.emptyTitle) {
            try service.createTask(task)
        }
    }

    // MARK: - 1-3-5 Constraint Tests

    @Test("Must bucket allows exactly 1 task per region")
    func mustBucketLimitEnforced() throws {
        let service = try makeTaskService()
        let task1 = makeTask(title: "Must 1", region: .morning, bucket: .must)
        try service.createTask(task1)

        let task2 = makeTask(title: "Must 2", region: .morning, bucket: .must)
        #expect(throws: TaskServiceError.self) {
            try service.createTask(task2)
        }
    }

    @Test("Complementary bucket allows exactly 3 tasks per region")
    func complementaryBucketLimitEnforced() throws {
        let service = try makeTaskService()

        for index in 1...3 {
            let task = makeTask(
                title: "Comp \(index)",
                region: .afternoon,
                bucket: .complementary
            )
            try service.createTask(task)
        }

        let overflowTask = makeTask(
            title: "Comp 4",
            region: .afternoon,
            bucket: .complementary
        )
        #expect(throws: TaskServiceError.self) {
            try service.createTask(overflowTask)
        }
    }

    @Test("Misc bucket allows exactly 5 tasks per region")
    func miscBucketLimitEnforced() throws {
        let service = try makeTaskService()

        for index in 1...5 {
            let task = makeTask(
                title: "Misc \(index)",
                region: .evening,
                bucket: .misc
            )
            try service.createTask(task)
        }

        let overflowTask = makeTask(
            title: "Misc 6",
            region: .evening,
            bucket: .misc
        )
        #expect(throws: TaskServiceError.self) {
            try service.createTask(overflowTask)
        }
    }

    @Test("Backlog has no bucket limit (unconstrained)")
    func backlogIsUnconstrained() throws {
        let service = try makeTaskService()

        for index in 1...20 {
            let task = makeTask(
                title: "Backlog \(index)",
                region: .backlog,
                bucket: .unassigned
            )
            try service.createTask(task)
        }

        let backlogTasks = try service.fetchBacklogTasks()
        #expect(backlogTasks.count == 20)
    }

    @Test("Completed tasks don't count toward bucket limits")
    func completedTasksDoNotCountTowardLimits() throws {
        let service = try makeTaskService()

        let task1 = makeTask(title: "Must Done", region: .morning, bucket: .must)
        try service.createTask(task1)
        try service.toggleTaskCompletion(identifier: task1.identifier)

        let task2 = makeTask(title: "Must New", region: .morning, bucket: .must)
        try service.createTask(task2)

        let morningTasks = try service.fetchTasks(for: Date(), in: .morning)
        #expect(morningTasks.count == 2)
    }

    @Test("Constraint applies per region independently")
    func constraintIsPerRegion() throws {
        let service = try makeTaskService()

        let morningMust = makeTask(title: "Morning Must", region: .morning, bucket: .must)
        try service.createTask(morningMust)

        let afternoonMust = makeTask(title: "Afternoon Must", region: .afternoon, bucket: .must)
        try service.createTask(afternoonMust)

        let eveningMust = makeTask(title: "Evening Must", region: .evening, bucket: .must)
        try service.createTask(eveningMust)

        let morningTasks = try service.fetchTasks(for: Date(), in: .morning)
        let afternoonTasks = try service.fetchTasks(for: Date(), in: .afternoon)
        let eveningTasks = try service.fetchTasks(for: Date(), in: .evening)
        #expect(morningTasks.count == 1)
        #expect(afternoonTasks.count == 1)
        #expect(eveningTasks.count == 1)
    }

    @Test("Constraint applies per day independently")
    func constraintIsPerDay() throws {
        let service = try makeTaskService()
        let today = Date()
        let tomorrow = today.addingDays(1)

        let todayMust = makeTask(
            title: "Today Must",
            region: .morning,
            bucket: .must,
            plannedDate: today
        )
        try service.createTask(todayMust)

        let tomorrowMust = makeTask(
            title: "Tomorrow Must",
            region: .morning,
            bucket: .must,
            plannedDate: tomorrow
        )
        try service.createTask(tomorrowMust)

        let todayTasks = try service.fetchTasks(for: today, in: .morning)
        let tomorrowTasks = try service.fetchTasks(for: tomorrow, in: .morning)
        #expect(todayTasks.count == 1)
        #expect(tomorrowTasks.count == 1)
    }

    // MARK: - Read Tests

    @Test("fetchTasks filters by date correctly")
    func fetchTasksFiltersByDate() throws {
        let service = try makeTaskService()
        let today = Date()
        let yesterday = today.addingDays(-1)

        let todayTask = makeTask(title: "Today", plannedDate: today)
        let yesterdayTask = makeTask(title: "Yesterday", plannedDate: yesterday)
        try service.createTask(todayTask)
        try service.createTask(yesterdayTask)

        let todayResults = try service.fetchTasks(for: today)
        let yesterdayResults = try service.fetchTasks(for: yesterday)
        #expect(todayResults.count == 1)
        #expect(todayResults.first?.title == "Today")
        #expect(yesterdayResults.count == 1)
        #expect(yesterdayResults.first?.title == "Yesterday")
    }

    @Test("fetchTasks filters by region correctly")
    func fetchTasksFiltersByRegion() throws {
        let service = try makeTaskService()

        let morningTask = makeTask(title: "Morning", region: .morning, bucket: .must)
        let eveningTask = makeTask(title: "Evening", region: .evening, bucket: .must)
        try service.createTask(morningTask)
        try service.createTask(eveningTask)

        let morningResults = try service.fetchTasks(for: Date(), in: .morning)
        let eveningResults = try service.fetchTasks(for: Date(), in: .evening)
        #expect(morningResults.count == 1)
        #expect(morningResults.first?.title == "Morning")
        #expect(eveningResults.count == 1)
        #expect(eveningResults.first?.title == "Evening")
    }

    @Test("fetchTask by identifier returns correct task")
    func fetchTaskByIdentifier() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Find Me")
        try service.createTask(task)

        let found = try service.fetchTask(byIdentifier: task.identifier)
        #expect(found?.title == "Find Me")
    }

    @Test("fetchTask by identifier returns nil for nonexistent task")
    func fetchTaskByIdentifierReturnsNilForMissing() throws {
        let service = try makeTaskService()

        let found = try service.fetchTask(byIdentifier: UUID())
        #expect(found == nil)
    }

    @Test("fetchBacklogTasks returns only backlog tasks")
    func fetchBacklogTasks() throws {
        let service = try makeTaskService()

        let backlogTask = makeTask(title: "Backlog", region: .backlog, bucket: .unassigned)
        let morningTask = makeTask(title: "Morning", region: .morning, bucket: .must)
        try service.createTask(backlogTask)
        try service.createTask(morningTask)

        let backlogResults = try service.fetchBacklogTasks()
        #expect(backlogResults.count == 1)
        #expect(backlogResults.first?.title == "Backlog")
    }

    // MARK: - Update Tests

    @Test("updateTaskContent changes title and notes")
    func updateTaskContent() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Original")
        try service.createTask(task)

        try service.updateTaskContent(
            identifier: task.identifier,
            title: "Updated",
            notes: "New notes"
        )

        let fetched = try service.fetchTask(byIdentifier: task.identifier)
        #expect(fetched?.title == "Updated")
        #expect(fetched?.notes == "New notes")
    }

    @Test("updateTaskContent with empty title throws emptyTitle error")
    func updateTaskContentEmptyTitle() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Original")
        try service.createTask(task)

        #expect(throws: TaskServiceError.emptyTitle) {
            try service.updateTaskContent(
                identifier: task.identifier,
                title: "",
                notes: nil
            )
        }
    }

    @Test("updateTaskContent with nonexistent identifier throws taskNotFound")
    func updateTaskContentNotFound() throws {
        let service = try makeTaskService()
        let fakeIdentifier = UUID()

        #expect(throws: TaskServiceError.taskNotFound(fakeIdentifier)) {
            try service.updateTaskContent(
                identifier: fakeIdentifier,
                title: "Doesn't Matter",
                notes: nil
            )
        }
    }

    // MARK: - Move Tests

    @Test("moveTask changes region and bucket")
    func moveTask() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Move Me", region: .morning, bucket: .must)
        try service.createTask(task)

        try service.moveTask(
            identifier: task.identifier,
            toRegion: .afternoon,
            bucket: .complementary
        )

        let fetched = try service.fetchTask(byIdentifier: task.identifier)
        #expect(fetched?.region == .afternoon)
        #expect(fetched?.bucket == .complementary)
    }

    @Test("moveTask enforces 1-3-5 at destination")
    func moveTaskEnforcesConstraintAtDestination() throws {
        let service = try makeTaskService()

        let existingMust = makeTask(title: "Existing", region: .afternoon, bucket: .must)
        try service.createTask(existingMust)

        let taskToMove = makeTask(title: "Incoming", region: .morning, bucket: .misc)
        try service.createTask(taskToMove)

        #expect(throws: TaskServiceError.self) {
            try service.moveTask(
                identifier: taskToMove.identifier,
                toRegion: .afternoon,
                bucket: .must
            )
        }
    }

    @Test("moveTask within same region and bucket does not self-conflict")
    func moveTaskWithinSameRegionBucket() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Stay", region: .morning, bucket: .must)
        try service.createTask(task)

        try service.moveTask(
            identifier: task.identifier,
            toRegion: .morning,
            bucket: .must
        )

        let fetched = try service.fetchTask(byIdentifier: task.identifier)
        #expect(fetched?.region == .morning)
        #expect(fetched?.bucket == .must)
    }

    @Test("moveTask reverts deferred status to todo")
    func moveTaskRevertsDeferredStatus() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Deferred", region: .backlog, bucket: .unassigned, status: .deferred)
        try service.createTask(task)

        try service.moveTask(
            identifier: task.identifier,
            toRegion: .evening,
            bucket: .misc
        )

        let fetched = try service.fetchTask(byIdentifier: task.identifier)
        #expect(fetched?.status == .todo)
    }

    // MARK: - Toggle Completion Tests

    @Test("toggleTaskCompletion marks todo task as done")
    func toggleCompletionMarksDone() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Toggle Me")
        try service.createTask(task)

        try service.toggleTaskCompletion(identifier: task.identifier)

        let fetched = try service.fetchTask(byIdentifier: task.identifier)
        #expect(fetched?.status == .done)
        #expect(fetched?.completedAt != nil)
    }

    @Test("toggleTaskCompletion marks done task as todo")
    func toggleCompletionRevertsToDo() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Toggle Me")
        try service.createTask(task)

        try service.toggleTaskCompletion(identifier: task.identifier)
        try service.toggleTaskCompletion(identifier: task.identifier)

        let fetched = try service.fetchTask(byIdentifier: task.identifier)
        #expect(fetched?.status == .todo)
        #expect(fetched?.completedAt == nil)
    }

    // MARK: - Delete Tests

    @Test("deleteTask removes task from store")
    func deleteTask() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Delete Me")
        try service.createTask(task)

        try service.deleteTask(identifier: task.identifier)

        let fetched = try service.fetchTask(byIdentifier: task.identifier)
        #expect(fetched == nil)
    }

    @Test("deleteTask with nonexistent identifier throws taskNotFound")
    func deleteTaskNotFound() throws {
        let service = try makeTaskService()
        let fakeIdentifier = UUID()

        #expect(throws: TaskServiceError.taskNotFound(fakeIdentifier)) {
            try service.deleteTask(identifier: fakeIdentifier)
        }
    }

    // MARK: - Sort Order Tests

    @Test("updateTaskSortOrder changes sort order")
    func updateTaskSortOrder() throws {
        let service = try makeTaskService()
        let task = makeTask(title: "Reorder Me", sortOrder: 0)
        try service.createTask(task)

        try service.updateTaskSortOrder(identifier: task.identifier, newSortOrder: 10)

        let fetched = try service.fetchTask(byIdentifier: task.identifier)
        #expect(fetched?.sortOrder == 10)
    }

    // MARK: - Remaining Capacity Tests

    @Test("remainingCapacity returns correct values")
    func remainingCapacity() throws {
        let service = try makeTaskService()

        let initialCapacity = try service.remainingCapacity(
            in: .morning,
            bucket: .complementary,
            on: Date()
        )
        #expect(initialCapacity == 3)

        let task = makeTask(title: "Comp 1", region: .morning, bucket: .complementary)
        try service.createTask(task)

        let afterOneCapacity = try service.remainingCapacity(
            in: .morning,
            bucket: .complementary,
            on: Date()
        )
        #expect(afterOneCapacity == 2)
    }

    @Test("remainingCapacity returns Int.max for backlog")
    func remainingCapacityBacklog() throws {
        let service = try makeTaskService()

        let capacity = try service.remainingCapacity(
            in: .backlog,
            bucket: .unassigned,
            on: Date()
        )
        #expect(capacity == Int.max)
    }

    // MARK: - Day Rollover Tests

    @Test("Day rollover moves incomplete past tasks to backlog")
    func dayRolloverMovesIncompleteTasks() throws {
        let service = try makeTaskService()
        let yesterday = Date().addingDays(-1)

        let incompleteMust = makeTask(
            title: "Incomplete Must",
            region: .morning,
            bucket: .must,
            status: .todo,
            plannedDate: yesterday
        )
        let incompleteComp = makeTask(
            title: "Incomplete Comp",
            region: .afternoon,
            bucket: .complementary,
            status: .inProgress,
            plannedDate: yesterday
        )
        try service.createTask(incompleteMust)
        try service.createTask(incompleteComp)

        let movedCount = try service.performDayRollover()

        #expect(movedCount == 2)

        let backlogTasks = try service.fetchBacklogTasks()
        #expect(backlogTasks.count == 2)
        #expect(backlogTasks.allSatisfy { $0.status == .deferred })
        #expect(backlogTasks.allSatisfy { $0.region == .backlog })
        #expect(backlogTasks.allSatisfy { $0.bucket == .unassigned })
    }

    @Test("Day rollover preserves completed tasks in place")
    func dayRolloverPreservesCompletedTasks() throws {
        let service = try makeTaskService()
        let yesterday = Date().addingDays(-1)

        let completedTask = makeTask(
            title: "Done Yesterday",
            region: .morning,
            bucket: .must,
            status: .done,
            plannedDate: yesterday
        )
        try service.createTask(completedTask)

        let movedCount = try service.performDayRollover()

        #expect(movedCount == 0)

        let morningTasks = try service.fetchTasks(for: yesterday, in: .morning)
        #expect(morningTasks.count == 1)
        #expect(morningTasks.first?.status == .done)
    }

    @Test("Day rollover does not affect today's tasks")
    func dayRolloverDoesNotAffectToday() throws {
        let service = try makeTaskService()

        let todayTask = makeTask(
            title: "Today's Task",
            region: .morning,
            bucket: .must,
            status: .todo,
            plannedDate: Date()
        )
        try service.createTask(todayTask)

        let movedCount = try service.performDayRollover()

        #expect(movedCount == 0)

        let morningTasks = try service.fetchTasks(for: Date(), in: .morning)
        #expect(morningTasks.count == 1)
        #expect(morningTasks.first?.region == .morning)
    }

    @Test("Day rollover is idempotent — calling twice yields same result")
    func dayRolloverIsIdempotent() throws {
        let service = try makeTaskService()
        let yesterday = Date().addingDays(-1)

        let task = makeTask(
            title: "Rollover Me",
            region: .evening,
            bucket: .misc,
            status: .todo,
            plannedDate: yesterday
        )
        try service.createTask(task)

        let firstCount = try service.performDayRollover()
        let secondCount = try service.performDayRollover()

        #expect(firstCount == 1)
        #expect(secondCount == 0)

        let backlogTasks = try service.fetchBacklogTasks()
        #expect(backlogTasks.count == 1)
    }

    @Test("Day rollover does not move backlog tasks")
    func dayRolloverDoesNotMoveBacklogTasks() throws {
        let service = try makeTaskService()
        let yesterday = Date().addingDays(-1)

        let backlogTask = makeTask(
            title: "Already in Backlog",
            region: .backlog,
            bucket: .unassigned,
            status: .todo,
            plannedDate: yesterday
        )
        try service.createTask(backlogTask)

        let movedCount = try service.performDayRollover()

        #expect(movedCount == 0)
    }
}
