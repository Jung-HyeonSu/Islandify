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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let travel = model.activeTravel {
                    activeTravelCard(travel)
                } else {
                    travelForm
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
        .onAppear { model.refresh() }
    }

    private var travelForm: some View {
        let copy = IslandifyCopy.current
        return VStack(alignment: .leading, spacing: 16) {
            Label(copy.travelDdayTitle, systemImage: "airplane.departure")
                .font(.title2.weight(.semibold))

            TextField(copy.tripName, text: $tripName)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(copy.tripName)

            TextField(copy.destination, text: $destination)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(copy.destination)

            DatePicker(copy.departure, selection: $departureDate, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                .accessibilityLabel(copy.departureDateAndTime)

            HStack {
                Label(copy.timezone, systemImage: "globe")
                Spacer()
                TextField(copy.timezoneExample, text: $timeZoneIdentifier)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 190)
                    .accessibilityLabel(copy.departureTimezone)
            }

            HStack {
                Label(copy.icon, systemImage: "face.smiling")
                Spacer()
                TextField("✈️", text: $iconText)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                    .accessibilityLabel(copy.tripEmoji)
            }

            Picker(copy.theme, selection: $theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(copy.themeName(theme)).tag(theme)
                }
            }

            Button {
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
            } label: {
                Label(copy.startTripCountdown, systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.activeTimer != nil)
            .accessibilityHint(copy.startTripHint)
        }
        .padding()
        .islandifyBrightCardBackground(cornerRadius: 24)
    }

    private func activeTravelCard(_ configuration: TravelConfiguration) -> some View {
        let copy = IslandifyCopy.current
        let state = TravelCalculator.state(for: configuration, at: model.now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Label(configuration.tripName, systemImage: configuration.icon.kind == .system ? configuration.icon.value : "airplane.departure")
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(state.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if state.kind == .dDay, let departureDate = state.remainingUntilDeparture.map({ model.now.addingTimeInterval($0) }) {
                Text(timerInterval: model.now...departureDate, countsDown: true)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            } else {
                Text(state.displayValue)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }

            Text(configuration.destination)
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack {
                Text("\(copy.timezone): \(configuration.timeZoneIdentifier)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button(copy.endTrip, role: .destructive) { Task { await model.endTravel() } }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel(copy.moreTripActions)
                }
            }
        }
        .padding()
        .islandifyBrightCardBackground(cornerRadius: 24)
        .foregroundStyle(IslandifyBrightPalette.text)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(copy.travelAccessibility(
            tripName: configuration.tripName,
            destination: configuration.destination,
            value: state.displayValue
        ))
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
