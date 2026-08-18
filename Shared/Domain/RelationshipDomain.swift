import Foundation

public enum RelationshipCountingMode: String, Codable, CaseIterable, Hashable, Sendable {
    case dPlus0
    case dPlus1
}

public enum RelationshipMilestoneKind: String, Codable, CaseIterable, Hashable, Sendable {
    case dayCount
    case annual
}

public struct RelationshipConfiguration: Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var startDate: Date
    public var timeZoneIdentifier: String
    public var nickname: String
    public var icon: ActivityIcon
    public var theme: IslandifyTheme
    public var countingMode: RelationshipCountingMode
    public var presentation: PresentationConfiguration
    public var notificationsEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        nickname: String = "",
        icon: ActivityIcon = .heart,
        theme: IslandifyTheme = .pastelCouple,
        countingMode: RelationshipCountingMode = .dPlus1,
        presentation: PresentationConfiguration? = nil,
        notificationsEnabled: Bool = true
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.startDate = startDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        self.icon = icon
        self.theme = theme
        self.countingMode = countingMode
        self.presentation = presentation ?? PresentationConfiguration(
            title: name,
            description: nickname,
            icon: icon,
            theme: theme,
            numberFormat: .dayCount,
            progressStyle: .dots,
            compactLeading: .icon,
            compactTrailing: .primaryValue,
            expandedDetails: [.title, .primaryValue, .secondaryValue],
            completionMessage: "Another day together"
        )
        self.notificationsEnabled = notificationsEnabled
    }
}

public struct RelationshipMilestone: Codable, Hashable, Sendable {
    public let kind: RelationshipMilestoneKind
    public let value: Int
    public let date: Date
    public let title: String

    public init(kind: RelationshipMilestoneKind, value: Int, date: Date, title: String) {
        self.kind = kind
        self.value = value
        self.date = date
        self.title = title
    }
}

public struct RelationshipSnapshot: Hashable, Sendable {
    public let dayCount: Int
    public let nextDayMilestone: RelationshipMilestone?
    public let nextAnnualMilestone: RelationshipMilestone?
    public let message: String

    public init(dayCount: Int, nextDayMilestone: RelationshipMilestone?, nextAnnualMilestone: RelationshipMilestone?, message: String) {
        self.dayCount = dayCount
        self.nextDayMilestone = nextDayMilestone
        self.nextAnnualMilestone = nextAnnualMilestone
        self.message = message
    }
}

public enum RelationshipCalculator {
    public static func dayCount(
        for configuration: RelationshipConfiguration,
        at date: Date,
        calendar: Calendar? = nil
    ) -> Int {
        let calendar = calendar ?? IslandifyDateMath.calendar(timeZoneIdentifier: configuration.timeZoneIdentifier)
        let elapsedDays = max(0, IslandifyDateMath.wholeCalendarDays(from: configuration.startDate, to: date, calendar: calendar))
        return elapsedDays + (configuration.countingMode == .dPlus1 ? 1 : 0)
    }

    public static func nextDayMilestone(
        for configuration: RelationshipConfiguration,
        at date: Date,
        calendar: Calendar? = nil
    ) -> RelationshipMilestone {
        let calendar = calendar ?? IslandifyDateMath.calendar(timeZoneIdentifier: configuration.timeZoneIdentifier)
        let current = dayCount(for: configuration, at: date, calendar: calendar)
        let nextValue = max(100, ((current / 100) + 1) * 100)
        let offset = configuration.countingMode == .dPlus1 ? nextValue - 1 : nextValue
        let milestoneDate = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: configuration.startDate)) ?? date
        return RelationshipMilestone(kind: .dayCount, value: nextValue, date: milestoneDate, title: "D+\(nextValue)")
    }

    public static func nextAnnualMilestone(
        for configuration: RelationshipConfiguration,
        at date: Date,
        calendar: Calendar? = nil
    ) -> RelationshipMilestone {
        let calendar = calendar ?? IslandifyDateMath.calendar(timeZoneIdentifier: configuration.timeZoneIdentifier)
        let startDay = calendar.startOfDay(for: configuration.startDate)
        let currentYear = calendar.component(.year, from: date)
        let startYear = calendar.component(.year, from: startDay)
        var years = max(1, currentYear - startYear)
        var candidate = calendar.date(byAdding: .year, value: years, to: startDay) ?? startDay
        if candidate <= date {
            years += 1
            candidate = calendar.date(byAdding: .year, value: years, to: startDay) ?? candidate
        }
        return RelationshipMilestone(kind: .annual, value: years, date: candidate, title: "\(years) year anniversary")
    }

    public static func snapshot(
        for configuration: RelationshipConfiguration,
        at date: Date,
        calendar: Calendar? = nil
    ) -> RelationshipSnapshot {
        let dayCount = dayCount(for: configuration, at: date, calendar: calendar)
        let nextDay = nextDayMilestone(for: configuration, at: date, calendar: calendar)
        let nextAnnual = nextAnnualMilestone(for: configuration, at: date, calendar: calendar)
        let name = configuration.nickname.isEmpty ? configuration.name : configuration.nickname
        return RelationshipSnapshot(
            dayCount: dayCount,
            nextDayMilestone: nextDay,
            nextAnnualMilestone: nextAnnual,
            message: "\(name)와 함께한 D+\(dayCount)"
        )
    }

    public static func presentation(for configuration: RelationshipConfiguration, at date: Date) -> ActivityPresentationState {
        let snapshot = snapshot(for: configuration, at: date)
        let next = snapshot.nextDayMilestone.map { "Next \($0.title)" }
        return ActivityPresentationState(
            kind: .relationship,
            phase: .active,
            title: configuration.presentation.title,
            description: configuration.nickname,
            icon: configuration.presentation.icon,
            palette: configuration.presentation.theme.palette,
            primaryValue: IslandifyTimeFormatter.dayCount(snapshot.dayCount),
            secondaryValue: next,
            progress: nil,
            compactLeading: configuration.presentation.icon.value,
            compactTrailing: IslandifyTimeFormatter.dayCount(snapshot.dayCount),
            expandedDetails: [snapshot.message, next ?? ""].filter { !$0.isEmpty },
            completionMessage: configuration.presentation.completionMessage,
            accessibilityLabel: snapshot.message
        )
    }
}

public struct RelationshipNotificationPlan: Hashable, Sendable {
    public let identifier: String
    public let date: Date
    public let title: String
    public let body: String

    public init(identifier: String, date: Date, title: String, body: String) {
        self.identifier = identifier
        self.date = date
        self.title = title
        self.body = body
    }

    public static func upcoming(for configuration: RelationshipConfiguration, at date: Date) -> [RelationshipNotificationPlan] {
        guard configuration.notificationsEnabled else { return [] }
        let snapshot = RelationshipCalculator.snapshot(for: configuration, at: date)
        var plans: [RelationshipNotificationPlan] = []
        if let milestone = snapshot.nextDayMilestone {
            plans.append(RelationshipNotificationPlan(
                identifier: "relationship-\(configuration.id.uuidString)-day-\(milestone.value)",
                date: milestone.date,
                title: milestone.title,
                body: "\(configuration.name), 오늘은 \(milestone.title)"
            ))
        }
        if let milestone = snapshot.nextAnnualMilestone {
            plans.append(RelationshipNotificationPlan(
                identifier: "relationship-\(configuration.id.uuidString)-annual-\(milestone.value)",
                date: milestone.date,
                title: milestone.title,
                body: "\(configuration.name), \(milestone.title)"
            ))
        }
        return plans
    }
}
