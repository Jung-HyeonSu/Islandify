import Foundation

public enum ActivityKind: String, Codable, CaseIterable, Hashable, Sendable {
    case timer
    case travel
    case relationship
    case running
}

public enum ActivityPhase: String, Codable, CaseIterable, Hashable, Sendable {
    case configured
    case active
    case paused
    case completed
    case ended
}

public struct ActivityIcon: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Hashable, Sendable {
        case system
        case emoji
    }

    public let kind: Kind
    public let value: String

    public init(systemName: String) {
        self.kind = .system
        self.value = systemName
    }

    public init(emoji: String) {
        self.kind = .emoji
        self.value = emoji
    }

    public static let flame = ActivityIcon(systemName: "flame.fill")
    public static let airplane = ActivityIcon(systemName: "airplane.departure")
    public static let heart = ActivityIcon(systemName: "heart.fill")
    public static let running = ActivityIcon(systemName: "figure.run")

    public var accessibilityLabel: String {
        kind == .emoji ? "Emoji \(value)" : value.replacingOccurrences(of: ".", with: " ")
    }
}

public enum ProgressStyle: String, Codable, CaseIterable, Hashable, Sendable {
    case bar
    case circle
    case dots
    case hidden
}

public enum NumberFormat: String, Codable, CaseIterable, Hashable, Sendable {
    case duration
    case compactDuration
    case decimal
    case pace
    case dayCount
    case distance
}

public enum SlotAlignment: String, Codable, CaseIterable, Hashable, Sendable {
    case leading
    case center
    case trailing
}

public enum PresentationSlot: String, Codable, CaseIterable, Hashable, Sendable {
    case icon
    case title
    case description
    case primaryValue
    case secondaryValue
    case progress
    case phase
}

public struct ThemePalette: Codable, Hashable, Sendable {
    public let backgroundHex: String
    public let foregroundHex: String
    public let accentHex: String
    public let secondaryHex: String
    public let contrastRatio: Double

    public init(
        backgroundHex: String,
        foregroundHex: String,
        accentHex: String,
        secondaryHex: String,
        contrastRatio: Double
    ) {
        self.backgroundHex = backgroundHex
        self.foregroundHex = foregroundHex
        self.accentHex = accentHex
        self.secondaryHex = secondaryHex
        self.contrastRatio = contrastRatio
    }

    public var isContrastSafe: Bool { contrastRatio >= 4.5 }
}

public enum IslandifyTheme: String, Codable, CaseIterable, Hashable, Sendable {
    case minimalBlack
    case pastelCouple
    case travelBlue
    case neonTimer
    case runningGreen
    case creamDiary

    public var displayName: String {
        switch self {
        case .minimalBlack: return "Minimal Black"
        case .pastelCouple: return "Pastel Couple"
        case .travelBlue: return "Travel Blue"
        case .neonTimer: return "Neon Timer"
        case .runningGreen: return "Running Green"
        case .creamDiary: return "Cream Diary"
        }
    }

    public var palette: ThemePalette {
        switch self {
        case .minimalBlack:
            return ThemePalette(backgroundHex: "#050505", foregroundHex: "#FFFFFF", accentHex: "#FFFFFF", secondaryHex: "#B7B7B7", contrastRatio: 21.0)
        case .pastelCouple:
            return ThemePalette(backgroundHex: "#3A2231", foregroundHex: "#FFF5FA", accentHex: "#FF9FC4", secondaryHex: "#EEC9D9", contrastRatio: 12.1)
        case .travelBlue:
            return ThemePalette(backgroundHex: "#082B45", foregroundHex: "#F1FAFF", accentHex: "#5ED7FF", secondaryHex: "#B5D5E5", contrastRatio: 13.7)
        case .neonTimer:
            return ThemePalette(backgroundHex: "#171225", foregroundHex: "#FFF8FF", accentHex: "#D8FF45", secondaryHex: "#D4BFF5", contrastRatio: 14.4)
        case .runningGreen:
            return ThemePalette(backgroundHex: "#102B23", foregroundHex: "#F2FFF9", accentHex: "#65E6A7", secondaryHex: "#B9D8CA", contrastRatio: 13.0)
        case .creamDiary:
            return ThemePalette(backgroundHex: "#34271D", foregroundHex: "#FFF7E8", accentHex: "#F4C77D", secondaryHex: "#E4CDB0", contrastRatio: 12.0)
        }
    }
}

public struct PresentationConfiguration: Codable, Hashable, Sendable {
    public var title: String
    public var description: String
    public var icon: ActivityIcon
    public var theme: IslandifyTheme
    public var numberFormat: NumberFormat
    public var progressStyle: ProgressStyle
    public var alignment: SlotAlignment
    public var compactLeading: PresentationSlot
    public var compactTrailing: PresentationSlot
    public var expandedDetails: [PresentationSlot]
    public var completionMessage: String

    public init(
        title: String,
        description: String = "",
        icon: ActivityIcon,
        theme: IslandifyTheme,
        numberFormat: NumberFormat,
        progressStyle: ProgressStyle,
        alignment: SlotAlignment = .leading,
        compactLeading: PresentationSlot = .icon,
        compactTrailing: PresentationSlot = .primaryValue,
        expandedDetails: [PresentationSlot] = [.title, .primaryValue, .progress],
        completionMessage: String = "Done"
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.theme = theme
        self.numberFormat = numberFormat
        self.progressStyle = progressStyle
        self.alignment = alignment
        self.compactLeading = compactLeading
        self.compactTrailing = compactTrailing
        self.expandedDetails = expandedDetails
        self.completionMessage = completionMessage
    }

    public static func `default`(for kind: ActivityKind) -> PresentationConfiguration {
        switch kind {
        case .timer:
            return PresentationConfiguration(title: "Focus", icon: .flame, theme: .neonTimer, numberFormat: .compactDuration, progressStyle: .bar, completionMessage: "Focus complete")
        case .travel:
            return PresentationConfiguration(title: "Trip", icon: .airplane, theme: .travelBlue, numberFormat: .dayCount, progressStyle: .hidden, completionMessage: "Have a great trip")
        case .relationship:
            return PresentationConfiguration(title: "Together", icon: .heart, theme: .pastelCouple, numberFormat: .dayCount, progressStyle: .dots, completionMessage: "Another day together")
        case .running:
            return PresentationConfiguration(title: "Run", icon: .running, theme: .runningGreen, numberFormat: .distance, progressStyle: .bar, completionMessage: "Run complete")
        }
    }
}

public struct ActivityPresentationState: Codable, Hashable, Sendable {
    public var kind: ActivityKind
    public var phase: ActivityPhase
    public var title: String
    public var description: String
    public var icon: ActivityIcon
    public var palette: ThemePalette
    public var primaryValue: String
    public var secondaryValue: String?
    public var progress: Double?
    public var compactLeading: String
    public var compactTrailing: String
    public var expandedDetails: [String]
    public var completionMessage: String
    public var accessibilityLabel: String
    public var staleDate: Date?
    public var countdownEndDate: Date?

    public init(
        kind: ActivityKind,
        phase: ActivityPhase,
        title: String,
        description: String = "",
        icon: ActivityIcon,
        palette: ThemePalette,
        primaryValue: String,
        secondaryValue: String? = nil,
        progress: Double? = nil,
        compactLeading: String,
        compactTrailing: String,
        expandedDetails: [String] = [],
        completionMessage: String = "Done",
        accessibilityLabel: String? = nil,
        staleDate: Date? = nil,
        countdownEndDate: Date? = nil
    ) {
        self.kind = kind
        self.phase = phase
        self.title = title
        self.description = description
        self.icon = icon
        self.palette = palette
        self.primaryValue = primaryValue
        self.secondaryValue = secondaryValue
        self.progress = progress.map { min(max($0, 0), 1) }
        self.compactLeading = compactLeading
        self.compactTrailing = compactTrailing
        self.expandedDetails = expandedDetails
        self.completionMessage = completionMessage
        self.accessibilityLabel = accessibilityLabel ?? [title, primaryValue, secondaryValue].compactMap { $0 }.joined(separator: ", ")
        self.staleDate = staleDate
        self.countdownEndDate = countdownEndDate
    }

    public var isTerminal: Bool {
        phase == .completed || phase == .ended
    }
}

public enum ActivitySurface: String, Codable, CaseIterable, Hashable, Sendable {
    case compact
    case minimal
    case expanded
    case lockScreen
}

public struct ActivitySurfaceModel: Hashable, Sendable {
    public let surface: ActivitySurface
    public let leadingText: String?
    public let trailingText: String?
    public let primaryText: String
    public let secondaryText: String?
    public let details: [String]
    public let accessibilityLabel: String

    public init(
        surface: ActivitySurface,
        leadingText: String? = nil,
        trailingText: String? = nil,
        primaryText: String,
        secondaryText: String? = nil,
        details: [String] = [],
        accessibilityLabel: String
    ) {
        self.surface = surface
        self.leadingText = leadingText
        self.trailingText = trailingText
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.details = details
        self.accessibilityLabel = accessibilityLabel
    }
}

public enum ActivityPresentationRenderer {
    public static func render(_ state: ActivityPresentationState, on surface: ActivitySurface) -> ActivitySurfaceModel {
        switch surface {
        case .compact:
            return ActivitySurfaceModel(
                surface: surface,
                leadingText: truncate(state.compactLeading, limit: 10),
                trailingText: truncate(state.compactTrailing, limit: 10),
                primaryText: truncate(state.primaryValue, limit: 12),
                secondaryText: state.secondaryValue.map { truncate($0, limit: 18) },
                accessibilityLabel: state.accessibilityLabel
            )
        case .minimal:
            return ActivitySurfaceModel(
                surface: surface,
                primaryText: truncate(state.compactTrailing, limit: 8),
                secondaryText: state.secondaryValue.map { truncate($0, limit: 12) },
                accessibilityLabel: state.accessibilityLabel
            )
        case .expanded:
            let details = state.expandedDetails.isEmpty ? [state.title, state.primaryValue] : state.expandedDetails
            return ActivitySurfaceModel(
                surface: surface,
                leadingText: truncate(state.title, limit: 24),
                trailingText: truncate(state.phase.rawValue.capitalized, limit: 12),
                primaryText: truncate(state.primaryValue, limit: 24),
                secondaryText: state.secondaryValue.map { truncate($0, limit: 24) },
                details: details.map { truncate($0, limit: 28) },
                accessibilityLabel: state.accessibilityLabel
            )
        case .lockScreen:
            let details = [state.description, state.secondaryValue].compactMap { $0 }.filter { !$0.isEmpty }
            return ActivitySurfaceModel(
                surface: surface,
                leadingText: truncate(state.title, limit: 32),
                primaryText: truncate(state.primaryValue, limit: 32),
                secondaryText: state.phase == .completed ? state.completionMessage : state.secondaryValue,
                details: details.map { truncate($0, limit: 40) },
                accessibilityLabel: state.accessibilityLabel
            )
        }
    }

    private static func truncate(_ value: String, limit: Int) -> String {
        guard value.count > limit else { return value }
        let end = value.index(value.startIndex, offsetBy: max(0, limit - 1))
        return String(value[..<end]) + "…"
    }
}
