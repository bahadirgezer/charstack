import Testing
@testable import Charstack

@Suite("TaskStatus Enum Tests")
struct TaskStatusTests {

    @Test("All cases are present")
    func allCasesExist() {
        #expect(TaskStatus.allCases.count == 4)
        #expect(TaskStatus.allCases.contains(.todo))
        #expect(TaskStatus.allCases.contains(.inProgress))
        #expect(TaskStatus.allCases.contains(.done))
        #expect(TaskStatus.allCases.contains(.deferred))
    }

    @Test("isIncomplete returns true for todo and inProgress")
    func isIncomplete() {
        #expect(TaskStatus.todo.isIncomplete)
        #expect(TaskStatus.inProgress.isIncomplete)
        #expect(!TaskStatus.done.isIncomplete)
        #expect(!TaskStatus.deferred.isIncomplete)
    }

    @Test("countsTowardBucketLimit returns true for active statuses")
    func countsTowardBucketLimit() {
        #expect(TaskStatus.todo.countsTowardBucketLimit)
        #expect(TaskStatus.inProgress.countsTowardBucketLimit)
        #expect(!TaskStatus.done.countsTowardBucketLimit)
        #expect(!TaskStatus.deferred.countsTowardBucketLimit)
    }

    @Test("Display names are human-readable")
    func displayNames() {
        #expect(TaskStatus.todo.displayName == "To Do")
        #expect(TaskStatus.inProgress.displayName == "In Progress")
        #expect(TaskStatus.done.displayName == "Done")
        #expect(TaskStatus.deferred.displayName == "Deferred")
    }

    @Test("Raw values encode correctly for Codable/SwiftData")
    func rawValues() {
        #expect(TaskStatus.todo.rawValue == "todo")
        #expect(TaskStatus.inProgress.rawValue == "inProgress")
        #expect(TaskStatus.done.rawValue == "done")
        #expect(TaskStatus.deferred.rawValue == "deferred")
    }
}
