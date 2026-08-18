import SwiftUI

struct TravelFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var tripName = "Summer trip"
    @State private var destination = "Seoul"
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
        .onAppear { model.refresh() }
    }

    private var travelForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Travel D-day", systemImage: "airplane.departure")
                .font(.title2.weight(.semibold))

            TextField("Trip name", text: $tripName)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Trip name")

            TextField("Destination", text: $destination)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Destination")

            DatePicker("Departure", selection: $departureDate, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                .accessibilityLabel("Departure date and time")

            HStack {
                Label("Timezone", systemImage: "globe")
                Spacer()
                TextField("Asia/Seoul", text: $timeZoneIdentifier)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 190)
                    .accessibilityLabel("Departure timezone")
            }

            HStack {
                Label("Icon", systemImage: "face.smiling")
                Spacer()
                TextField("✈️", text: $iconText)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                    .accessibilityLabel("Trip emoji")
            }

            Picker("Theme", selection: $theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
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
                Label("Start trip countdown", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.activeTimer != nil)
            .accessibilityHint("Starts the trip countdown and uses the saved departure timezone")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func activeTravelCard(_ configuration: TravelConfiguration) -> some View {
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
                Text("Timezone: \(configuration.timeZoneIdentifier)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button("End trip", role: .destructive) { Task { await model.endTravel() } }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("More trip actions")
                }
            }
        }
        .padding()
        .background(Color(hex: configuration.theme.palette.backgroundHex), in: RoundedRectangle(cornerRadius: 20))
        .foregroundStyle(Color(hex: configuration.theme.palette.foregroundHex))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(configuration.tripName), \(configuration.destination), \(state.displayValue)")
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
