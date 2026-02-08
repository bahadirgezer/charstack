import Foundation
import SwiftData
import Testing
@testable import Charstack

@Suite("CharstackTask Model Tests")
struct CharstackTaskTests {

    @Test("Default initialization sets expected values")
    func defaultInitialization() {
        let task = CharstackTask(title: "Test Task")

        #expect(task.title == "Test Task")
        #expect(task.notes == nil)
        #expect(task.region == .backlog)
        #expect(task.bucket == .none)
        #expect(task.status == .todo)
        #expect(task.sortOrder == 0)
        #expect(task.completedAt == nil)
    }

    @Test("Custom initialization sets all properties")
    func customInitialization() {
        let identifier = UUID()
        let now = Date()

        let task = CharstackTask(
            identifier: identifier,
            title: "Custom Task",
            notes: "Some notes",
            region: .morning,
            bucket: .must,
            status: .inProgress,
            plannedDate: now,
            sortOrder: 5,
            createdAt: now,
            updatedAt: now
        )

        #expect(task.identifier == identifier)
        #expect(task.title == "Custom Task")
        #expect(task.notes == "Some notes")
        #expect(task.region == .morning)
        #expect(task.bucket == .must)
        #expect(task.status == .inProgress)
        #expect(task.sortOrder == 5)
    }

    @Test("Region accessor reads and writes raw value correctly")
    func regionAccessor() {
        let task = CharstackTask(title: "Test", region: .morning)
        #expect(task.regionRawValue == "morning")

        task.region = .evening
        #expect(task.regionRawValue == "evening")
        #expect(task.region == .evening)
    }

    @Test("Bucket accessor reads and writes raw value correctly")
    func bucketAccessor() {
        let task = CharstackTask(title: "Test", bucket: .must)
        #expect(task.bucketRawValue == "must")

        task.bucket = .complementary
        #expect(task.bucketRawValue == "complementary")
        #expect(task.bucket == .complementary)
    }

    @Test("Status accessor reads and writes raw value correctly")
    func statusAccessor() {
        let task = CharstackTask(title: "Test", status: .todo)
        #expect(task.statusRawValue == "todo")

        task.status = .done
        #expect(task.statusRawValue == "done")
        #expect(task.status == .done)
    }

    @Test("markCompleted sets status to done and records timestamp")
    func markCompleted() {
        let task = CharstackTask(title: "Test")
        #expect(task.status == .todo)
        #expect(task.completedAt == nil)

        task.markCompleted()

        #expect(task.status == .done)
        #expect(task.completedAt != nil)
    }

    @Test("markIncomplete resets status to todo and clears completion timestamp")
    func markIncomplete() {
        let task = CharstackTask(title: "Test")
        task.markCompleted()
        #expect(task.status == .done)

        task.markIncomplete()

        #expect(task.status == .todo)
        #expect(task.completedAt == nil)
    }

    @Test("deferToBacklog sets region, bucket, and status correctly")
    func deferToBacklog() {
        let task = CharstackTask(title: "Test", region: .morning, bucket: .must)

        task.deferToBacklog()

        #expect(task.region == .backlog)
        #expect(task.bucket == .none)
        #expect(task.status == .deferred)
    }

    @Test("assignToRegion sets region and bucket, reverts deferred status to todo")
    func assignToRegion() {
        let task = CharstackTask(title: "Test")
        task.deferToBacklog()
        #expect(task.status == .deferred)

        task.assignToRegion(.afternoon, bucket: .complementary)

        #expect(task.region == .afternoon)
        #expect(task.bucket == .complementary)
        #expect(task.status == .todo)
    }

    @Test("assignToRegion preserves non-deferred status")
    func assignToRegionPreservesStatus() {
        let task = CharstackTask(title: "Test", status: .inProgress)

        task.assignToRegion(.evening, bucket: .misc)

        #expect(task.status == .inProgress)
    }

    @Test("isOverdue returns true for past incomplete tasks")
    func isOverdueForPastIncompleteTask() {
        let yesterday = Date().addingDays(-1)
        let task = CharstackTask(title: "Test", status: .todo, plannedDate: yesterday)

        #expect(task.isOverdue)
    }

    @Test("isOverdue returns false for today's tasks")
    func isOverdueForTodayTask() {
        let task = CharstackTask(title: "Test", status: .todo, plannedDate: Date())

        #expect(!task.isOverdue)
    }

    @Test("isOverdue returns false for completed tasks")
    func isOverdueForCompletedTask() {
        let yesterday = Date().addingDays(-1)
        let task = CharstackTask(title: "Test", status: .done, plannedDate: yesterday)

        #expect(!task.isOverdue)
    }

    @Test("Invalid raw values fall back to defaults")
    func invalidRawValueFallbacks() {
        let task = CharstackTask(title: "Test")
        task.regionRawValue = "invalid_region"
        task.bucketRawValue = "invalid_bucket"
        task.statusRawValue = "invalid_status"

        #expect(task.region == .backlog)
        #expect(task.bucket == .none)
        #expect(task.status == .todo)
    }
}
