import Foundation

public enum IslandifyTimeFormatter {
    public static func duration(_ seconds: TimeInterval, includeHours: Bool? = nil) -> String {
        let rounded = max(0, Int(seconds.rounded(.down)))
        let hours = rounded / 3_600
        let minutes = (rounded % 3_600) / 60
        let secondsPart = rounded % 60
        let shouldIncludeHours = includeHours ?? (hours > 0)
        if shouldIncludeHours {
            return String(format: "%02d:%02d:%02d", hours, minutes, secondsPart)
        }
        return String(format: "%02d:%02d", minutes, secondsPart)
    }

    public static func compactDuration(_ seconds: TimeInterval) -> String {
        duration(seconds, includeHours: seconds >= 3_600)
    }

    public static func pace(secondsPerKilometer: TimeInterval?) -> String {
        guard let secondsPerKilometer, secondsPerKilometer.isFinite, secondsPerKilometer > 0 else {
            return "— /km"
        }
        return "\(duration(secondsPerKilometer))/km"
    }

    public static func dayCount(_ value: Int) -> String {
        value >= 0 ? "D+\(value)" : "D\(value)"
    }

    public static func distance(kilometers: Double) -> String {
        String(format: "%.2f km", max(0, kilometers))
    }

    public static func decimal(_ value: Double, fractionDigits: Int = 1) -> String {
        String(format: "%.*f", fractionDigits, value)
    }
}
