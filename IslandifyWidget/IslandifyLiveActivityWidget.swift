import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct IslandifyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IslandifyActivityAttributes.self) { context in
            IslandifyLockScreenView(state: context.state.presentation)
        } dynamicIsland: { context in
            let state = context.state.presentation
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandifyIconView(icon: state.icon)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.title)
                            .font(.headline)
                            .lineLimit(1)
                        IslandifyDynamicValue(state: state)
                            .font(.title3.monospacedDigit().weight(.semibold))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(state.compactTrailing)
                        .font(.caption.monospacedDigit())
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        IslandifyProgressView(state: state)
                        HStack {
                            IslandifyElapsedValue(state: state)
                            Text(state.description)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(state.phase.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                IslandifyCompactText(state.compactLeading, icon: state.icon)
            } compactTrailing: {
                IslandifyDynamicValue(state: state)
                    .font(.caption2.monospacedDigit().weight(.semibold))
            } minimal: {
                IslandifyCompactText(state.compactTrailing, icon: state.icon)
            }
            .widgetURL(URL(string: "islandify://activity/\(context.attributes.activityID.uuidString)"))
            .keylineTint(Color(hex: state.palette.accentHex))
        }
    }
}

@available(iOS 16.1, *)
private struct IslandifyLockScreenView: View {
    let state: ActivityPresentationState

    var body: some View {
        HStack(spacing: 12) {
            IslandifyIconView(icon: state.icon)
            VStack(alignment: .leading, spacing: 3) {
                Text(state.title)
                    .font(.headline)
                    .lineLimit(1)
                IslandifyDynamicValue(state: state)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .lineLimit(1)
                if let secondaryValue = state.secondaryValue, !secondaryValue.isEmpty {
                    Text(secondaryValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                IslandifyProgressView(state: state)
                IslandifyElapsedValue(state: state)
            }
            Spacer(minLength: 8)
            Text(state.phase == .completed ? state.completionMessage : state.compactTrailing)
                .font(.caption.monospacedDigit())
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.accessibilityLabel)
    }
}

@available(iOS 16.1, *)
private struct IslandifyDynamicValue: View {
    let state: ActivityPresentationState

    var body: some View {
        if let endDate = state.countdownEndDate, state.phase == .active {
            Text(timerInterval: Date()...endDate, countsDown: true)
                .accessibilityLabel(state.accessibilityLabel)
        } else {
            Text(state.primaryValue)
                .accessibilityLabel(state.accessibilityLabel)
        }
    }
}

@available(iOS 16.1, *)
private struct IslandifyProgressView: View {
    let state: ActivityPresentationState

    @ViewBuilder
    var body: some View {
        if let progress = state.progress, state.progressStyle != .hidden {
            switch state.progressStyle {
            case .bar:
                ProgressView(value: progress)
                    .tint(Color(hex: state.palette.accentHex))
            case .circle:
                ProgressView(value: progress)
                    .progressViewStyle(.circular)
            case .dots:
                let filled = Int((progress * 5).rounded())
                Text(String(repeating: "●", count: filled) + String(repeating: "○", count: max(0, 5 - filled)))
                    .font(.caption2)
            case .hidden:
                EmptyView()
            }
        }
    }
}

@available(iOS 16.1, *)
private struct IslandifyElapsedValue: View {
    let state: ActivityPresentationState

    @ViewBuilder
    var body: some View {
        if state.kind == .running, let startDate = state.countupStartDate, state.phase == .active {
            Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
                .font(.caption.monospacedDigit())
                .lineLimit(1)
                .accessibilityLabel("Elapsed time")
        }
    }
}

@available(iOS 16.1, *)
private struct IslandifyIconView: View {
    let icon: ActivityIcon

    var body: some View {
        Group {
            if icon.kind == .emoji {
                Text(icon.value)
            } else {
                Image(systemName: icon.value)
            }
        }
        .font(.headline)
        .frame(minWidth: 24, minHeight: 24)
        .accessibilityHidden(true)
    }
}

@available(iOS 16.1, *)
private struct IslandifyCompactText: View {
    let value: String
    let icon: ActivityIcon

    var body: some View {
        Group {
            if icon.kind == .emoji {
                Text(icon.value)
            } else {
                Image(systemName: icon.value)
            }
        }
        .font(.caption2)
        .accessibilityLabel(value)
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
