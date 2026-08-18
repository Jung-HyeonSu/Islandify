import SwiftUI

struct RelationshipFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var name = "Our days"
    @State private var nickname = ""
    @State private var startDate = Date.now.addingTimeInterval(-30 * 24 * 60 * 60)
    @State private var timeZoneIdentifier = TimeZone.current.identifier
    @State private var iconText = "❤️"
    @State private var theme: IslandifyTheme = .pastelCouple
    @State private var countingMode: RelationshipCountingMode = .dPlus1
    @State private var notificationsEnabled = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let relationship = model.activeRelationship {
                    activeRelationshipCard(relationship)
                } else {
                    relationshipForm
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

    private var relationshipForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Together", systemImage: "heart.fill")
                .font(.title2.weight(.semibold))

            TextField("Anniversary name", text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Anniversary name")

            TextField("Nickname", text: $nickname)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Nickname")

            DatePicker("Start date", selection: $startDate, in: ...Date.now, displayedComponents: [.date])
                .accessibilityLabel("Relationship start date")

            Picker("Counting", selection: $countingMode) {
                Text("D+0 on start date").tag(RelationshipCountingMode.dPlus0)
                Text("D+1 on start date").tag(RelationshipCountingMode.dPlus1)
            }

            HStack {
                Label("Timezone", systemImage: "globe")
                Spacer()
                TextField("Asia/Seoul", text: $timeZoneIdentifier)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 190)
                    .accessibilityLabel("Relationship timezone")
            }

            HStack {
                Label("Icon", systemImage: "face.smiling")
                Spacer()
                TextField("❤️", text: $iconText)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                    .accessibilityLabel("Relationship emoji")
            }

            Picker("Theme", selection: $theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }

            Toggle("Milestone notifications", isOn: $notificationsEnabled)

            Button {
                Task {
                    await model.startRelationship(
                        name: name,
                        nickname: nickname,
                        startDate: startDate,
                        timeZoneIdentifier: timeZoneIdentifier,
                        iconText: iconText,
                        theme: theme,
                        countingMode: countingMode,
                        notificationsEnabled: notificationsEnabled
                    )
                }
            } label: {
                Label("Start D+", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.activeTimer != nil || model.activeTravel != nil)
            .accessibilityHint("Starts the relationship counter and optionally schedules local milestone notifications")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func activeRelationshipCard(_ configuration: RelationshipConfiguration) -> some View {
        let snapshot = RelationshipCalculator.snapshot(for: configuration, at: model.now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Label(configuration.name, systemImage: configuration.icon.kind == .system ? configuration.icon.value : "heart.fill")
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(configuration.countingMode == .dPlus0 ? "D+0" : "D+1")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text("D+\(snapshot.dayCount)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityLabel(snapshot.message)

            Text(snapshot.message)
                .font(.headline)
                .lineLimit(2)

            if let dayMilestone = snapshot.nextDayMilestone {
                Text("Next: \(dayMilestone.title)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let annualMilestone = snapshot.nextAnnualMilestone {
                Text("Annual: \(annualMilestone.title)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Timezone: \(configuration.timeZoneIdentifier)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button("End counter", role: .destructive) { Task { await model.endRelationship() } }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("More relationship actions")
                }
            }
        }
        .padding()
        .background(Color(hex: configuration.theme.palette.backgroundHex), in: RoundedRectangle(cornerRadius: 20))
        .foregroundStyle(Color(hex: configuration.theme.palette.foregroundHex))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(snapshot.message)
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
