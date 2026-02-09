import Foundation
import Testing
@testable import Charstack

@Suite("BacklogDateGroup Tests")
struct BacklogDateGroupTests {

    @Test("Today's date maps to .today group")
    func todayDateMapsToTodayGroup() {
        let group = BacklogDateGroup.group(for: Date())
        #expect(group == .today)
    }

    @Test("Yesterday's date maps to .yesterday group")
    func yesterdayDateMapsToYesterdayGroup() {
        let yesterday = Date().addingDays(-1)
        let group = BacklogDateGroup.group(for: yesterday)
        #expect(group == .yesterday)
    }

    @Test("Date from earlier this week maps to .thisWeek group")
    func earlierThisWeekMapsToThisWeekGroup() {
        // Find a date that's earlier this week but not yesterday or today
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            Issue.record("Could not determine week start")
            return
        }

        // If today is close to the start of the week, this test might not have
        // a valid "this week but not yesterday" date. Skip gracefully.
        let daysSinceWeekStart = calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0
        guard daysSinceWeekStart >= 3 else {
            // Not enough days into the week to test this case distinctly
            return
        }

        let threeDaysAgo = today.addingDays(-3)
        let group = BacklogDateGroup.group(for: threeDaysAgo)
        #expect(group == .thisWeek)
    }

    @Test("Date from last week maps to .older group")
    func lastWeekMapsToOlderGroup() {
        let lastWeek = Date().addingDays(-10)
        let group = BacklogDateGroup.group(for: lastWeek)
        #expect(group == .older)
    }

    @Test("Groups are sorted correctly (today < yesterday < thisWeek < older)")
    func groupsSortedCorrectly() {
        let sorted = BacklogDateGroup.allCases.sorted()
        #expect(sorted == [.today, .yesterday, .thisWeek, .older])
    }

    @Test("All groups have non-empty display names")
    func allGroupsHaveDisplayNames() {
        for group in BacklogDateGroup.allCases {
            #expect(!group.displayName.isEmpty)
        }
    }

    @Test("All groups have non-empty system image names")
    func allGroupsHaveSystemImageNames() {
        for group in BacklogDateGroup.allCases {
            #expect(!group.systemImageName.isEmpty)
        }
    }
}
