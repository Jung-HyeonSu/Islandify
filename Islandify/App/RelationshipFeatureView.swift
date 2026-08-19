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
        let copy = IslandifyCopy.current
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                IslandifyPageHeader(
                    eyebrow: copy.relationship,
                    title: model.activeRelationship?.name ?? copy.relationshipExampleName,
                    subtitle: IslandifyLanguage.current == .korean ? "소중한 날을 매일 선명하게." : "Keep the days that matter close.",
                    symbolName: "heart.fill"
                )

                if let relationship = model.activeRelationship {
                    activeRelationshipCard(relationship)
                } else {
                    relationshipForm
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
        .tint(IslandifyBrightPalette.pink)
        .onAppear {
            model.refresh()
            loadSavedIcon()
        }
        .accessibilityIdentifier("relationship-feature")
    }

    private var relationshipForm: some View {
        let copy = IslandifyCopy.current
        return IslandifyBrightCard(padding: 20, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 15) {
                Text(copy.relationship)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.text)

                TextField(copy.anniversaryName, text: $name)
                    .textFieldStyle(.plain)
                    .islandifyInputStyle()
                    .accessibilityLabel(copy.anniversaryName)

                TextField(copy.nickname, text: $nickname)
                    .textFieldStyle(.plain)
                    .islandifyInputStyle()
                    .accessibilityLabel(copy.nickname)

                DatePicker(copy.startDate, selection: $startDate, in: ...Date.now, displayedComponents: [.date])
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(IslandifyBrightPalette.surfaceSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel(copy.relationshipStartDate)

                IslandifyPickerRow(
                    title: copy.relationshipCounting,
                    selection: $countingMode,
                    options: [
                        IslandifyPickerOption(value: RelationshipCountingMode.dPlus0, title: copy.dPlus0OnStartDate),
                        IslandifyPickerOption(value: RelationshipCountingMode.dPlus1, title: copy.dPlus1OnStartDate)
                    ]
                )

                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .foregroundStyle(IslandifyBrightPalette.pink)
                    Text(copy.timezone)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    TextField(copy.timezoneExample, text: $timeZoneIdentifier)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 180)
                        .accessibilityLabel(copy.relationshipTimezone)
                }
                .islandifyInputStyle()

                IslandifyEmojiPickerField(selection: $iconText, title: copy.icon, placeholder: "❤️")
                    .accessibilityLabel(copy.relationshipEmoji)

                IslandifyPickerRow(
                    title: copy.theme,
                    selection: $theme,
                    options: IslandifyTheme.allCases.map { IslandifyPickerOption(value: $0, title: copy.themeName($0)) }
                )

                Toggle(copy.milestoneNotifications, isOn: $notificationsEnabled)
                    .font(.subheadline.weight(.medium))
                    .tint(IslandifyBrightPalette.pink)

                IslandifyGradientButton(title: copy.startRelationship) {
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
                }
                .disabled(model.activeTimer != nil || model.activeTravel != nil)
                .accessibilityHint(copy.startRelationshipHint)
            }
        }
    }

    private func loadSavedIcon() {
        let saved = model.composition(for: .relationship)
        if saved.icon.kind == .emoji {
            iconText = saved.icon.value
        }
    }

    private func activeRelationshipCard(_ configuration: RelationshipConfiguration) -> some View {
        let copy = IslandifyCopy.current
        let snapshot = RelationshipCalculator.snapshot(for: configuration, at: model.now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                IslandifyAppIconView(icon: configuration.presentation.icon)
                    .font(.title3)
                    .frame(width: 38, height: 38)
                    .background(IslandifyBrightPalette.pink.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(configuration.name)
                        .font(.headline.weight(.semibold))
                    Text(configuration.nickname.isEmpty ? copy.relationship : configuration.nickname)
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
                Spacer()
                Menu {
                    Button(copy.endCounter, role: .destructive) { Task { await model.endRelationship() } }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.bold))
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                        .frame(width: 38, height: 38)
                        .background(IslandifyBrightPalette.surfaceSoft, in: Circle())
                }
                .accessibilityLabel(copy.moreRelationshipActions)
            }

            IslandifyHeroCard(
                eyebrow: copy.relationship,
                value: "D+\(snapshot.dayCount)",
                detail: snapshot.message
            )
            .accessibilityLabel(snapshot.message)

            IslandifyBrightCard(padding: 16, cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    if let dayMilestone = snapshot.nextDayMilestone {
                        Label(copy.nextMilestone(dayMilestone.title), systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(IslandifyBrightPalette.pink)
                    }
                    if let annualMilestone = snapshot.nextAnnualMilestone {
                        Text(copy.annualMilestoneLabel(annualMilestone.title))
                            .font(.caption)
                            .foregroundStyle(IslandifyBrightPalette.secondaryText)
                    }
                    Text("\(copy.timezone): \(configuration.timeZoneIdentifier)")
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(IslandifyBrightPalette.text)
    }
}

#Preview {
    RelationshipFeatureView()
        .environmentObject(IslandifyAppModel())
}
