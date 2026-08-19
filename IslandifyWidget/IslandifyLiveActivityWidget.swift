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
            return DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            IslandifyIconView(icon: state.icon, tint: IslandifyActivityAccent.color(for: state.kind))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(state.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                if !state.description.isEmpty {
                                    Text(state.description)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 4)
                            IslandifyDynamicValue(state: state)
                                .font(.body.monospacedDigit().weight(.semibold))
                                .lineLimit(1)
                        }
                        IslandifyProgressView(state: state)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                IslandifyCompactText(value: state.compactLeading, icon: state.icon)
                    .frame(maxWidth: 32)
            } compactTrailing: {
                IslandifyDynamicValue(state: state)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } minimal: {
                IslandifyCompactText(value: state.icon.value, icon: state.icon)
                    .frame(maxWidth: 32)
            }
            .widgetURL(URL(string: "islandify://activity/\(context.attributes.activityID.uuidString)"))
            .keylineTint(IslandifyActivityAccent.color(for: state.kind))
        }
    }
}

@available(iOS 16.1, *)
private struct IslandifyLockScreenView: View {
    let state: ActivityPresentationState

    var body: some View {
        HStack(spacing: 12) {
            IslandifyIconView(icon: state.icon, tint: IslandifyActivityAccent.color(for: state.kind))
            VStack(alignment: .leading, spacing: 3) {
                Text(state.title)
                    .font(.headline)
                    .lineLimit(1)
                if !state.description.isEmpty {
                    Text(state.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
        .padding(14)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(IslandifyActivityAccent.color(for: state.kind).opacity(0.22), lineWidth: 1)
        }
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

    private var accent: Color {
        IslandifyActivityAccent.color(for: state.kind)
    }

    @ViewBuilder
    var body: some View {
        if let progress = state.progress, state.progressStyle != .hidden {
            switch state.progressStyle {
            case .bar:
                ProgressView(value: progress)
                    .tint(accent)
            case .circle:
                ProgressView(value: progress)
                    .progressViewStyle(.circular)
                    .tint(accent)
            case .dots:
                let filled = Int((progress * 5).rounded())
                Text(String(repeating: "●", count: filled) + String(repeating: "○", count: max(0, 5 - filled)))
                    .font(.caption2)
                    .foregroundStyle(accent)
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
                .accessibilityLabel(IslandifyCopy.current.elapsedTime)
        }
    }
}

@available(iOS 16.1, *)
private struct IslandifyIconView: View {
    let icon: ActivityIcon
    var tint: Color?

    var body: some View {
        Group {
            if icon.kind == .emoji {
                Text(icon.value)
            } else {
                Image(systemName: icon.value)
            }
        }
        .font(.headline)
        .foregroundStyle(tint ?? .primary)
        .frame(minWidth: 24, minHeight: 24)
        .accessibilityHidden(true)
    }
}

private enum IslandifyActivityAccent {
    static func color(for kind: ActivityKind) -> Color {
        switch kind {
        case .timer:
            return Color(red: 0.22, green: 0.62, blue: 0.96)
        case .travel:
            return Color(red: 0.52, green: 0.49, blue: 0.92)
        case .relationship:
            return Color(red: 0.91, green: 0.46, blue: 0.82)
        case .running:
            return Color(red: 0.32, green: 0.74, blue: 0.70)
        }
    }
}

@available(iOS 16.1, *)
private struct IslandifyCompactText: View {
    let value: String
    let icon: ActivityIcon

    var body: some View {
        Group {
            if value == icon.value, icon.kind == .emoji {
                Text(icon.value)
            } else if value == icon.value, icon.kind == .system {
                Image(systemName: icon.value)
            } else {
                Text(value)
            }
        }
        .font(.caption2)
        .accessibilityLabel(value)
    }
}
