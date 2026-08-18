import Foundation

public extension TravelCalculator {
    static func presentation(
        for configuration: TravelConfiguration,
        at date: Date,
        calendar: Calendar? = nil,
        language: IslandifyLanguage = .current
    ) -> ActivityPresentationState {
        let copy = IslandifyCopy(language: language)
        let configuredCalendar = calendar ?? configuration.calendar(basedOn: IslandifyDateMath.calendar(timeZoneIdentifier: configuration.timeZoneIdentifier))
        let state = TravelCalculator.state(for: configuration, at: date, calendar: configuredCalendar)
        let secondary: String?
        switch state.kind {
        case .started:
            secondary = copy.travelStarted
        case .dDay:
            secondary = configuration.destination
        case .d30, .d7, .d1, .daysRemaining:
            secondary = configuration.destination
        }

        let primaryValue: String
        switch configuration.presentation.numberFormat {
        case .duration, .compactDuration:
            primaryValue = state.countdown?.formatted ?? state.displayValue(language: language)
        default:
            primaryValue = state.displayValue(language: language)
        }

        return ActivityPresentationState(
            kind: .travel,
            phase: .active,
            title: configuration.presentation.title,
            description: configuration.presentation.description,
            icon: configuration.presentation.icon,
            palette: configuration.presentation.theme.palette,
            primaryValue: primaryValue,
            secondaryValue: secondary,
            progress: nil,
            progressStyle: configuration.presentation.progressStyle,
            compactLeading: configuration.presentation.icon.value,
            compactTrailing: primaryValue,
            expandedDetails: [configuration.destination, state.label(language: language), state.countdownText ?? ""].filter { !$0.isEmpty },
            completionMessage: configuration.presentation.completionMessage,
            accessibilityLabel: copy.travelAccessibility(
                tripName: configuration.tripName,
                destination: configuration.destination,
                value: state.displayValue(language: language)
            ),
            staleDate: configuration.departureDate,
            countdownEndDate: date < configuration.departureDate ? configuration.departureDate : nil
        )
    }
}
