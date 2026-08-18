import Foundation

public enum IslandifyDateMath {
    public static func calendar(timeZoneIdentifier: String? = nil, locale: Locale? = nil) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZoneIdentifier, let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        if let locale {
            calendar.locale = locale
        }
        return calendar
    }

    public static func startOfDay(_ date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    public static func wholeCalendarDays(from start: Date, to end: Date, calendar: Calendar) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }

    public static func dateByAddingDays(_ days: Int, to date: Date, calendar: Calendar) -> Date? {
        calendar.date(byAdding: .day, value: days, to: date)
    }

    public static func dateByAddingYears(_ years: Int, to date: Date, calendar: Calendar) -> Date? {
        calendar.date(byAdding: .year, value: years, to: date)
    }

    public static func clampedProgress(elapsed: TimeInterval, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        return min(max(elapsed / duration, 0), 1)
    }
}
