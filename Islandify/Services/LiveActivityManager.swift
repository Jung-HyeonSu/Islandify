import ActivityKit
import Foundation

@available(iOS 16.1, *)
enum LiveActivityError: LocalizedError, Equatable {
    case activitiesDisabled
    case duplicateActivity
    case noActiveActivity

    var errorDescription: String? {
        switch self {
        case .activitiesDisabled:
            return "Live Activities are disabled. The timer will still remain available in the app."
        case .duplicateActivity:
            return "An Islandify activity is already running. End it before starting another one."
        case .noActiveActivity:
            return "There is no active Live Activity to update."
        }
    }
}

@available(iOS 16.1, *)
@MainActor
final class LiveActivityManager {
    private var currentActivity: Activity<IslandifyActivityAttributes>?

    var activitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    init() {
        reconcile()
    }

    func reconcile() {
        currentActivity = Activity<IslandifyActivityAttributes>.activities.first {
            $0.activityState == .active
        }
    }

    func start(presentation: ActivityPresentationState) async throws {
        guard activitiesEnabled else { throw LiveActivityError.activitiesDisabled }
        reconcile()
        guard currentActivity == nil else { throw LiveActivityError.duplicateActivity }

        let attributes = IslandifyActivityAttributes(kind: presentation.kind)
        let state = IslandifyActivityAttributes.ContentState(presentation: presentation)
        if #available(iOS 16.2, *) {
            let content = ActivityContent(state: state, staleDate: presentation.staleDate)
            currentActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } else {
            currentActivity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
        }
    }

    func update(presentation: ActivityPresentationState) async throws {
        reconcile()
        guard let currentActivity else { throw LiveActivityError.noActiveActivity }
        let state = IslandifyActivityAttributes.ContentState(presentation: presentation)
        if #available(iOS 16.2, *) {
            let content = ActivityContent(state: state, staleDate: presentation.staleDate)
            await currentActivity.update(content)
        } else {
            await currentActivity.update(using: state)
        }
    }

    func end(presentation: ActivityPresentationState) async {
        reconcile()
        guard let currentActivity else { return }
        let state = IslandifyActivityAttributes.ContentState(presentation: presentation)
        if #available(iOS 16.2, *) {
            let content = ActivityContent(state: state, staleDate: Date())
            await currentActivity.end(content, dismissalPolicy: .default)
        } else {
            await currentActivity.end(using: state, dismissalPolicy: .default)
        }
        self.currentActivity = nil
    }
}
