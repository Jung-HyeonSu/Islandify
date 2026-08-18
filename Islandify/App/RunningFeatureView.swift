import SwiftUI

struct RunningFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var name = "Morning run"
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
        .onAppear { model.refresh() }
    }

    private var runForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Running", systemImage: "figure.run")
                .font(.title2.weight(.semibold))

            Text("Location is requested only when you start a run. If access is denied, elapsed time still works as a time-only run.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField("Run name", text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Run name")

            HStack {
                Label("Icon", systemImage: "face.smiling")
                Spacer()
                TextField("🏃", text: $iconText)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                    .accessibilityLabel("Run emoji")
            }

            Picker("Theme", selection: $theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }

            Button {
                Task { await model.startRun(name: name, theme: theme, iconText: iconText) }
            } label: {
                Label("Start run", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.activeTimer != nil || model.activeTravel != nil || model.activeRelationship != nil)
            .accessibilityHint("Starts a run and requests location access")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func activeRunCard(_ state: RunningState) -> some View {
        let snapshot = RunningCalculator.snapshot(for: state, at: model.now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Label(state.configuration.name, systemImage: state.configuration.icon.kind == .system ? state.configuration.icon.value : "figure.run")
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(state.phase.rawValue.capitalized)
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
                metric(title: "Current pace", value: IslandifyTimeFormatter.pace(secondsPerKilometer: snapshot.currentPaceSecondsPerKilometer))
                metric(title: "Average pace", value: IslandifyTimeFormatter.pace(secondsPerKilometer: snapshot.averagePaceSecondsPerKilometer))
                metric(title: "Calories", value: "\(Int(snapshot.calories.rounded())) kcal")
            }

            Text(locationMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                if state.phase == .active {
                    Button("Pause") { Task { await model.pauseRun() } }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Resume") { Task { await model.resumeRun() } }
                        .buttonStyle(.borderedProminent)
                }
                TextField("Optional memo", text: $memo)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Optional run memo")
                Button("End", role: .destructive) {
                    Task { await model.endRun(memo: memo.isEmpty ? nil : memo) }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(hex: state.configuration.theme.palette.backgroundHex), in: RoundedRectangle(cornerRadius: 20))
        .foregroundStyle(Color(hex: state.configuration.theme.palette.foregroundHex))
        .accessibilityElement(children: .contain)
    }

    private var locationMessage: String {
        switch model.locationAuthorization {
        case .authorizedWhenInUse, .authorizedAlways:
            return "GPS distance is active."
        case .notDetermined:
            return "Waiting for location permission…"
        case .denied:
            return "Location denied — recording time only."
        case .restricted:
            return "Location restricted — recording time only."
        case .unavailable:
            return "Location unavailable — recording time only."
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent runs")
                .font(.headline)
            if model.runRecords.isEmpty {
                Text("Completed runs will appear here.")
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
                        Text("\(Int(record.calories.rounded())) kcal")
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
