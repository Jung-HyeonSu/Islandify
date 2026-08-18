import SwiftUI

struct TravelFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var tripName = IslandifyCopy.current.travelExampleName
    @State private var destination = IslandifyCopy.current.destinationExample
    @State private var departureDate = Date.now.addingTimeInterval(7 * 24 * 60 * 60)
    @State private var timeZoneIdentifier = TimeZone.current.identifier
    @State private var iconText = "✈️"
    @State private var theme: IslandifyTheme = .travelBlue

    var body: some View {
        let copy = IslandifyCopy.current
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                IslandifyPageHeader(
                    eyebrow: copy.travel,
                    title: model.activeTravel?.tripName ?? copy.travelExampleName,
                    subtitle: copy.travelDdayTitle,
                    symbolName: "airplane.departure"
                )

                if let travel = model.activeTravel {
                    activeTravelCard(travel)
                } else {
                    travelForm
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
        .accessibilityIdentifier("travel-feature")
    }

    private var travelForm: some View {
        let copy = IslandifyCopy.current
        return IslandifyBrightCard(padding: 20, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 15) {
                Text(copy.travelDdayTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.text)

                TextField(copy.tripName, text: $tripName)
                    .textFieldStyle(.plain)
                    .islandifyInputStyle()
                    .accessibilityLabel(copy.tripName)

                TextField(copy.destination, text: $destination)
                    .textFieldStyle(.plain)
                    .islandifyInputStyle()
                    .accessibilityLabel(copy.destination)

                DatePicker(copy.departure, selection: $departureDate, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(IslandifyBrightPalette.surfaceSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel(copy.departureDateAndTime)

                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .foregroundStyle(IslandifyBrightPalette.lavender)
                    Text(copy.timezone)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    TextField(copy.timezoneExample, text: $timeZoneIdentifier)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 180)
                        .accessibilityLabel(copy.departureTimezone)
                }
                .islandifyInputStyle()

                IslandifyEmojiPickerField(selection: $iconText, title: copy.icon, placeholder: "✈️")
                    .accessibilityLabel(copy.tripEmoji)

                IslandifyPickerRow(
                    title: copy.theme,
                    selection: $theme,
                    options: IslandifyTheme.allCases.map { IslandifyPickerOption(value: $0, title: copy.themeName($0)) }
                )

                IslandifyGradientButton(title: copy.startTripCountdown) {
                    Task {
                        await model.startTravel(
                            tripName: tripName,
                            destination: destination,
                            departureDate: departureDate,
                            timeZoneIdentifier: timeZoneIdentifier,
                            iconText: iconText,
                            theme: theme
                        )
                    }
                }
                .disabled(model.activeTimer != nil)
                .accessibilityHint(copy.startTripHint)
            }
        }
    }

    private func loadSavedIcon() {
        let saved = model.composition(for: .travel)
        if saved.icon.kind == .emoji {
            iconText = saved.icon.value
        }
    }

    private func activeTravelCard(_ configuration: TravelConfiguration) -> some View {
        let copy = IslandifyCopy.current
        let state = TravelCalculator.state(for: configuration, at: model.now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                IslandifyAppIconView(icon: configuration.presentation.icon)
                    .font(.title3)
                    .frame(width: 38, height: 38)
                    .background(IslandifyBrightPalette.lavender.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(configuration.tripName)
                        .font(.headline.weight(.semibold))
                    Text(configuration.destination)
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
                Spacer()
                Menu {
                    Button(copy.endTrip, role: .destructive) { Task { await model.endTravel() } }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.bold))
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                        .frame(width: 38, height: 38)
                        .background(IslandifyBrightPalette.surfaceSoft, in: Circle())
                }
                .accessibilityLabel(copy.moreTripActions)
            }

            let displayValue = state.displayValue
            IslandifyHeroCard(
                eyebrow: copy.travel,
                value: displayValue,
                detail: state.label
            )
            .accessibilityLabel(copy.travelAccessibility(
                tripName: configuration.tripName,
                destination: configuration.destination,
                value: state.displayValue
            ))

            IslandifyBrightCard(padding: 16, cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(copy.destination)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                    Text(configuration.destination)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(IslandifyBrightPalette.text)
                    Text("\(copy.timezone): \(configuration.timeZoneIdentifier)")
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.mutedText)
                }
            }
        }
        .foregroundStyle(IslandifyBrightPalette.text)
    }
}

#Preview {
    TravelFeatureView()
        .environmentObject(IslandifyAppModel())
}
