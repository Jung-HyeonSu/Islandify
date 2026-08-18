import Foundation

public extension TravelCalculator {
    static func presentation(
        for configuration: TravelConfiguration,
        at date: Date,
        calendar: Calendar? = nil
    ) -> ActivityPresentationState {
        let configuredCalendar = calendar ?? configuration.calendar(basedOn: IslandifyDateMath.calendar(timeZoneIdentifier: configuration.timeZoneIdentifier))
        let state = TravelCalculator.state(for: configuration, at: date, calendar: configuredCalendar)
        let secondary: String?
        switch state.kind {
        case .started:
            secondary = "여행 시작"
        case .dDay:
            secondary = configuration.destination
        case .d30, .d7, .d1, .daysRemaining:
            secondary = configuration.destination
        }

        return ActivityPresentationState(
            kind: .travel,
            phase: .active,
            title: configuration.tripName,
            description: configuration.destination,
            icon: configuration.icon,
            palette: configuration.theme.palette,
            primaryValue: state.displayValue,
            secondaryValue: secondary,
            progress: nil,
            compactLeading: configuration.icon.value,
            compactTrailing: state.displayValue,
            expandedDetails: [configuration.destination, state.label, state.countdownText ?? ""].filter { !$0.isEmpty },
            completionMessage: "여행 시작",
            accessibilityLabel: "\(configuration.tripName), \(configuration.destination), \(state.displayValue)",
            staleDate: configuration.departureDate,
            countdownEndDate: date < configuration.departureDate ? configuration.departureDate : nil
        )
    }
}
