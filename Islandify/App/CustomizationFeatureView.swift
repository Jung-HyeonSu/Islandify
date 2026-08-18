import SwiftUI

struct CustomizationFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var kind: ActivityKind = .timer
    @State private var configuration = PresentationConfiguration.default(for: .timer)
    @State private var iconText = "🔥"
    @State private var validationMessage: String?

    var body: some View {
        let copy = IslandifyCopy.current
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                IslandifyPageHeader(
                    eyebrow: copy.style,
                    title: copy.customize,
                    subtitle: copy.customizationDescription,
                    symbolName: "sparkles"
                )
                editor
                preview
                if let validationMessage {
                    IslandifyMessageBanner(message: validationMessage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .islandifyBrightPageBackground()
        .tint(IslandifyBrightPalette.lavender)
        .onAppear { loadConfiguration() }
        .onChange(of: kind) { _ in loadConfiguration() }
        .accessibilityIdentifier("customization-feature")
    }

    private var editor: some View {
        let copy = IslandifyCopy.current
        return IslandifyBrightCard(padding: 20, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 14) {
                IslandifyPickerRow(
                    title: copy.activity,
                    selection: $kind,
                    options: ActivityKind.allCases.map { IslandifyPickerOption(value: $0, title: copy.activityName($0)) }
                )

                TextField(copy.title, text: $configuration.title)
                    .textFieldStyle(.plain)
                    .islandifyInputStyle()
                    .accessibilityLabel(copy.liveActivityTitle)
                TextField(copy.shortDescription, text: $configuration.description)
                    .textFieldStyle(.plain)
                    .islandifyInputStyle()
                    .accessibilityLabel(copy.liveActivityDescription)

                IslandifyEmojiPickerField(selection: iconSelection, title: copy.iconOrEmoji, placeholder: emojiPlaceholder)
                    .accessibilityLabel(copy.liveActivityIconOrEmoji)

                IslandifyPickerRow(
                    title: copy.themeOrColor,
                    selection: $configuration.theme,
                    options: IslandifyTheme.allCases.map { IslandifyPickerOption(value: $0, title: copy.themeName($0)) }
                )
                IslandifyPickerRow(
                    title: copy.numberFormat,
                    selection: $configuration.numberFormat,
                    options: NumberFormat.allCases.map { IslandifyPickerOption(value: $0, title: copy.numberFormatName($0)) }
                )
                IslandifyPickerRow(
                    title: copy.progress,
                    selection: $configuration.progressStyle,
                    options: ProgressStyle.allCases.map { IslandifyPickerOption(value: $0, title: copy.progressStyleName($0)) }
                )
                IslandifyPickerRow(
                    title: copy.alignment,
                    selection: $configuration.alignment,
                    options: SlotAlignment.allCases.map { IslandifyPickerOption(value: $0, title: copy.alignmentName($0)) }
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(copy.compactLeadingSlot)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(IslandifyBrightPalette.text)
                    IslandifyPickerRow(
                        title: copy.compactLeadingSlot,
                        selection: $configuration.compactLeading,
                        options: PresentationSlot.allCases.map { IslandifyPickerOption(value: $0, title: copy.slotName($0)) }
                    )
                    IslandifyPickerRow(
                        title: copy.compactTrailingSlot,
                        selection: $configuration.compactTrailing,
                        options: PresentationSlot.allCases.map { IslandifyPickerOption(value: $0, title: copy.slotName($0)) }
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(copy.expandedDetails)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(IslandifyBrightPalette.text)
                    ForEach(0..<3, id: \.self) { index in
                        IslandifyPickerRow(
                            title: copy.detail(index + 1),
                            selection: Binding(
                                get: { expandedSlot(at: index) },
                                set: { updateExpandedSlot(at: index, value: $0) }
                            ),
                            options: PresentationSlot.allCases.map { IslandifyPickerOption(value: $0, title: copy.slotName($0)) }
                        )
                    }
                }

                TextField(copy.completionMessage, text: $configuration.completionMessage)
                    .textFieldStyle(.plain)
                    .islandifyInputStyle()
                    .accessibilityLabel(copy.completionMessage)

                IslandifyGradientButton(title: copy.saveLayout) {
                    let errors = PresentationComposer.validate(configuration)
                    if errors.isEmpty {
                        model.saveComposition(configuration, for: kind)
                        validationMessage = nil
                    } else {
                        validationMessage = errors.map { copy.validationMessage(code: String(describing: $0)) }.joined(separator: ", ")
                    }
                }
            }
        }
    }

    private var preview: some View {
        let copy = IslandifyCopy.current
        let state = PresentationComposer.previewState(for: kind, configuration: configuration)
        return IslandifyBrightCard(padding: 20, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(copy.previewAllSurfaces)
                            .font(.headline.weight(.semibold))
                        Text(IslandifyLanguage.current == .korean ? "시스템 슬롯에서 어떻게 보이는지 확인하세요." : "Check every system surface before saving.")
                            .font(.caption)
                            .foregroundStyle(IslandifyBrightPalette.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "eye")
                        .foregroundStyle(IslandifyBrightPalette.lavender)
                }

                ForEach(ActivitySurface.allCases, id: \.self) { surface in
                    let rendered = ActivityPresentationRenderer.render(state, on: surface)
                    PreviewSurfaceView(rendered: rendered, state: state)
                }
            }
        }
    }

    private func loadConfiguration() {
        configuration = model.composition(for: kind)
        iconText = configuration.icon.kind == .emoji ? configuration.icon.value : emojiPlaceholder
        configuration.icon = ActivityIcon(emoji: iconText)
    }

    private var iconSelection: Binding<String> {
        Binding(
            get: { iconText },
            set: { value in
                iconText = value
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    configuration.icon = ActivityIcon(emoji: trimmed)
                }
            }
        )
    }

    private var emojiPlaceholder: String {
        switch kind {
        case .timer: return "🔥"
        case .travel: return "✈️"
        case .relationship: return "❤️"
        case .running: return "🏃"
        }
    }

    private func expandedSlot(at index: Int) -> PresentationSlot {
        guard configuration.expandedDetails.indices.contains(index) else { return .primaryValue }
        return configuration.expandedDetails[index]
    }

    private func updateExpandedSlot(at index: Int, value: PresentationSlot) {
        while configuration.expandedDetails.count <= index {
            configuration.expandedDetails.append(.primaryValue)
        }
        configuration.expandedDetails[index] = value
    }
}

private struct PreviewSurfaceView: View {
    let rendered: ActivitySurfaceModel
    let state: ActivityPresentationState

    var body: some View {
        let copy = IslandifyCopy.current
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(copy.surfaceName(rendered.surface))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                Spacer()
                Text(state.icon.value)
                    .font(.caption)
            }
            HStack(spacing: 8) {
                if let leadingText = rendered.leadingText {
                    Text(leadingText).lineLimit(1)
                }
                Text(rendered.primaryText)
                    .font(.body.monospacedDigit().weight(.semibold))
                    .lineLimit(1)
                if let trailingText = rendered.trailingText {
                    Spacer(minLength: 4)
                    Text(trailingText).lineLimit(1)
                }
            }
            if let secondaryText = rendered.secondaryText, !secondaryText.isEmpty {
                Text(secondaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if !rendered.details.isEmpty {
                Text(rendered.details.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(IslandifyBrightPalette.surfaceSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(IslandifyBrightPalette.line, lineWidth: 1)
        }
        .foregroundStyle(IslandifyBrightPalette.text)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rendered.accessibilityLabel)
    }
}

#Preview {
    CustomizationFeatureView()
        .environmentObject(IslandifyAppModel())
}
