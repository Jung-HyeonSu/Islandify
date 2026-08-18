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
            title: configuration.presentation.title,
            description: configuration.presentation.description,
            icon: configuration.presentation.icon,
            palette: configuration.presentation.theme.palette,
            primaryValue: state.displayValue,
            secondaryValue: secondary,
            progress: nil,
            compactLeading: configuration.presentation.icon.value,
            compactTrailing: state.displayValue,
            expandedDetails: [configuration.destination, state.label, state.countdownText ?? ""].filter { !$0.isEmpty },
            completionMessage: configuration.presentation.completionMessage,
            accessibilityLabel: "\(configuration.tripName), \(configuration.destination), \(state.displayValue)",
            staleDate: configuration.departureDate,
            countdownEndDate: date < configuration.departureDate ? configuration.departureDate : nil
        )
    }
}
