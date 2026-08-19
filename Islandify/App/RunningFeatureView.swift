import SwiftUI

struct RunningFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var name = IslandifyCopy.current.runExampleName
    @State private var iconText = "🏃"
    @State private var theme: IslandifyTheme = .runningGreen
    @State private var memo = ""

    var body: some View {
        let copy = IslandifyCopy.current
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                IslandifyPageHeader(
                    eyebrow: copy.running,
                    title: model.activeRun?.configuration.name ?? copy.runExampleName,
                    subtitle: copy.runningDescription,
                    symbolName: "figure.run"
                )

                if let run = model.activeRun {
                    activeRunCard(run)
                } else {
                    runForm
                    history
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
        .tint(IslandifyBrightPalette.mint)
        .onAppear {
            model.refresh()
            loadSavedIcon()
        }
        .accessibilityIdentifier("running-feature")
    }

    private var runForm: some View {
        let copy = IslandifyCopy.current
        return IslandifyBrightCard(padding: 20, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 15) {
                Text(copy.running)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.text)

                TextField(copy.runName, text: $name)
                    .textFieldStyle(.plain)
                    .islandifyInputStyle()
                    .accessibilityLabel(copy.runName)

                IslandifyEmojiPickerField(selection: $iconText, title: copy.icon, placeholder: "🏃")
                    .accessibilityLabel(copy.runEmoji)

                IslandifyPickerRow(
                    title: copy.theme,
                    selection: $theme,
                    options: IslandifyTheme.allCases.map { IslandifyPickerOption(value: $0, title: copy.themeName($0)) }
                )

                IslandifyGradientButton(title: copy.startRun) {
                    Task { await model.startRun(name: name, theme: theme, iconText: iconText) }
                }
                .disabled(model.activeTimer != nil || model.activeTravel != nil || model.activeRelationship != nil)
                .accessibilityHint(copy.startRunHint)
            }
        }
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
            HStack(spacing: 10) {
                IslandifyAppIconView(icon: state.configuration.presentation.icon)
                    .font(.title3)
                    .frame(width: 38, height: 38)
                    .background(IslandifyBrightPalette.mint.opacity(0.13), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.configuration.name)
                        .font(.headline.weight(.semibold))
                    Text(copy.runningPhaseLabel(state.phase.rawValue))
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
                Spacer()
                Menu {
                    Button(copy.end, role: .destructive) { Task { await model.endRun(memo: memo.isEmpty ? nil : memo) } }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.bold))
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                        .frame(width: 38, height: 38)
                        .background(IslandifyBrightPalette.surfaceSoft, in: Circle())
                }
                .accessibilityLabel(copy.end)
            }

            IslandifyHeroCard(
                eyebrow: copy.running,
                value: IslandifyTimeFormatter.distance(kilometers: snapshot.distanceKilometers),
                detail: IslandifyTimeFormatter.duration(snapshot.elapsed)
            )
            .accessibilityLabel(state.configuration.name)

            IslandifyBrightCard(padding: 16, cornerRadius: 22) {
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        runningMetric(title: copy.currentPace, value: IslandifyTimeFormatter.pace(secondsPerKilometer: snapshot.currentPaceSecondsPerKilometer))
                        runningMetric(title: copy.averagePace, value: IslandifyTimeFormatter.pace(secondsPerKilometer: snapshot.averagePaceSecondsPerKilometer))
                        runningMetric(title: copy.calories, value: copy.caloriesValue(Int(snapshot.calories.rounded())))
                    }

                    Text(locationMessage)
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        if state.phase == .active {
                            Button(copy.pause) { Task { await model.pauseRun() } }
                                .buttonStyle(.borderedProminent)
                                .tint(IslandifyBrightPalette.mint)
                        } else if state.phase == .paused {
                            Button(copy.resume) { Task { await model.resumeRun() } }
                                .buttonStyle(.borderedProminent)
                                .tint(IslandifyBrightPalette.mint)
                        }
                        TextField(copy.optionalMemo, text: $memo)
                            .textFieldStyle(.plain)
                            .islandifyInputStyle()
                            .accessibilityLabel(copy.optionalRunMemo)
                    }
                }
            }
        }
        .foregroundStyle(IslandifyBrightPalette.text)
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
        return IslandifyBrightCard(padding: 18, cornerRadius: 26) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(copy.recentRuns)
                        .font(.headline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundStyle(IslandifyBrightPalette.mint)
                }
                if model.runRecords.isEmpty {
                    Text(copy.completedRunsPlaceholder)
                        .font(.callout)
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                } else {
                    ForEach(model.runRecords.prefix(5)) { record in
                        HStack(spacing: 10) {
                            Image(systemName: "figure.run")
                                .foregroundStyle(IslandifyBrightPalette.mint)
                                .frame(width: 34, height: 34)
                                .background(IslandifyBrightPalette.mint.opacity(0.11), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.name)
                                    .font(.subheadline.weight(.medium))
                                Text("\(IslandifyTimeFormatter.distance(kilometers: record.distanceMeters / 1_000)) · \(IslandifyTimeFormatter.duration(record.duration))")
                                    .font(.caption)
                                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                            }
                            Spacer()
                            Text(copy.caloriesValue(Int(record.calories.rounded())))
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(IslandifyBrightPalette.secondaryText)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func runningMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(IslandifyBrightPalette.secondaryText)
                .lineLimit(1)
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(IslandifyBrightPalette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RunningFeatureView()
        .environmentObject(IslandifyAppModel())
}
