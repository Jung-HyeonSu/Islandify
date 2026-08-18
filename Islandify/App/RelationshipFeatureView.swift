import SwiftUI

struct RelationshipFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var name = IslandifyCopy.current.relationshipExampleName
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
        .islandifyBrightPageBackground()
        .onAppear { model.refresh() }
    }

    private var relationshipForm: some View {
        let copy = IslandifyCopy.current
        return VStack(alignment: .leading, spacing: 16) {
            Label(copy.relationship, systemImage: "heart.fill")
                .font(.title2.weight(.semibold))

            TextField(copy.anniversaryName, text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(copy.anniversaryName)

            TextField(copy.nickname, text: $nickname)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(copy.nickname)

            DatePicker(copy.startDate, selection: $startDate, in: ...Date.now, displayedComponents: [.date])
                .accessibilityLabel(copy.relationshipStartDate)

            Picker(copy.relationshipCounting, selection: $countingMode) {
                Text(copy.dPlus0OnStartDate).tag(RelationshipCountingMode.dPlus0)
                Text(copy.dPlus1OnStartDate).tag(RelationshipCountingMode.dPlus1)
            }

            HStack {
                Label(copy.timezone, systemImage: "globe")
                Spacer()
                TextField(copy.timezoneExample, text: $timeZoneIdentifier)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 190)
                    .accessibilityLabel(copy.relationshipTimezone)
            }

            HStack {
                Label(copy.icon, systemImage: "face.smiling")
                Spacer()
                TextField("❤️", text: $iconText)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                    .accessibilityLabel(copy.relationshipEmoji)
            }

            Picker(copy.theme, selection: $theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(copy.themeName(theme)).tag(theme)
                }
            }

            Toggle(copy.milestoneNotifications, isOn: $notificationsEnabled)

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
                Label(copy.startRelationship, systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.activeTimer != nil || model.activeTravel != nil)
            .accessibilityHint(copy.startRelationshipHint)
        }
        .padding()
        .islandifyBrightCardBackground(cornerRadius: 24)
    }

    private func activeRelationshipCard(_ configuration: RelationshipConfiguration) -> some View {
        let copy = IslandifyCopy.current
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
                Text(copy.nextMilestone(dayMilestone.title))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let annualMilestone = snapshot.nextAnnualMilestone {
                Text(copy.annualMilestoneLabel(annualMilestone.title))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("\(copy.timezone): \(configuration.timeZoneIdentifier)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button(copy.endCounter, role: .destructive) { Task { await model.endRelationship() } }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel(copy.moreRelationshipActions)
                }
            }
        }
        .padding()
        .islandifyBrightCardBackground(cornerRadius: 24)
        .foregroundStyle(IslandifyBrightPalette.text)
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
