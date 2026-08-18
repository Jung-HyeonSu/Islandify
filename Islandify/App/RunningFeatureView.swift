import SwiftUI

struct RunningFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var name = IslandifyCopy.current.runExampleName
    @State private var iconText = "🏃"
    @State private var theme: IslandifyTheme = .runningGreen
    @State private var memo = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let run = model.activeRun {
                    activeRunCard(run)
                } else {
                    runForm
                    history
                }

                if let message = model.message {
                    Label(message, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .islandifyBrightPageBackground()
        .onAppear {
            model.refresh()
            loadSavedIcon()
        }
    }

    private var runForm: some View {
        let copy = IslandifyCopy.current
        return VStack(alignment: .leading, spacing: 16) {
            Label(copy.running, systemImage: "figure.run")
                .font(.title2.weight(.semibold))

            Text(copy.runningFormDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField(copy.runName, text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(copy.runName)

            IslandifyEmojiPickerField(selection: $iconText, title: copy.icon, placeholder: "🏃")
                .accessibilityLabel(copy.runEmoji)

            Picker(copy.theme, selection: $theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(copy.themeName(theme)).tag(theme)
                }
            }

            Button {
                Task { await model.startRun(name: name, theme: theme, iconText: iconText) }
            } label: {
                Label(copy.startRun, systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.activeTimer != nil || model.activeTravel != nil || model.activeRelationship != nil)
            .accessibilityHint(copy.startRunHint)
        }
        .padding()
        .islandifyBrightCardBackground(cornerRadius: 24)
    }

    private func loadSavedIcon() {
        let saved = model.composition(for: .running)
        if saved.icon.kind == .emoji {
            iconText = saved.icon.value
        }
    }

    private func activeRunCard(_ state: RunningState) -> some View {
        let copy = IslandifyCopy.current
        let snapshot = RunningCalculator.snapshot(for: state, at: model.now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 10) {
                IslandifyAppIconView(icon: state.configuration.presentation.icon)
                    .font(.title3)
                    .frame(width: 30, height: 30)
                Text(state.configuration.name)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(copy.runningPhaseLabel(state.phase.rawValue))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(IslandifyTimeFormatter.distance(kilometers: snapshot.distanceKilometers))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Spacer()
                Text(IslandifyTimeFormatter.duration(snapshot.elapsed))
                    .font(.title3.monospacedDigit().weight(.semibold))
            }

            HStack {
                metric(title: copy.currentPace, value: IslandifyTimeFormatter.pace(secondsPerKilometer: snapshot.currentPaceSecondsPerKilometer))
                metric(title: copy.averagePace, value: IslandifyTimeFormatter.pace(secondsPerKilometer: snapshot.averagePaceSecondsPerKilometer))
                metric(title: copy.calories, value: copy.caloriesValue(Int(snapshot.calories.rounded())))
            }

            Text(locationMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                if state.phase == .active {
                    Button(copy.pause) { Task { await model.pauseRun() } }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button(copy.resume) { Task { await model.resumeRun() } }
                        .buttonStyle(.borderedProminent)
                }
                TextField(copy.optionalMemo, text: $memo)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(copy.optionalRunMemo)
                Button(copy.end, role: .destructive) {
                    Task { await model.endRun(memo: memo.isEmpty ? nil : memo) }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .islandifyBrightCardBackground(cornerRadius: 24)
        .foregroundStyle(IslandifyBrightPalette.text)
        .accessibilityElement(children: .contain)
    }

    private var locationMessage: String {
        let copy = IslandifyCopy.current
        switch model.locationAuthorization {
        case .authorizedWhenInUse, .authorizedAlways:
            return copy.gpsDistanceActive
        case .notDetermined:
            return copy.waitingForLocationPermission
        case .denied:
            return copy.locationDeniedTimeOnly
        case .restricted:
            return copy.locationRestrictedTimeOnly
        case .unavailable:
            return copy.locationUnavailableTimeOnly
        }
    }

    private var history: some View {
        let copy = IslandifyCopy.current
        return VStack(alignment: .leading, spacing: 10) {
            Text(copy.recentRuns)
                .font(.headline)
            if model.runRecords.isEmpty {
                Text(copy.completedRunsPlaceholder)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.runRecords.prefix(5)) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.name).font(.body.weight(.medium))
                            Text("\(IslandifyTimeFormatter.distance(kilometers: record.distanceMeters / 1_000)) · \(IslandifyTimeFormatter.duration(record.duration))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(copy.caloriesValue(Int(record.calories.rounded())))
                            .font(.caption.monospacedDigit())
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
