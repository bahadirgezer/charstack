import Foundation

extension Date {
    /// The start of the day (midnight 00:00:00) for this date in the current calendar.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// The end of the day (23:59:59) for this date in the current calendar.
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Whether this date falls on the same calendar day as the given date.
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Returns a new date offset by the given number of days.
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Whether this date is before the start of today (i.e., in a past day).
    var isBeforeToday: Bool {
        self < Date().startOfDay
    }
}
