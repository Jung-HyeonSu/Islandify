import Foundation

public struct PreviewActivity: Codable, Hashable, Sendable {
    public let title: String
    public let subtitle: String
    public let primaryValue: String

    public init(title: String, subtitle: String, primaryValue: String) {
        self.title = title
        self.subtitle = subtitle
        self.primaryValue = primaryValue
    }

    public static let sample = PreviewActivity(
        title: "Deep focus",
        subtitle: "Preview activity",
        primaryValue: "24:58"
    )
}
