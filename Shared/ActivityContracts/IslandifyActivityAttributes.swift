#if canImport(ActivityKit)
import ActivityKit
import Foundation

@available(iOS 16.1, *)
public struct IslandifyActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var presentation: ActivityPresentationState
        public var updatedAt: Date

        public init(presentation: ActivityPresentationState, updatedAt: Date = .now) {
            self.presentation = presentation
            self.updatedAt = updatedAt
        }
    }

    public let activityID: UUID
    public let kind: ActivityKind

    public init(activityID: UUID = UUID(), kind: ActivityKind) {
        self.activityID = activityID
        self.kind = kind
    }
}
#endif
