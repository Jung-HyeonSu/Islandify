import Foundation

public enum TimerAlertSound: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case chime
    case bell
    case gentle
}

public enum TimerValidationError: Error, Equatable, Sendable {
    case emptyName
    case durationTooShort
    case durationTooLong
}

public enum TimerActionError: Error, Equatable, Sendable {
    case alreadyActive
    case notActive
    case notPaused
    case cannotModifyCompletedTimer
    case durationLimitReached
}

public struct TimerConfiguration: Codable, Hashable, Sendable {
    public static let minimumDuration: TimeInterval = 60
    public static let maximumDuration: TimeInterval = 8 * 60 * 60

    public let id: UUID
    public var name: String
    public var duration: TimeInterval
    public var icon: ActivityIcon
    public var theme: IslandifyTheme
    public var alertSound: TimerAlertSound
    public var progressStyle: ProgressStyle
    public var autoEnd: Bool
    public var presentation: PresentationConfiguration

    public init(
        id: UUID = UUID(),
        name: String,
        duration: TimeInterval,
        icon: ActivityIcon = .flame,
        theme: IslandifyTheme = .neonTimer,
        alertSound: TimerAlertSound = .chime,
        progressStyle: ProgressStyle = .bar,
        autoEnd: Bool = true,
        presentation: PresentationConfiguration? = nil
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw TimerValidationError.emptyName }
        guard duration >= Self.minimumDuration else { throw TimerValidationError.durationTooShort }
        guard duration <= Self.maximumDuration else { throw TimerValidationError.durationTooLong }

        self.id = id
        self.name = trimmedName
        self.duration = duration
        self.icon = icon
        self.theme = theme
        self.alertSound = alertSound
        self.progressStyle = progressStyle
        self.autoEnd = autoEnd
        self.presentation = presentation ?? PresentationConfiguration(
            title: trimmedName,
            description: "Timer",
            icon: icon,
            theme: theme,
            numberFormat: .compactDuration,
            progressStyle: progressStyle,
            compactLeading: .icon,
            compactTrailing: .primaryValue,
            expandedDetails: [.title, .primaryValue, .progress],
            completionMessage: "\(trimmedName) complete"
        )
    }

    public func changingDuration(by delta: TimeInterval) throws -> TimerConfiguration {
        try TimerConfiguration(
            id: id,
            name: name,
            duration: duration + delta,
            icon: icon,
            theme: theme,
            alertSound: alertSound,
            progressStyle: progressStyle,
            autoEnd: autoEnd,
            presentation: presentation
        )
    }
}

public struct TimerState: Codable, Hashable, Sendable {
    public var configuration: TimerConfiguration
    public var phase: ActivityPhase
    public var startedAt: Date?
    public var endDate: Date?
    public var pausedAt: Date?
    public var pausedRemaining: TimeInterval?
    public var completedAt: Date?

    public init(configuration: TimerConfiguration, phase: ActivityPhase = .configured) {
        self.configuration = configuration
        self.phase = phase
        self.startedAt = nil
        self.endDate = nil
        self.pausedAt = nil
        self.pausedRemaining = nil
        self.completedAt = nil
    }
}

public struct TimerSnapshot: Hashable, Sendable {
    public let phase: ActivityPhase
    public let remaining: TimeInterval
    public let elapsed: TimeInterval
    public let progress: Double
    public let isExpired: Bool

    public init(phase: ActivityPhase, remaining: TimeInterval, elapsed: TimeInterval, progress: Double, isExpired: Bool) {
        self.phase = phase
        self.remaining = remaining
        self.elapsed = elapsed
        self.progress = progress
        self.isExpired = isExpired
    }
}

public enum TimerEngine {
    public static func start(configuration: TimerConfiguration, at date: Date) -> TimerState {
        var state = TimerState(configuration: configuration, phase: .active)
        state.startedAt = date
        state.endDate = date.addingTimeInterval(configuration.duration)
        return state
    }

    public static func snapshot(for state: TimerState, at date: Date) -> TimerSnapshot {
        let duration = state.configuration.duration
        switch state.phase {
        case .configured:
            return TimerSnapshot(phase: .configured, remaining: duration, elapsed: 0, progress: 0, isExpired: false)
        case .active:
            let remaining = max(0, (state.endDate ?? date).timeIntervalSince(date))
            let expired = remaining <= 0
            let elapsed = min(duration, max(0, duration - remaining))
            return TimerSnapshot(
                phase: expired ? .completed : .active,
                remaining: remaining,
                elapsed: elapsed,
                progress: IslandifyDateMath.clampedProgress(elapsed: elapsed, duration: duration),
                isExpired: expired
            )
        case .paused:
            let remaining = max(0, state.pausedRemaining ?? 0)
            let elapsed = min(duration, max(0, duration - remaining))
            return TimerSnapshot(
                phase: .paused,
                remaining: remaining,
                elapsed: elapsed,
                progress: IslandifyDateMath.clampedProgress(elapsed: elapsed, duration: duration),
                isExpired: remaining <= 0
            )
        case .completed, .ended:
            return TimerSnapshot(phase: state.phase, remaining: 0, elapsed: duration, progress: 1, isExpired: true)
        }
    }

    public static func reconcile(_ state: TimerState, at date: Date) -> TimerState {
        guard state.phase == .active, snapshot(for: state, at: date).isExpired else { return state }
        var updated = state
        updated.phase = .completed
        updated.completedAt = state.endDate ?? date
        updated.endDate = nil
        return updated
    }

    public static func pause(_ state: TimerState, at date: Date) throws -> TimerState {
        guard state.phase == .active else {
            if state.phase == .paused { throw TimerActionError.notActive }
            throw TimerActionError.notActive
        }
        let snapshot = snapshot(for: state, at: date)
        guard !snapshot.isExpired else { throw TimerActionError.cannotModifyCompletedTimer }

        var updated = state
        updated.phase = .paused
        updated.pausedAt = date
        updated.pausedRemaining = snapshot.remaining
        updated.endDate = nil
        return updated
    }

    public static func resume(_ state: TimerState, at date: Date) throws -> TimerState {
        guard state.phase == .paused else { throw TimerActionError.notPaused }
        guard let remaining = state.pausedRemaining, remaining > 0 else {
            throw TimerActionError.cannotModifyCompletedTimer
        }

        var updated = state
        updated.phase = .active
        updated.endDate = date.addingTimeInterval(remaining)
        updated.pausedAt = nil
        updated.pausedRemaining = nil
        return updated
    }

    public static func reset(_ state: TimerState) -> TimerState {
        TimerState(configuration: state.configuration)
    }

    public static func end(_ state: TimerState, at date: Date) -> TimerState {
        var updated = state
        updated.phase = .ended
        updated.completedAt = date
        updated.endDate = nil
        updated.pausedAt = nil
        updated.pausedRemaining = nil
        return updated
    }

    public static func addOneMinute(_ state: TimerState, at date: Date) throws -> TimerState {
        guard state.phase != .completed, state.phase != .ended else {
            throw TimerActionError.cannotModifyCompletedTimer
        }
        guard state.configuration.duration < TimerConfiguration.maximumDuration else {
            throw TimerActionError.durationLimitReached
        }

        var updated = state
        updated.configuration = try state.configuration.changingDuration(by: 60)
        switch state.phase {
        case .active:
            updated.endDate = (state.endDate ?? date).addingTimeInterval(60)
        case .paused:
            updated.pausedRemaining = (state.pausedRemaining ?? 0) + 60
        case .configured:
            break
        case .completed, .ended:
            break
        }
        return updated
    }

    public static func presentation(for state: TimerState, at date: Date) -> ActivityPresentationState {
        let snapshot = snapshot(for: state, at: date)
        let phase = snapshot.phase
        let value: String
        switch state.configuration.presentation.numberFormat {
        case .duration:
            value = IslandifyTimeFormatter.duration(snapshot.remaining, includeHours: true)
        case .decimal:
            value = "\(Int((snapshot.remaining / 60).rounded())) min"
        default:
            value = IslandifyTimeFormatter.compactDuration(snapshot.remaining)
        }
        let percent = "\(Int((snapshot.progress * 100).rounded()))%"
        let secondary = phase == .completed ? state.configuration.presentation.completionMessage : percent
        return ActivityPresentationState(
            kind: .timer,
            phase: phase,
            title: state.configuration.presentation.title,
            description: state.configuration.presentation.description,
            icon: state.configuration.presentation.icon,
            palette: state.configuration.presentation.theme.palette,
            primaryValue: value,
            secondaryValue: secondary,
            progress: snapshot.progress,
            progressStyle: state.configuration.presentation.progressStyle,
            compactLeading: state.configuration.presentation.icon.value,
            compactTrailing: value,
            expandedDetails: [state.configuration.name, value, "Progress \(percent)"],
            completionMessage: state.configuration.presentation.completionMessage,
            accessibilityLabel: "\(state.configuration.name), \(value), \(phase.rawValue)",
            staleDate: state.phase == .active ? state.endDate : nil,
            countdownEndDate: state.phase == .active ? state.endDate : nil
        )
    }
}
