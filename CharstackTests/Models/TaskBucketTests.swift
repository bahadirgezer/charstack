import Testing
@testable import Charstack

@Suite("TaskBucket Enum Tests")
struct TaskBucketTests {

    @Test("All cases are present")
    func allCasesExist() {
        #expect(TaskBucket.allCases.count == 4)
        #expect(TaskBucket.allCases.contains(.must))
        #expect(TaskBucket.allCases.contains(.complementary))
        #expect(TaskBucket.allCases.contains(.misc))
        #expect(TaskBucket.allCases.contains(.unassigned))
    }

    @Test("Max counts enforce 1-3-5 rule")
    func maxCounts() {
        #expect(TaskBucket.must.maxCount == 1)
        #expect(TaskBucket.complementary.maxCount == 3)
        #expect(TaskBucket.misc.maxCount == 5)
        #expect(TaskBucket.unassigned.maxCount == Int.max)
    }

    @Test("Sort order is Must < Complementary < Misc < None")
    func sortOrder() {
        #expect(TaskBucket.must < TaskBucket.complementary)
        #expect(TaskBucket.complementary < TaskBucket.misc)
        #expect(TaskBucket.misc < TaskBucket.unassigned)
    }

    @Test("Constrained buckets excludes unassigned")
    func constrainedBuckets() {
        let constrained = TaskBucket.constrainedBuckets
        #expect(constrained.count == 3)
        #expect(constrained.contains(.must))
        #expect(constrained.contains(.complementary))
        #expect(constrained.contains(.misc))
        #expect(!constrained.contains(.unassigned))
    }

    @Test("Total max per region is 9 (1+3+5)")
    func totalMaxPerRegion() {
        #expect(TaskBucket.totalMaxPerRegion == 9)
    }

    @Test("Display names are human-readable")
    func displayNames() {
        #expect(TaskBucket.must.displayName == "Must Do")
        #expect(TaskBucket.complementary.displayName == "Complementary")
        #expect(TaskBucket.misc.displayName == "Misc")
        #expect(TaskBucket.unassigned.displayName == "Unassigned")
    }

    @Test("Raw values encode correctly for Codable/SwiftData")
    func rawValues() {
        #expect(TaskBucket.must.rawValue == "must")
        #expect(TaskBucket.complementary.rawValue == "complementary")
        #expect(TaskBucket.misc.rawValue == "misc")
        #expect(TaskBucket.unassigned.rawValue == "none")
    }
}
