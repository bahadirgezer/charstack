import Foundation
import Testing
@testable import Charstack

@Suite("Date Extensions Tests")
struct DateExtensionsTests {

    @Test("startOfDay returns midnight of the same day")
    func startOfDay() {
        let now = Date()
        let start = now.startOfDay

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
        #expect(Calendar.current.isDate(start, inSameDayAs: now))
    }

    @Test("endOfDay returns 23:59:59 of the same day")
    func endOfDay() {
        let now = Date()
        let end = now.endOfDay

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: end)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
        #expect(Calendar.current.isDate(end, inSameDayAs: now))
    }

    @Test("isSameDay returns true for dates on the same calendar day")
    func isSameDayTrue() {
        let date1 = Calendar.current.date(
            bySettingHour: 8, minute: 0, second: 0, of: Date()
        )!
        let date2 = Calendar.current.date(
            bySettingHour: 20, minute: 0, second: 0, of: Date()
        )!

        #expect(date1.isSameDay(as: date2))
    }

    @Test("isSameDay returns false for different calendar days")
    func isSameDayFalse() {
        let today = Date()
        let tomorrow = today.addingDays(1)

        #expect(!today.isSameDay(as: tomorrow))
    }

    @Test("addingDays adds positive days correctly")
    func addingPositiveDays() {
        let today = Date().startOfDay
        let threeDaysLater = today.addingDays(3)

        let dayDifference = Calendar.current.dateComponents(
            [.day],
            from: today,
            to: threeDaysLater
        ).day

        #expect(dayDifference == 3)
    }

    @Test("addingDays subtracts negative days correctly")
    func addingNegativeDays() {
        let today = Date().startOfDay
        let twoDaysAgo = today.addingDays(-2)

        let dayDifference = Calendar.current.dateComponents(
            [.day],
            from: twoDaysAgo,
            to: today
        ).day

        #expect(dayDifference == 2)
    }

    @Test("isBeforeToday returns true for yesterday")
    func isBeforeTodayYesterday() {
        let yesterday = Date().addingDays(-1)
        #expect(yesterday.isBeforeToday)
    }

    @Test("isBeforeToday returns false for today")
    func isBeforeTodayToday() {
        let today = Date()
        #expect(!today.isBeforeToday)
    }
}
