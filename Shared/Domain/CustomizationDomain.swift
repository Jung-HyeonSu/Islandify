import Foundation

public enum CompositionValidationError: Error, Equatable, Sendable {
    case emptyTitle
    case titleTooLong
    case descriptionTooLong
    case completionMessageTooLong
    case tooManyExpandedDetails
}

public enum PresentationComposer {
    public static func validate(_ configuration: PresentationConfiguration) -> [CompositionValidationError] {
        var errors: [CompositionValidationError] = []
        let title = configuration.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty { errors.append(.emptyTitle) }
        if title.count > 32 { errors.append(.titleTooLong) }
        if configuration.description.count > 80 { errors.append(.descriptionTooLong) }
        if configuration.completionMessage.count > 80 { errors.append(.completionMessageTooLong) }
        if configuration.expandedDetails.count > 4 { errors.append(.tooManyExpandedDetails) }
        return errors
    }

    public static func normalized(_ configuration: PresentationConfiguration) -> PresentationConfiguration {
        var normalized = configuration
        normalized.title = String(configuration.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(32))
        normalized.description = String(configuration.description.prefix(80))
        normalized.completionMessage = String(configuration.completionMessage.prefix(80))
        normalized.expandedDetails = Array(configuration.expandedDetails.prefix(4))
        return normalized
    }

    public static func previewState(
        for kind: ActivityKind,
        configuration: PresentationConfiguration,
        phase: ActivityPhase = .active
    ) -> ActivityPresentationState {
        let (primary, secondary, progress) = sampleValues(for: kind, phase: phase)
        let base = ActivityPresentationState(
            kind: kind,
            phase: phase,
            title: configuration.title,
            description: configuration.description,
            icon: configuration.icon,
            palette: configuration.theme.palette,
            primaryValue: primary,
            secondaryValue: secondary,
            progress: progress,
            progressStyle: configuration.progressStyle,
            compactLeading: "",
            compactTrailing: "",
            expandedDetails: [],
            completionMessage: configuration.completionMessage,
            accessibilityLabel: "\(configuration.title), \(primary)"
        )

        let compactLeading = value(for: configuration.compactLeading, state: base)
        let compactTrailing = value(for: configuration.compactTrailing, state: base)
        let details = configuration.expandedDetails.map { value(for: $0, state: base) }
        return ActivityPresentationState(
            kind: kind,
            phase: phase,
            title: configuration.title,
            description: configuration.description,
            icon: configuration.icon,
            palette: configuration.theme.palette,
            primaryValue: primary,
            secondaryValue: secondary,
            progress: progress,
            progressStyle: configuration.progressStyle,
            compactLeading: compactLeading,
            compactTrailing: compactTrailing,
            expandedDetails: details,
            completionMessage: configuration.completionMessage,
            accessibilityLabel: "\(configuration.title), \(primary)",
            staleDate: nil
        )
    }

    private static func sampleValues(for kind: ActivityKind, phase: ActivityPhase) -> (String, String?, Double?) {
        if phase == .completed {
            return ("Done", "Completed", 1)
        }
        switch kind {
        case .timer: return ("24:58", "40%", 0.4)
        case .travel: return ("D-7", "Seoul", nil)
        case .relationship: return ("D+100", "Next annual", nil)
        case .running: return ("5.00 km", "05:42/km", nil)
        }
    }

    private static func value(for slot: PresentationSlot, state: ActivityPresentationState) -> String {
        switch slot {
        case .icon: return state.icon.value
        case .title: return state.title
        case .description: return state.description
        case .primaryValue: return state.primaryValue
        case .secondaryValue: return state.secondaryValue ?? ""
        case .progress: return state.progress.map { "\(Int(($0 * 100).rounded()))%" } ?? ""
        case .phase: return state.phase.rawValue.capitalized
        }
    }
}
