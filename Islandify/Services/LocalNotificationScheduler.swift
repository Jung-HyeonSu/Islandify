import Foundation
import UserNotifications

@MainActor
final class LocalNotificationScheduler {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func schedule(
        plans: [RelationshipNotificationPlan],
        timeZoneIdentifier: String
    ) async {
        guard await requestAuthorization() else { return }
        let calendar = IslandifyDateMath.calendar(timeZoneIdentifier: timeZoneIdentifier)

        for plan in plans {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: plan.date)
            let content = UNMutableNotificationContent()
            content.title = plan.title
            content.body = plan.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: plan.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func cancel(plans: [RelationshipNotificationPlan]) {
        center.removePendingNotificationRequests(withIdentifiers: plans.map(\.identifier))
    }
}
