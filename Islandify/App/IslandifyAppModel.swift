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

    private var copy: IslandifyCopy { IslandifyCopy.current }

    private let store: JSONLocalStore
    private let activityManager: LiveActivityManager
    private let notificationScheduler: LocalNotificationScheduler
    private let locationService: LocationService
    private var displayTimer: Timer?
    private var lastTravelKind: TravelStateKind?
    private var lastRelationshipDayCount: Int?
    private var lastRunProjectionDate: Date?

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
        self.store = JSONLocalStore(directoryURL: directory, migrations: [1: { _, valueData in valueData }])
        self.activityManager = LiveActivityManager()
        self.notificationScheduler = LocalNotificationScheduler()
        self.locationService = LocationService()

        loadTimer()
        loadTravel()
        loadRelationship()
        loadRun()
        loadRunRecords()
        loadCompositions()
        reconcilePersistedActivities()
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
        activityManager.reconcile()
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
            let shouldProject = lastRunProjectionDate.map { date.timeIntervalSince($0) >= 10 } ?? true
            if shouldProject {
                lastRunProjectionDate = date
                let presentation = RunningCalculator.presentation(for: activeRun, at: date)
                Task { try? await activityManager.update(presentation: presentation) }
            }
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
            message = copy.endCurrentActivity
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
                presentation: presentation(for: .timer, icon: icon)
            )
            let state = TimerEngine.start(configuration: configuration, at: .now)
            activeTimer = state
            persistTimer()
            message = nil

            do {
                try await activityManager.start(presentation: TimerEngine.presentation(for: state, at: .now))
            } catch {
                message = localizedMessage(for: error)
            }
        } catch {
            message = localizedMessage(for: error)
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
            message = localizedMessage(for: error)
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
            message = localizedMessage(for: error)
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
            message = localizedMessage(for: error)
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
            message = copy.endCurrentActivity
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
                presentation: presentation(for: .travel, icon: icon)
            )
            activeTravel = configuration
            lastTravelKind = TravelCalculator.state(for: configuration, at: .now).kind
            persistTravel()
            message = nil

            do {
                try await activityManager.start(presentation: TravelCalculator.presentation(for: configuration, at: .now))
            } catch {
                message = localizedMessage(for: error)
            }
        } catch {
            message = localizedMessage(for: error)
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
            message = copy.endCurrentActivity
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
            presentation: presentation(for: .relationship, icon: icon),
            notificationsEnabled: notificationsEnabled
        )
        activeRelationship = configuration
        lastRelationshipDayCount = RelationshipCalculator.dayCount(for: configuration, at: .now)
        persistRelationship()
        message = nil

        do {
            try await activityManager.start(presentation: RelationshipCalculator.presentation(for: configuration, at: .now))
        } catch {
            message = localizedMessage(for: error)
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
            message = copy.endCurrentActivity
            return
        }

        let icon = iconText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? ActivityIcon.running
            : ActivityIcon(emoji: iconText)
        let configuration = RunningConfiguration(name: name, icon: icon, theme: theme, presentation: presentation(for: .running, icon: icon))
        let state = RunningCalculator.start(configuration: configuration, at: .now)
        activeRun = state
        lastRunProjectionDate = .now
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
            message = [message, localizedMessage(for: error)].compactMap { $0 }.joined(separator: " ")
        }
    }

    func pauseRun() async {
        guard let activeRun else { return }
        let updated = RunningCalculator.pause(activeRun, at: .now)
        self.activeRun = updated
        lastRunProjectionDate = .now
        locationService.stop()
        persistRun()
        try? await activityManager.update(presentation: RunningCalculator.presentation(for: updated, at: .now))
    }

    func resumeRun() async {
        guard let activeRun else { return }
        let updated = RunningCalculator.resume(activeRun, at: .now)
        self.activeRun = updated
        lastRunProjectionDate = .now
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
        self.lastRunProjectionDate = nil
        try? store.removeValue(forKey: StoreKey.activeRun)
    }

    private func receiveLocationSample(_ sample: LocationSample) {
        guard let activeRun else { return }
        let updated = RunningCalculator.addSample(activeRun, sample: sample)
        guard updated != activeRun else { return }
        self.activeRun = updated
        lastRunProjectionDate = .now
        persistRun()
        Task { try? await activityManager.update(presentation: RunningCalculator.presentation(for: updated, at: .now)) }
    }

    private func locationMessage(for state: LocationAuthorizationState) -> String {
        copy.locationMessage(for: state.rawValue)
    }

    private func loadTimer() {
        do {
            if let stored = try store.load(TimerState.self, forKey: StoreKey.activeTimer) {
                let reconciled = TimerEngine.reconcile(stored, at: .now)
                activeTimer = reconciled
                if reconciled != stored { persistTimer() }
            }
        } catch {
            message = copy.savedTimerLoadFailed
        }
    }

    private func loadTravel() {
        do {
            if let stored = try store.load(TravelConfiguration.self, forKey: StoreKey.activeTravel) {
                activeTravel = stored
                lastTravelKind = TravelCalculator.state(for: stored, at: .now).kind
            }
        } catch {
            message = copy.savedTravelLoadFailed
        }
    }

    private func loadRelationship() {
        do {
            if let stored = try store.load(RelationshipConfiguration.self, forKey: StoreKey.activeRelationship) {
                activeRelationship = stored
                lastRelationshipDayCount = RelationshipCalculator.dayCount(for: stored, at: .now)
            }
        } catch {
            message = copy.savedRelationshipLoadFailed
        }
    }

    private func loadRun() {
        do {
            if let stored = try store.load(RunningState.self, forKey: StoreKey.activeRun) {
                if stored.phase == .active {
                    activeRun = RunningCalculator.pause(stored, at: .now)
                    persistRun()
                    message = copy.previousRunPaused
                } else {
                    activeRun = stored
                }
            }
        } catch {
            message = copy.savedRunLoadFailed
        }
    }

    private func loadRunRecords() {
        do {
            runRecords = try store.load([RunRecord].self, forKey: StoreKey.runRecords) ?? []
        } catch {
            message = copy.runHistoryLoadFailed
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
            message = copy.savedCustomizationLoadFailed
        }
    }

    private func persistTimer() {
        guard let activeTimer else { return }
        do {
            try store.save(activeTimer, forKey: StoreKey.activeTimer)
        } catch {
            message = copy.timerSaveFailed
        }
    }

    private func persistTravel() {
        guard let activeTravel else { return }
        do {
            try store.save(activeTravel, forKey: StoreKey.activeTravel)
        } catch {
            message = copy.travelSaveFailed
        }
    }

    private func persistRelationship() {
        guard let activeRelationship else { return }
        do {
            try store.save(activeRelationship, forKey: StoreKey.activeRelationship)
        } catch {
            message = copy.relationshipSaveFailed
        }
    }

    private func persistRun() {
        guard let activeRun else { return }
        do {
            try store.save(activeRun, forKey: StoreKey.activeRun)
        } catch {
            message = copy.runSaveFailed
        }
    }

    private func persistRunRecords() {
        do {
            try store.save(runRecords, forKey: StoreKey.runRecords)
        } catch {
            message = copy.runHistorySaveFailed
        }
    }

    private func reconcilePersistedActivities() {
        var foundActivity = false
        if activeTimer != nil {
            foundActivity = true
        }
        if activeTravel != nil {
            if foundActivity {
                activeTravel = nil
                try? store.removeValue(forKey: StoreKey.activeTravel)
                message = copy.duplicateSavedActivity(timerIsAuthoritative: true)
            } else {
                foundActivity = true
            }
        }
        if activeRelationship != nil {
            if foundActivity {
                activeRelationship = nil
                try? store.removeValue(forKey: StoreKey.activeRelationship)
                message = copy.duplicateSavedActivity(timerIsAuthoritative: false)
            } else {
                foundActivity = true
            }
        }
        if activeRun != nil {
            if foundActivity {
                activeRun = nil
                locationService.stop()
                try? store.removeValue(forKey: StoreKey.activeRun)
                message = copy.duplicateSavedActivity(timerIsAuthoritative: false)
            }
        }
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "islandify" else { return }
        if url.host == "activity" {
            message = copy.activityDetailsInActiveTab
        } else {
            message = copy.openedFromSupportedLink
        }
    }

    func composition(for kind: ActivityKind) -> PresentationConfiguration {
        compositions[kind] ?? PresentationConfiguration.default(for: kind)
    }

    private func presentation(for kind: ActivityKind, icon: ActivityIcon) -> PresentationConfiguration? {
        guard var saved = compositions[kind] else { return nil }
        saved.icon = icon
        return saved
    }

    func saveComposition(_ configuration: PresentationConfiguration, for kind: ActivityKind) {
        let normalized = PresentationComposer.normalized(configuration)
        compositions[kind] = normalized
        let stored = Dictionary(uniqueKeysWithValues: compositions.map { ($0.key.rawValue, $0.value) })
        do {
            try store.save(stored, forKey: StoreKey.compositions)
            message = copy.savedLayout(for: kind)
        } catch {
            message = copy.customizationSaveFailed
        }
    }

    private func localizedMessage(for error: Error) -> String {
        if let liveActivityError = error as? LiveActivityError,
           let description = liveActivityError.errorDescription {
            return description
        }
        if let error = error as? TimerValidationError {
            return copy.errorMessage(code: "timer.\(String(describing: error))") ?? error.localizedDescription
        }
        if let error = error as? TimerActionError {
            return copy.errorMessage(code: "timer.\(String(describing: error))") ?? error.localizedDescription
        }
        if let error = error as? TravelValidationError {
            return copy.errorMessage(code: "travel.\(String(describing: error))") ?? error.localizedDescription
        }
        return error.localizedDescription
    }
}
