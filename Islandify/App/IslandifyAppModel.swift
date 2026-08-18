import Foundation
import SwiftUI

@MainActor
final class IslandifyAppModel: ObservableObject {
    @Published private(set) var activeTimer: TimerState?
    @Published private(set) var now = Date.now
    @Published var message: String?

    private let store: JSONLocalStore
    private let activityManager: LiveActivityManager
    private var displayTimer: Timer?

    private enum StoreKey {
        static let activeTimer = "active-timer"
    }

    init() {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = applicationSupport.appendingPathComponent("Islandify", isDirectory: true)
        self.store = JSONLocalStore(directoryURL: directory)
        self.activityManager = LiveActivityManager()

        loadTimer()
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
        guard let activeTimer else { return }
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

    func startTimer(
        name: String,
        durationMinutes: Int,
        iconText: String,
        theme: IslandifyTheme,
        alertSound: TimerAlertSound,
        progressStyle: ProgressStyle,
        autoEnd: Bool
    ) async {
        guard activeTimer == nil else {
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

    private func persistTimer() {
        guard let activeTimer else { return }
        do {
            try store.save(activeTimer, forKey: StoreKey.activeTimer)
        } catch {
            message = "Timer could not be saved on this device."
        }
    }
}
