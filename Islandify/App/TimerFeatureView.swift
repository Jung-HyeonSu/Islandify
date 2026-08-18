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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let activeTimer = model.activeTimer {
                    activeTimerCard(activeTimer)
                } else {
                    timerForm
                }

                if let message = model.message {
                    Label(message, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(message)
                }
            }
            .padding()
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .onAppear { model.refresh() }
        .onChange(of: model.activeTimer?.phase) { _ in model.refresh() }
    }

    private var timerForm: some View {
        let copy = IslandifyCopy.current
        return VStack(alignment: .leading, spacing: 16) {
            Label(copy.timer, systemImage: "timer")
                .font(.title2.weight(.semibold))

            Text(copy.timerFormDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField(copy.name, text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(copy.timerName)

            HStack {
                Label(copy.duration, systemImage: "clock")
                Spacer()
                Stepper(value: $durationMinutes, in: 1...480) {
                    Text(copy.durationMinutes(durationMinutes))
                        .monospacedDigit()
                }
                .accessibilityLabel(copy.durationAccessibility(minutes: durationMinutes))
            }

            HStack {
                Label(copy.icon, systemImage: "face.smiling")
                Spacer()
                TextField("🔥", text: $iconText)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 72)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(copy.timerEmoji)
            }

            Picker(copy.theme, selection: $theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(copy.themeName(theme)).tag(theme)
                }
            }

            Picker(copy.alertSound, selection: $alertSound) {
                ForEach(TimerAlertSound.allCases, id: \.self) { sound in
                    Text(copy.alertSoundName(sound.rawValue)).tag(sound)
                }
            }

            Picker(copy.progress, selection: $progressStyle) {
                ForEach(ProgressStyle.allCases, id: \.self) { style in
                    Text(copy.progressStyleName(style)).tag(style)
                }
            }

            Toggle(copy.endLiveActivityWhenComplete, isOn: $autoEnd)

            Button {
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
            } label: {
                Label(copy.startTimer, systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(copy.startTimerHint)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func activeTimerCard(_ state: TimerState) -> some View {
        let copy = IslandifyCopy.current
        let snapshot = TimerEngine.snapshot(for: state, at: model.now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Label(state.configuration.name, systemImage: state.configuration.icon.kind == .system ? state.configuration.icon.value : "face.smiling")
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(copy.phaseLabel(state.phase))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(IslandifyTimeFormatter.duration(snapshot.remaining))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityLabel(copy.timerRemaining(
                    name: state.configuration.name,
                    value: IslandifyTimeFormatter.duration(snapshot.remaining)
                ))

            ProgressView(value: snapshot.progress)
                .tint(Color(hex: state.configuration.theme.palette.accentHex))
                .accessibilityValue(copy.progressPercent(Int(snapshot.progress * 100)))

            HStack {
                if state.phase == .active {
                    Button(copy.pause) { Task { await model.pauseTimer() } }
                        .buttonStyle(.borderedProminent)
                } else if state.phase == .paused {
                    Button(copy.resume) { Task { await model.resumeTimer() } }
                        .buttonStyle(.borderedProminent)
                } else if state.phase == .completed {
                    Text(state.configuration.presentation.completionMessage)
                        .font(.headline)
                }

                Button(copy.addMinute) { Task { await model.addMinute() } }
                    .buttonStyle(.bordered)
                    .disabled(state.phase == .completed || state.phase == .ended)

                Menu {
                    Button(copy.reset, role: .destructive) { Task { await model.resetTimer() } }
                    Button(copy.end, role: .destructive) { Task { await model.endTimer() } }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel(copy.moreTimerActions)
                }
            }
        }
        .padding()
        .background(Color(hex: state.configuration.theme.palette.backgroundHex), in: RoundedRectangle(cornerRadius: 20))
        .foregroundStyle(Color(hex: state.configuration.theme.palette.foregroundHex))
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
