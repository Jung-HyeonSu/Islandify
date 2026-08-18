import Foundation
import SwiftUI

@MainActor
final class IslandifyAppModel: ObservableObject {
    @Published private(set) var activeTimer: TimerState?
    @Published private(set) var activeTravel: TravelConfiguration?
    @Published private(set) var now = Date.now
    @Published var message: String?

    private let store: JSONLocalStore
    private let activityManager: LiveActivityManager
    private var displayTimer: Timer?
    private var lastTravelKind: TravelStateKind?

    private enum StoreKey {
        static let activeTimer = "active-timer"
        static let activeTravel = "active-travel"
    }

    init() {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = applicationSupport.appendingPathComponent("Islandify", isDirectory: true)
        self.store = JSONLocalStore(directoryURL: directory)
        self.activityManager = LiveActivityManager()

        loadTimer()
        loadTravel()
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
        guard activeTimer == nil && activeTravel == nil else {
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
                autoEnd: autoEnd
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
        guard activeTimer == nil && activeTravel == nil else {
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
                theme: theme
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
}
