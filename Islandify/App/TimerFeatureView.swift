import SwiftUI

struct TimerFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var name = "Deep focus"
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
        VStack(alignment: .leading, spacing: 16) {
            Label("Timer", systemImage: "timer")
                .font(.title2.weight(.semibold))

            Text("Keep the source of truth on an absolute end date so the timer stays correct after suspension.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Timer name")

            HStack {
                Label("Duration", systemImage: "clock")
                Spacer()
                Stepper(value: $durationMinutes, in: 1...480) {
                    Text("\(durationMinutes) min")
                        .monospacedDigit()
                }
                .accessibilityLabel("Duration, \(durationMinutes) minutes")
            }

            HStack {
                Label("Icon", systemImage: "face.smiling")
                Spacer()
                TextField("🔥", text: $iconText)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 72)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Timer emoji")
            }

            Picker("Theme", selection: $theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }

            Picker("Alert sound", selection: $alertSound) {
                ForEach(TimerAlertSound.allCases, id: \.self) { sound in
                    Text(sound.rawValue.capitalized).tag(sound)
                }
            }

            Picker("Progress", selection: $progressStyle) {
                ForEach(ProgressStyle.allCases, id: \.self) { style in
                    Text(style.rawValue.capitalized).tag(style)
                }
            }

            Toggle("End Live Activity when complete", isOn: $autoEnd)

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
                Label("Start timer", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Starts the timer and requests a Live Activity if it is enabled")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func activeTimerCard(_ state: TimerState) -> some View {
        let snapshot = TimerEngine.snapshot(for: state, at: model.now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Label(state.configuration.name, systemImage: state.configuration.icon.kind == .system ? state.configuration.icon.value : "face.smiling")
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(state.phase.rawValue.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(IslandifyTimeFormatter.duration(snapshot.remaining))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityLabel("\(state.configuration.name), \(IslandifyTimeFormatter.duration(snapshot.remaining)) remaining")

            ProgressView(value: snapshot.progress)
                .tint(Color(hex: state.configuration.theme.palette.accentHex))
                .accessibilityValue("\(Int(snapshot.progress * 100)) percent")

            HStack {
                if state.phase == .active {
                    Button("Pause") { Task { await model.pauseTimer() } }
                        .buttonStyle(.borderedProminent)
                } else if state.phase == .paused {
                    Button("Resume") { Task { await model.resumeTimer() } }
                        .buttonStyle(.borderedProminent)
                } else if state.phase == .completed {
                    Text(state.configuration.presentation.completionMessage)
                        .font(.headline)
                }

                Button("+1 min") { Task { await model.addMinute() } }
                    .buttonStyle(.bordered)
                    .disabled(state.phase == .completed || state.phase == .ended)

                Menu {
                    Button("Reset", role: .destructive) { Task { await model.resetTimer() } }
                    Button("End", role: .destructive) { Task { await model.endTimer() } }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("More timer actions")
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
