import SwiftUI

struct TimerFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var name = IslandifyCopy.current.timerExampleName
    @State private var durationMinutes = 25
    @State private var iconText = "🔥"
    @State private var theme: IslandifyTheme = .neonTimer
    @State private var alertSound: TimerAlertSound = .chime
    @State private var progressStyle: ProgressStyle = .bar
    @State private var autoEnd = true

    var body: some View {
        let copy = IslandifyCopy.current
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                IslandifyPageHeader(
                    eyebrow: copy.timer,
                    title: model.activeTimer?.configuration.name ?? copy.timerExampleName,
                    subtitle: copy.timerFormDescription,
                    symbolName: "timer"
                )

                if let activeTimer = model.activeTimer {
                    activeTimerCard(activeTimer)
                } else {
                    timerForm
                }

                if let message = model.message {
                    IslandifyMessageBanner(message: message)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .islandifyBrightPageBackground()
        .tint(IslandifyBrightPalette.lavender)
        .onAppear {
            model.refresh()
            loadSavedIcon()
        }
        .onChange(of: model.activeTimer?.phase) { _ in model.refresh() }
        .accessibilityIdentifier("timer-feature")
    }

    private var timerForm: some View {
        let copy = IslandifyCopy.current
        return IslandifyBrightCard(padding: 20, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 15) {
                Text(copy.timer)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.text)

                TextField(copy.name, text: $name)
                    .textFieldStyle(.plain)
                    .islandifyInputStyle()
                    .accessibilityLabel(copy.timerName)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(copy.duration)
                            .font(.subheadline.weight(.medium))
                        Text(copy.durationMinutes(durationMinutes))
                            .font(.title3.monospacedDigit().weight(.semibold))
                            .foregroundStyle(IslandifyBrightPalette.lavender)
                    }
                    .foregroundStyle(IslandifyBrightPalette.text)
                    Spacer()
                    Stepper("", value: $durationMinutes, in: 1...480)
                        .labelsHidden()
                        .tint(IslandifyBrightPalette.lavender)
                        .accessibilityLabel(copy.durationAccessibility(minutes: durationMinutes))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(IslandifyBrightPalette.surfaceSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                IslandifyEmojiPickerField(selection: $iconText, title: copy.icon, placeholder: "🔥")
                    .accessibilityLabel(copy.timerEmoji)

                IslandifyPickerRow(
                    title: copy.theme,
                    selection: $theme,
                    options: IslandifyTheme.allCases.map { IslandifyPickerOption(value: $0, title: copy.themeName($0)) }
                )
                IslandifyPickerRow(
                    title: copy.alertSound,
                    selection: $alertSound,
                    options: TimerAlertSound.allCases.map { IslandifyPickerOption(value: $0, title: copy.alertSoundName($0.rawValue)) }
                )
                IslandifyPickerRow(
                    title: copy.progress,
                    selection: $progressStyle,
                    options: ProgressStyle.allCases.map { IslandifyPickerOption(value: $0, title: copy.progressStyleName($0)) }
                )

                Toggle(copy.endLiveActivityWhenComplete, isOn: $autoEnd)
                    .font(.subheadline.weight(.medium))
                    .tint(IslandifyBrightPalette.lavender)

                IslandifyGradientButton(title: copy.startTimer) {
                    Task {
                        await model.startTimer(
                            name: name,
                            durationMinutes: durationMinutes,
                            iconText: iconText,
                            theme: theme,
                            alertSound: alertSound,
                            progressStyle: progressStyle,
                            autoEnd: autoEnd
                        )
                    }
                }
                .accessibilityHint(copy.startTimerHint)
            }
        }
    }

    private func loadSavedIcon() {
        let saved = model.composition(for: .timer)
        if saved.icon.kind == .emoji {
            iconText = saved.icon.value
        }
    }

    private func activeTimerCard(_ state: TimerState) -> some View {
        let copy = IslandifyCopy.current
        let snapshot = TimerEngine.snapshot(for: state, at: model.now)
        let actionTitle: String? = state.phase == .active ? copy.pause : state.phase == .paused ? copy.resume : nil
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                IslandifyAppIconView(icon: state.configuration.presentation.icon)
                    .font(.title3)
                    .frame(width: 38, height: 38)
                    .background(IslandifyBrightPalette.lavender.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.configuration.name)
                        .font(.headline.weight(.semibold))
                    Text(copy.phaseLabel(state.phase))
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
                Spacer()
                Text(copy.phaseLabel(state.phase))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.lavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(IslandifyBrightPalette.lavender.opacity(0.11), in: Capsule())
            }

            IslandifyHeroCard(
                eyebrow: copy.timer,
                value: IslandifyTimeFormatter.duration(snapshot.remaining),
                detail: copy.progressPercent(Int((snapshot.progress * 100).rounded())),
                progress: snapshot.progress
            )
            .accessibilityLabel(copy.timerRemaining(name: state.configuration.name, value: IslandifyTimeFormatter.duration(snapshot.remaining)))

            IslandifyBrightCard(padding: 14, cornerRadius: 22) {
                HStack(spacing: 10) {
                    if let actionTitle {
                        Button(actionTitle) {
                            Task {
                                if state.phase == .active { await model.pauseTimer() } else { await model.resumeTimer() }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(IslandifyBrightPalette.lavender)
                    }

                    Button(copy.addMinute) { Task { await model.addMinute() } }
                        .buttonStyle(.bordered)
                        .tint(IslandifyBrightPalette.lavender)
                        .disabled(state.phase == .completed || state.phase == .ended)

                    Spacer(minLength: 0)
                    Menu {
                        Button(copy.reset, role: .destructive) { Task { await model.resetTimer() } }
                        Button(copy.end, role: .destructive) { Task { await model.endTimer() } }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body.weight(.bold))
                            .foregroundStyle(IslandifyBrightPalette.secondaryText)
                            .frame(width: 38, height: 38)
                            .background(IslandifyBrightPalette.surfaceSoft, in: Circle())
                    }
                    .accessibilityLabel(copy.moreTimerActions)
                }
            }

            if state.phase == .completed {
                Text(state.configuration.presentation.completionMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.lavender)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .foregroundStyle(IslandifyBrightPalette.text)
    }
}

#Preview {
    TimerFeatureView()
        .environmentObject(IslandifyAppModel())
}
