import Foundation
import SwiftUI

@MainActor
final class IslandifyAppModel: ObservableObject {
    @Published private(set) var activeTimer: TimerState?
    @Published private(set) var activeTravel: TravelConfiguration?
    @Published private(set) var activeRelationship: RelationshipConfiguration?
    @Published private(set) var activeRun: RunningState?
    @Published private(set) var runRecords: [RunRecord] = []
    @Published private(set) var locationAuthorization: LocationAuthorizationState = .notDetermined
    @Published private(set) var compositions: [ActivityKind: PresentationConfiguration] = [:]
    @Published private(set) var now = Date.now
    @Published var message: String?

    private let store: JSONLocalStore
    private let activityManager: LiveActivityManager
    private let notificationScheduler: LocalNotificationScheduler
    private let locationService: LocationService
    private var displayTimer: Timer?
    private var lastTravelKind: TravelStateKind?
    private var lastRelationshipDayCount: Int?

    private enum StoreKey {
        static let activeTimer = "active-timer"
        static let activeTravel = "active-travel"
        static let activeRelationship = "active-relationship"
        static let activeRun = "active-run"
        static let runRecords = "run-records"
        static let compositions = "compositions"
    }

    init() {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = applicationSupport.appendingPathComponent("Islandify", isDirectory: true)
        self.store = JSONLocalStore(directoryURL: directory)
        self.activityManager = LiveActivityManager()
        self.notificationScheduler = LocalNotificationScheduler()
        self.locationService = LocationService()

        loadTimer()
        loadTravel()
        loadRelationship()
        loadRun()
        loadRunRecords()
        loadCompositions()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    deinit {
        displayTimer?.invalidate()
    }

    func refresh(at date: Date = .now) {
        now = date
        if let activeTimer {
            let reconciled = TimerEngine.reconcile(activeTimer, at: date)
            if reconciled != activeTimer {
                self.activeTimer = reconciled
                persistTimer()
                if reconciled.phase == .completed && reconciled.configuration.autoEnd {
                    let presentation = TimerEngine.presentation(for: reconciled, at: date)
                    Task { await activityManager.end(presentation: presentation) }
                }
            }
        }

        if let activeTravel {
            let travelState = TravelCalculator.state(for: activeTravel, at: date)
            if travelState.kind != lastTravelKind {
                lastTravelKind = travelState.kind
                let presentation = TravelCalculator.presentation(for: activeTravel, at: date)
                Task { try? await activityManager.update(presentation: presentation) }
            }
        }

        if let activeRelationship {
            let relationshipSnapshot = RelationshipCalculator.snapshot(for: activeRelationship, at: date)
            if relationshipSnapshot.dayCount != lastRelationshipDayCount {
                lastRelationshipDayCount = relationshipSnapshot.dayCount
                let presentation = RelationshipCalculator.presentation(for: activeRelationship, at: date)
                Task { try? await activityManager.update(presentation: presentation) }
            }
        }

        if let activeRun {
            let presentation = RunningCalculator.presentation(for: activeRun, at: date)
            Task { try? await activityManager.update(presentation: presentation) }
        }
    }

    func startTimer(
        name: String,
        durationMinutes: Int,
        iconText: String,
        theme: IslandifyTheme,
        alertSound: TimerAlertSound,
        progressStyle: ProgressStyle,
        autoEnd: Bool
    ) async {
        guard activeTimer == nil && activeTravel == nil && activeRelationship == nil && activeRun == nil else {
            message = "End the current activity before starting another one."
            return
        }

        do {
            let icon = iconText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? ActivityIcon.flame
                : ActivityIcon(emoji: iconText)
            let configuration = try TimerConfiguration(
                name: name,
                duration: TimeInterval(durationMinutes * 60),
                icon: icon,
                theme: theme,
                alertSound: alertSound,
                progressStyle: progressStyle,
                autoEnd: autoEnd,
                presentation: compositions[.timer]
            )
            let state = TimerEngine.start(configuration: configuration, at: .now)
            activeTimer = state
            persistTimer()
            message = nil

            do {
                try await activityManager.start(presentation: TimerEngine.presentation(for: state, at: .now))
            } catch {
                message = error.localizedDescription
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func pauseTimer() async {
        guard let activeTimer else { return }
        do {
            let updated = try TimerEngine.pause(activeTimer, at: .now)
            self.activeTimer = updated
            persistTimer()
            try? await activityManager.update(presentation: TimerEngine.presentation(for: updated, at: .now))
        } catch {
            message = error.localizedDescription
        }
    }

    func resumeTimer() async {
        guard let activeTimer else { return }
        do {
            let updated = try TimerEngine.resume(activeTimer, at: .now)
            self.activeTimer = updated
            persistTimer()
            try? await activityManager.update(presentation: TimerEngine.presentation(for: updated, at: .now))
        } catch {
            message = error.localizedDescription
        }
    }

    func addMinute() async {
        guard let activeTimer else { return }
        do {
            let updated = try TimerEngine.addOneMinute(activeTimer, at: .now)
            self.activeTimer = updated
            persistTimer()
            try? await activityManager.update(presentation: TimerEngine.presentation(for: updated, at: .now))
        } catch {
            message = error.localizedDescription
        }
    }

    func resetTimer() async {
        guard let activeTimer else { return }
        let ended = TimerEngine.end(activeTimer, at: .now)
        await activityManager.end(presentation: TimerEngine.presentation(for: ended, at: .now))
        self.activeTimer = nil
        try? store.removeValue(forKey: StoreKey.activeTimer)
    }

    func endTimer() async {
        await resetTimer()
    }

    func startTravel(
        tripName: String,
        destination: String,
        departureDate: Date,
        timeZoneIdentifier: String,
        iconText: String,
        theme: IslandifyTheme
    ) async {
        guard activeTimer == nil && activeTravel == nil && activeRelationship == nil && activeRun == nil else {
            message = "End the current activity before starting another one."
            return
        }

        do {
            let icon = iconText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? ActivityIcon.airplane
                : ActivityIcon(emoji: iconText)
            let configuration = try TravelConfiguration(
                tripName: tripName,
                destination: destination,
                departureDate: departureDate,
                timeZoneIdentifier: timeZoneIdentifier,
                icon: icon,
                theme: theme,
                presentation: compositions[.travel]
            )
            activeTravel = configuration
            lastTravelKind = TravelCalculator.state(for: configuration, at: .now).kind
            persistTravel()
            message = nil

            do {
                try await activityManager.start(presentation: TravelCalculator.presentation(for: configuration, at: .now))
            } catch {
                message = error.localizedDescription
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func resetTravel() async {
        guard let activeTravel else { return }
        let presentation = TravelCalculator.presentation(for: activeTravel, at: .now)
        await activityManager.end(presentation: presentation)
        self.activeTravel = nil
        self.lastTravelKind = nil
        try? store.removeValue(forKey: StoreKey.activeTravel)
    }

    func endTravel() async {
        await resetTravel()
    }

    func startRelationship(
        name: String,
        nickname: String,
        startDate: Date,
        timeZoneIdentifier: String,
        iconText: String,
        theme: IslandifyTheme,
        countingMode: RelationshipCountingMode,
        notificationsEnabled: Bool
    ) async {
        guard activeTimer == nil && activeTravel == nil && activeRelationship == nil && activeRun == nil else {
            message = "End the current activity before starting another one."
            return
        }

        let icon = iconText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? ActivityIcon.heart
            : ActivityIcon(emoji: iconText)
        let configuration = RelationshipConfiguration(
            name: name,
            startDate: startDate,
            timeZoneIdentifier: timeZoneIdentifier,
            nickname: nickname,
            icon: icon,
            theme: theme,
            countingMode: countingMode,
            presentation: compositions[.relationship],
            notificationsEnabled: notificationsEnabled
        )
        activeRelationship = configuration
        lastRelationshipDayCount = RelationshipCalculator.dayCount(for: configuration, at: .now)
        persistRelationship()
        message = nil

        do {
            try await activityManager.start(presentation: RelationshipCalculator.presentation(for: configuration, at: .now))
        } catch {
            message = error.localizedDescription
        }

        if notificationsEnabled {
            let plans = RelationshipNotificationPlan.upcoming(for: configuration, at: .now)
            await notificationScheduler.schedule(plans: plans, timeZoneIdentifier: timeZoneIdentifier)
        }
    }

    func resetRelationship() async {
        guard let activeRelationship else { return }
        let plans = RelationshipNotificationPlan.upcoming(for: activeRelationship, at: .now)
        notificationScheduler.cancel(plans: plans)
        await activityManager.end(presentation: RelationshipCalculator.presentation(for: activeRelationship, at: .now))
        self.activeRelationship = nil
        self.lastRelationshipDayCount = nil
        try? store.removeValue(forKey: StoreKey.activeRelationship)
    }

    func endRelationship() async {
        await resetRelationship()
    }

    func startRun(name: String, theme: IslandifyTheme, iconText: String) async {
        guard activeTimer == nil && activeTravel == nil && activeRelationship == nil && activeRun == nil else {
            message = "End the current activity before starting another one."
            return
        }

        let icon = iconText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? ActivityIcon.running
            : ActivityIcon(emoji: iconText)
        let configuration = RunningConfiguration(name: name, icon: icon, theme: theme, presentation: compositions[.running])
        let state = RunningCalculator.start(configuration: configuration, at: .now)
        activeRun = state
        persistRun()
        message = nil

        locationAuthorization = locationService.start { [weak self] sample in
            Task { @MainActor [weak self] in
                self?.receiveLocationSample(sample)
            }
        }
        if !locationAuthorization.canCollectLocation {
            message = locationMessage(for: locationAuthorization)
        }

        do {
            try await activityManager.start(presentation: RunningCalculator.presentation(for: state, at: .now))
        } catch {
            message = [message, error.localizedDescription].compactMap { $0 }.joined(separator: " ")
        }
    }

    func pauseRun() async {
        guard let activeRun else { return }
        let updated = RunningCalculator.pause(activeRun, at: .now)
        self.activeRun = updated
        locationService.stop()
        persistRun()
        try? await activityManager.update(presentation: RunningCalculator.presentation(for: updated, at: .now))
    }

    func resumeRun() async {
        guard let activeRun else { return }
        let updated = RunningCalculator.resume(activeRun, at: .now)
        self.activeRun = updated
        locationAuthorization = locationService.start { [weak self] sample in
            Task { @MainActor [weak self] in
                self?.receiveLocationSample(sample)
            }
        }
        persistRun()
        try? await activityManager.update(presentation: RunningCalculator.presentation(for: updated, at: .now))
    }

    func endRun(memo: String? = nil) async {
        guard let activeRun else { return }
        let completed = RunningCalculator.finish(activeRun, at: .now)
        if let record = RunningCalculator.record(for: completed, at: .now, memo: memo) {
            runRecords.insert(record, at: 0)
            persistRunRecords()
        }
        locationService.stop()
        await activityManager.end(presentation: RunningCalculator.presentation(for: completed, at: .now))
        self.activeRun = nil
        try? store.removeValue(forKey: StoreKey.activeRun)
    }

    private func receiveLocationSample(_ sample: LocationSample) {
        guard let activeRun else { return }
        let updated = RunningCalculator.addSample(activeRun, sample: sample)
        guard updated != activeRun else { return }
        self.activeRun = updated
        persistRun()
        Task { try? await activityManager.update(presentation: RunningCalculator.presentation(for: updated, at: .now)) }
    }

    private func locationMessage(for state: LocationAuthorizationState) -> String {
        switch state {
        case .notDetermined:
            return "Location permission is being requested. The run can continue while permission is decided."
        case .denied:
            return "Location access was denied. This run will continue as a time-only run."
        case .restricted:
            return "Location access is restricted. This run will continue as a time-only run."
        case .unavailable:
            return "Location is unavailable. This run will continue as a time-only run."
        case .authorizedWhenInUse, .authorizedAlways:
            return ""
        }
    }

    private func loadTimer() {
        do {
            if let stored = try store.load(TimerState.self, forKey: StoreKey.activeTimer) {
                let reconciled = TimerEngine.reconcile(stored, at: .now)
                activeTimer = reconciled
                if reconciled != stored { persistTimer() }
            }
        } catch {
            message = "Saved timer could not be loaded."
        }
    }

    private func loadTravel() {
        do {
            if let stored = try store.load(TravelConfiguration.self, forKey: StoreKey.activeTravel) {
                activeTravel = stored
                lastTravelKind = TravelCalculator.state(for: stored, at: .now).kind
            }
        } catch {
            message = "Saved trip could not be loaded."
        }
    }

    private func loadRelationship() {
        do {
            if let stored = try store.load(RelationshipConfiguration.self, forKey: StoreKey.activeRelationship) {
                activeRelationship = stored
                lastRelationshipDayCount = RelationshipCalculator.dayCount(for: stored, at: .now)
            }
        } catch {
            message = "Saved relationship counter could not be loaded."
        }
    }

    private func loadRun() {
        do {
            if let stored = try store.load(RunningState.self, forKey: StoreKey.activeRun) {
                activeRun = stored
            }
        } catch {
            message = "Saved run could not be loaded."
        }
    }

    private func loadRunRecords() {
        do {
            runRecords = try store.load([RunRecord].self, forKey: StoreKey.runRecords) ?? []
        } catch {
            message = "Run history could not be loaded."
        }
    }

    private func loadCompositions() {
        do {
            let stored = try store.load([String: PresentationConfiguration].self, forKey: StoreKey.compositions) ?? [:]
            compositions = Dictionary(uniqueKeysWithValues: stored.compactMap { key, value in
                guard let kind = ActivityKind(rawValue: key) else { return nil }
                return (kind, value)
            })
        } catch {
            message = "Saved customization could not be loaded."
        }
    }

    private func persistTimer() {
        guard let activeTimer else { return }
        do {
            try store.save(activeTimer, forKey: StoreKey.activeTimer)
        } catch {
            message = "Timer could not be saved on this device."
        }
    }

    private func persistTravel() {
        guard let activeTravel else { return }
        do {
            try store.save(activeTravel, forKey: StoreKey.activeTravel)
        } catch {
            message = "Trip could not be saved on this device."
        }
    }

    private func persistRelationship() {
        guard let activeRelationship else { return }
        do {
            try store.save(activeRelationship, forKey: StoreKey.activeRelationship)
        } catch {
            message = "Relationship counter could not be saved on this device."
        }
    }

    private func persistRun() {
        guard let activeRun else { return }
        do {
            try store.save(activeRun, forKey: StoreKey.activeRun)
        } catch {
            message = "Run could not be saved on this device."
        }
    }

    private func persistRunRecords() {
        do {
            try store.save(runRecords, forKey: StoreKey.runRecords)
        } catch {
            message = "Run history could not be saved on this device."
        }
    }

    func composition(for kind: ActivityKind) -> PresentationConfiguration {
        compositions[kind] ?? PresentationConfiguration.default(for: kind)
    }

    func saveComposition(_ configuration: PresentationConfiguration, for kind: ActivityKind) {
        let normalized = PresentationComposer.normalized(configuration)
        compositions[kind] = normalized
        let stored = Dictionary(uniqueKeysWithValues: compositions.map { ($0.key.rawValue, $0.value) })
        do {
            try store.save(stored, forKey: StoreKey.compositions)
            message = "Saved \(kind.rawValue) layout."
        } catch {
            message = "Customization could not be saved on this device."
        }
    }
}
