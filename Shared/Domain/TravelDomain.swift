import Foundation

public enum TravelValidationError: Error, Equatable, Sendable {
    case emptyTripName
    case emptyDestination
    case invalidTimeZoneIdentifier
}

public struct TravelConfiguration: Codable, Hashable, Sendable {
    public var id: UUID
    public var tripName: String
    public var destination: String
    public var departureDate: Date
    public var timeZoneIdentifier: String
    public var icon: ActivityIcon
    public var theme: IslandifyTheme
    public var presentation: PresentationConfiguration

    public init(
        id: UUID = UUID(),
        tripName: String,
        destination: String,
        departureDate: Date,
        timeZoneIdentifier: String = "UTC",
        icon: ActivityIcon = .airplane,
        theme: IslandifyTheme = .travelBlue,
        presentation: PresentationConfiguration? = nil
    ) throws {
        let trimmedTripName = tripName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTripName.isEmpty else { throw TravelValidationError.emptyTripName }

        let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDestination.isEmpty else { throw TravelValidationError.emptyDestination }

        guard TimeZone(identifier: timeZoneIdentifier) != nil else {
            throw TravelValidationError.invalidTimeZoneIdentifier
        }

        self.id = id
        self.tripName = trimmedTripName
        self.destination = trimmedDestination
        self.departureDate = departureDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.icon = icon
        self.theme = theme
        self.presentation = presentation ?? PresentationConfiguration(
            title: trimmedTripName,
            description: trimmedDestination,
            icon: icon,
            theme: theme,
            numberFormat: .dayCount,
            progressStyle: .hidden,
            compactLeading: .icon,
            compactTrailing: .primaryValue,
            expandedDetails: [.title, .primaryValue, .secondaryValue],
            completionMessage: "여행 시작"
        )
    }

    public init(
        id: UUID = UUID(),
        name: String,
        destination: String,
        departureDate: Date,
        timeZoneIdentifier: String = "UTC",
        icon: ActivityIcon = .airplane,
        theme: IslandifyTheme = .travelBlue
    ) throws {
        try self.init(
            id: id,
            tripName: name,
            destination: destination,
            departureDate: departureDate,
            timeZoneIdentifier: timeZoneIdentifier,
            icon: icon,
            theme: theme
        )
    }

    public init(
        id: UUID = UUID(),
        tripName: String,
        destination: String,
        departureDate: Date,
        departureTimeZoneIdentifier: String,
        icon: ActivityIcon = .airplane,
        theme: IslandifyTheme = .travelBlue
    ) throws {
        try self.init(
            id: id,
            tripName: tripName,
            destination: destination,
            departureDate: departureDate,
            timeZoneIdentifier: departureTimeZoneIdentifier,
            icon: icon,
            theme: theme
        )
    }

    public var name: String { tripName }

    public var departureTimeZoneIdentifier: String { timeZoneIdentifier }

    public var departureTimeZone: TimeZone {
        // The throwing initializer and Decodable initializer both validate this value.
        TimeZone(identifier: timeZoneIdentifier)!
    }

    public func calendar(basedOn calendar: Calendar) -> Calendar {
        var configuredCalendar = calendar
        configuredCalendar.timeZone = departureTimeZone
        return configuredCalendar
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case tripName
        case destination
        case departureDate
        case timeZoneIdentifier
        case icon
        case theme
        case presentation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(UUID.self, forKey: .id),
            tripName: container.decode(String.self, forKey: .tripName),
            destination: container.decode(String.self, forKey: .destination),
            departureDate: container.decode(Date.self, forKey: .departureDate),
            timeZoneIdentifier: container.decode(String.self, forKey: .timeZoneIdentifier),
            icon: container.decode(ActivityIcon.self, forKey: .icon),
            theme: container.decode(IslandifyTheme.self, forKey: .theme),
            presentation: container.decodeIfPresent(PresentationConfiguration.self, forKey: .presentation)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tripName, forKey: .tripName)
        try container.encode(destination, forKey: .destination)
        try container.encode(departureDate, forKey: .departureDate)
        try container.encode(timeZoneIdentifier, forKey: .timeZoneIdentifier)
        try container.encode(icon, forKey: .icon)
        try container.encode(theme, forKey: .theme)
        try container.encode(presentation, forKey: .presentation)
    }
}

public struct TravelCountdown: Codable, Hashable, Sendable {
    public let totalSeconds: Int

    public init(remaining: TimeInterval) {
        guard remaining.isFinite else {
            self.totalSeconds = remaining.sign == .minus ? 0 : Int.max
            return
        }

        self.totalSeconds = max(0, Int(remaining.rounded(.down)))
    }

    public var hours: Int { totalSeconds / 3_600 }

    public var minutes: Int { (totalSeconds % 3_600) / 60 }

    public var seconds: Int { totalSeconds % 60 }

    public var formatted: String {
        String(format: "%02d:%02d", hours, minutes)
    }

    public var displayText: String {
        "\(hours)시간 \(minutes)분"
    }
}

public enum TravelStateKind: String, Codable, CaseIterable, Hashable, Sendable {
    case d30
    case d7
    case d1
    case daysRemaining
    case dDay
    case started
}

public typealias TravelPhase = TravelStateKind

public struct TravelState: Codable, Hashable, Sendable {
    public let kind: TravelStateKind
    public let calendarDaysRemaining: Int
    public let remainingUntilDeparture: TimeInterval?
    public let countdown: TravelCountdown?

    public init(
        kind: TravelStateKind,
        calendarDaysRemaining: Int,
        remainingUntilDeparture: TimeInterval? = nil,
        countdown: TravelCountdown? = nil
    ) {
        self.kind = kind
        self.calendarDaysRemaining = calendarDaysRemaining
        self.remainingUntilDeparture = remainingUntilDeparture
        self.countdown = countdown
    }

    public var phase: TravelStateKind { kind }

    public var status: TravelStateKind { kind }

    public var daysRemaining: Int { calendarDaysRemaining }

    public var isDepartureDay: Bool { kind == .dDay }

    public var isPostDeparture: Bool { kind == .started }

    public var hoursRemaining: Int? { countdown?.hours }

    public var minutesRemaining: Int? { countdown?.minutes }

    public var countdownText: String? { countdown?.formatted }

    public var label: String {
        switch kind {
        case .d30:
            return "D-30"
        case .d7:
            return "D-7"
        case .d1:
            return "D-1"
        case .daysRemaining:
            return "D-\(calendarDaysRemaining)"
        case .dDay:
            return "D-DAY"
        case .started:
            return "여행 시작"
        }
    }

    public var displayValue: String {
        switch kind {
        case .dDay:
            return countdown?.displayText ?? label
        case .started, .d30, .d7, .d1, .daysRemaining:
            return label
        }
    }

    public var primaryValue: String { displayValue }
}

public enum TravelCalculator {
    public static func state(
        for configuration: TravelConfiguration,
        at date: Date,
        calendar: Calendar
    ) -> TravelState {
        let departureCalendar = configuration.calendar(basedOn: calendar)

        if date >= configuration.departureDate {
            return TravelState(
                kind: .started,
                calendarDaysRemaining: 0,
                remainingUntilDeparture: 0
            )
        }

        let departureDay = departureCalendar.startOfDay(for: configuration.departureDate)
        let currentDay = departureCalendar.startOfDay(for: date)
        let calendarDaysRemaining = max(
            0,
            departureCalendar.dateComponents([.day], from: currentDay, to: departureDay).day ?? 0
        )
        let remaining = max(0, configuration.departureDate.timeIntervalSince(date))

        if calendarDaysRemaining == 0 {
            return TravelState(
                kind: .dDay,
                calendarDaysRemaining: 0,
                remainingUntilDeparture: remaining,
                countdown: TravelCountdown(remaining: remaining)
            )
        }

        let kind: TravelStateKind
        switch calendarDaysRemaining {
        case 30:
            kind = .d30
        case 7:
            kind = .d7
        case 1:
            kind = .d1
        default:
            kind = .daysRemaining
        }

        return TravelState(
            kind: kind,
            calendarDaysRemaining: calendarDaysRemaining,
            remainingUntilDeparture: remaining
        )
    }

    public static func calculate(
        configuration: TravelConfiguration,
        at date: Date,
        calendar: Calendar
    ) -> TravelState {
        state(for: configuration, at: date, calendar: calendar)
    }

    public static func status(
        for configuration: TravelConfiguration,
        at date: Date,
        calendar: Calendar
    ) -> TravelState {
        state(for: configuration, at: date, calendar: calendar)
    }

    public static func state(
        for configuration: TravelConfiguration,
        at date: Date
    ) -> TravelState {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = configuration.departureTimeZone
        return state(for: configuration, at: date, calendar: calendar)
    }
}
