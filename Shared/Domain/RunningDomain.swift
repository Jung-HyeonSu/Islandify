import Foundation

public enum RunningPhase: String, Codable, CaseIterable, Hashable, Sendable {
    case configured
    case active
    case paused
    case completed
    case ended
}

public enum LocationAuthorizationState: String, Codable, CaseIterable, Hashable, Sendable {
    case notDetermined
    case authorizedWhenInUse
    case authorizedAlways
    case denied
    case restricted
    case unavailable

    public var canCollectLocation: Bool {
        self == .authorizedWhenInUse || self == .authorizedAlways
    }
}

public struct LocationSample: Codable, Hashable, Sendable {
    public let timestamp: Date
    public let latitude: Double
    public let longitude: Double
    public let horizontalAccuracy: Double
    public let speedMetersPerSecond: Double

    public init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double = 5,
        speedMetersPerSecond: Double = -1
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speedMetersPerSecond = speedMetersPerSecond
    }

    public var isUsable: Bool {
        latitude.isFinite && longitude.isFinite &&
            abs(latitude) <= 90 && abs(longitude) <= 180 &&
            horizontalAccuracy.isFinite && horizontalAccuracy >= 0 && horizontalAccuracy <= 100
    }
}

public protocol LocationSampleProvider: AnyObject {
    func start(sink: @escaping (LocationSample) -> Void) -> LocationAuthorizationState
    func stop()
}

public struct RunningConfiguration: Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var icon: ActivityIcon
    public var theme: IslandifyTheme
    public var weightKg: Double
    public var presentation: PresentationConfiguration

    public init(
        id: UUID = UUID(),
        name: String = "Run",
        icon: ActivityIcon = .running,
        theme: IslandifyTheme = .runningGreen,
        weightKg: Double = 65,
        presentation: PresentationConfiguration? = nil
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Run" : name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.icon = icon
        self.theme = theme
        self.weightKg = weightKg > 0 && weightKg.isFinite ? weightKg : 65
        self.presentation = presentation ?? PresentationConfiguration(
            title: self.name,
            description: "GPS run",
            icon: icon,
            theme: theme,
            numberFormat: .distance,
            progressStyle: .bar,
            compactLeading: .icon,
            compactTrailing: .primaryValue,
            expandedDetails: [.title, .primaryValue, .secondaryValue],
            completionMessage: "Run complete"
        )
    }
}

public struct RunningState: Codable, Hashable, Sendable {
    public var id: UUID
    public var configuration: RunningConfiguration
    public var phase: RunningPhase
    public var startedAt: Date?
    public var resumedAt: Date?
    public var endedAt: Date?
    public var accumulatedActiveDuration: TimeInterval
    public var segmentActiveDuration: TimeInterval
    public var distanceMeters: Double
    public var segmentDistanceMeters: Double
    public var lastSample: LocationSample?

    public init(configuration: RunningConfiguration, phase: RunningPhase = .configured) {
        self.id = UUID()
        self.configuration = configuration
        self.phase = phase
        self.startedAt = nil
        self.resumedAt = nil
        self.endedAt = nil
        self.accumulatedActiveDuration = 0
        self.segmentActiveDuration = 0
        self.distanceMeters = 0
        self.segmentDistanceMeters = 0
        self.lastSample = nil
    }
}

public struct RunningSnapshot: Hashable, Sendable {
    public let phase: RunningPhase
    public let elapsed: TimeInterval
    public let distanceMeters: Double
    public let currentPaceSecondsPerKilometer: TimeInterval?
    public let averagePaceSecondsPerKilometer: TimeInterval?
    public let calories: Double

    public var distanceKilometers: Double { distanceMeters / 1_000 }
}

public struct RunRecord: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let duration: TimeInterval
    public let distanceMeters: Double
    public let averagePaceSecondsPerKilometer: TimeInterval?
    public let calories: Double
    public let memo: String?

    public init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        distanceMeters: Double,
        averagePaceSecondsPerKilometer: TimeInterval?,
        calories: Double,
        memo: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.duration = max(0, duration)
        self.distanceMeters = max(0, distanceMeters)
        self.averagePaceSecondsPerKilometer = averagePaceSecondsPerKilometer
        self.calories = max(0, calories)
        self.memo = memo
    }
}

public enum RunningCalculator {
    public static let defaultMET = 8.3

    public static func start(configuration: RunningConfiguration, at date: Date) -> RunningState {
        var state = RunningState(configuration: configuration, phase: .active)
        state.startedAt = date
        state.resumedAt = date
        return state
    }

    public static func pause(_ state: RunningState, at date: Date) -> RunningState {
        guard state.phase == .active else { return state }
        var updated = state
        let activeInterval = max(0, date.timeIntervalSince(state.resumedAt ?? date))
        updated.accumulatedActiveDuration += activeInterval
        updated.segmentActiveDuration += activeInterval
        updated.phase = .paused
        updated.resumedAt = nil
        updated.lastSample = nil
        return updated
    }

    public static func resume(_ state: RunningState, at date: Date) -> RunningState {
        guard state.phase == .paused else { return state }
        var updated = state
        updated.phase = .active
        updated.resumedAt = date
        updated.lastSample = nil
        return updated
    }

    public static func addSample(_ state: RunningState, sample: LocationSample) -> RunningState {
        guard state.phase == .active, sample.isUsable else { return state }
        var updated = state
        if let previous = state.lastSample, sample.timestamp >= previous.timestamp {
            let delta = distanceMeters(from: previous, to: sample)
            if delta <= 500 {
                updated.distanceMeters += delta
                updated.segmentDistanceMeters += delta
            }
        }
        updated.lastSample = sample
        return updated
    }

    public static func finish(_ state: RunningState, at date: Date) -> RunningState {
        guard state.phase == .active || state.phase == .paused else { return state }
        var updated = state
        if state.phase == .active {
            let activeInterval = max(0, date.timeIntervalSince(state.resumedAt ?? date))
            updated.accumulatedActiveDuration += activeInterval
            updated.segmentActiveDuration += activeInterval
        }
        updated.phase = .completed
        updated.endedAt = date
        updated.resumedAt = nil
        updated.lastSample = nil
        return updated
    }

    public static func snapshot(for state: RunningState, at date: Date) -> RunningSnapshot {
        let liveInterval: TimeInterval = state.phase == .active
            ? max(0, date.timeIntervalSince(state.resumedAt ?? date))
            : 0
        let elapsed = state.accumulatedActiveDuration + liveInterval
        let segmentElapsed = state.segmentActiveDuration + liveInterval
        let averagePace = pace(seconds: elapsed, distanceMeters: state.distanceMeters)
        let currentPace = pace(seconds: segmentElapsed, distanceMeters: state.segmentDistanceMeters)
        return RunningSnapshot(
            phase: state.phase,
            elapsed: elapsed,
            distanceMeters: state.distanceMeters,
            currentPaceSecondsPerKilometer: currentPace,
            averagePaceSecondsPerKilometer: averagePace,
            calories: estimatedCalories(duration: elapsed, weightKg: state.configuration.weightKg)
        )
    }

    public static func record(for state: RunningState, at date: Date, memo: String? = nil) -> RunRecord? {
        guard let startDate = state.startedAt else { return nil }
        let completed = state.phase == .completed ? state : finish(state, at: date)
        let snapshot = snapshot(for: completed, at: date)
        return RunRecord(
            name: completed.configuration.name,
            startDate: startDate,
            endDate: completed.endedAt ?? date,
            duration: snapshot.elapsed,
            distanceMeters: snapshot.distanceMeters,
            averagePaceSecondsPerKilometer: snapshot.averagePaceSecondsPerKilometer,
            calories: snapshot.calories,
            memo: memo
        )
    }

    public static func distanceMeters(from first: LocationSample, to second: LocationSample) -> Double {
        let earthRadius = 6_371_000.0
        let latitude1 = first.latitude * .pi / 180
        let latitude2 = second.latitude * .pi / 180
        let deltaLatitude = (second.latitude - first.latitude) * .pi / 180
        let deltaLongitude = (second.longitude - first.longitude) * .pi / 180
        let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(latitude1) * cos(latitude2) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(max(0, 1 - a)))
    }

    public static func pace(seconds: TimeInterval, distanceMeters: Double) -> TimeInterval? {
        guard seconds > 0, distanceMeters >= 100 else { return nil }
        return seconds / (distanceMeters / 1_000)
    }

    public static func estimatedCalories(duration: TimeInterval, weightKg: Double, met: Double = defaultMET) -> Double {
        guard duration > 0, weightKg > 0, met > 0 else { return 0 }
        return met * 3.5 * weightKg / 200 * (duration / 60)
    }

    public static func presentation(for state: RunningState, at date: Date) -> ActivityPresentationState {
        let snapshot = snapshot(for: state, at: date)
        let distance = IslandifyTimeFormatter.distance(kilometers: snapshot.distanceKilometers)
        let pace = IslandifyTimeFormatter.pace(secondsPerKilometer: snapshot.averagePaceSecondsPerKilometer)
        let phase: ActivityPhase = {
            switch state.phase {
            case .configured: return .configured
            case .active: return .active
            case .paused: return .paused
            case .completed: return .completed
            case .ended: return .ended
            }
        }()
        return ActivityPresentationState(
            kind: .running,
            phase: phase,
            title: state.configuration.presentation.title,
            description: state.configuration.presentation.description,
            icon: state.configuration.presentation.icon,
            palette: state.configuration.presentation.theme.palette,
            primaryValue: distance,
            secondaryValue: pace,
            progress: nil,
            compactLeading: state.configuration.presentation.icon.value,
            compactTrailing: distance,
            expandedDetails: [distance, "Time \(IslandifyTimeFormatter.duration(snapshot.elapsed))", "Pace \(pace)"],
            completionMessage: state.configuration.presentation.completionMessage,
            accessibilityLabel: "\(state.configuration.name), \(distance), \(pace), \(IslandifyTimeFormatter.duration(snapshot.elapsed))"
        )
    }
}
