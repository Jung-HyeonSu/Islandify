import SwiftUI

struct CustomizationFeatureView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @State private var kind: ActivityKind = .timer
    @State private var configuration = PresentationConfiguration.default(for: .timer)
    @State private var iconText = "🔥"
    @State private var validationMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                editor
                preview
                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .islandifyBrightPageBackground()
        .tint(IslandifyBrightPalette.accent)
        .onAppear { loadConfiguration() }
        .onChange(of: kind) { _ in loadConfiguration() }
    }

    private var editor: some View {
        let copy = IslandifyCopy.current
        return VStack(alignment: .leading, spacing: 14) {
            Label(copy.customize, systemImage: "slider.horizontal.3")
                .font(.title2.weight(.semibold))

            Text(copy.customizationDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker(copy.activity, selection: $kind) {
                ForEach(ActivityKind.allCases, id: \.self) { kind in
                    Text(copy.activityName(kind)).tag(kind)
                }
            }

            TextField(copy.title, text: $configuration.title)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(copy.liveActivityTitle)
            TextField(copy.shortDescription, text: $configuration.description)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(copy.liveActivityDescription)

            IslandifyEmojiPickerField(selection: iconSelection, title: copy.iconOrEmoji, placeholder: emojiPlaceholder)
                .accessibilityLabel(copy.liveActivityIconOrEmoji)

            Picker(copy.themeOrColor, selection: $configuration.theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(copy.themeName(theme)).tag(theme)
                }
            }
            Picker(copy.numberFormat, selection: $configuration.numberFormat) {
                ForEach(NumberFormat.allCases, id: \.self) { format in
                    Text(copy.numberFormatName(format)).tag(format)
                }
            }
            Picker(copy.progress, selection: $configuration.progressStyle) {
                ForEach(ProgressStyle.allCases, id: \.self) { style in
                    Text(copy.progressStyleName(style)).tag(style)
                }
            }
            Picker(copy.alignment, selection: $configuration.alignment) {
                ForEach(SlotAlignment.allCases, id: \.self) { alignment in
                    Text(copy.alignmentName(alignment)).tag(alignment)
                }
            }
            Picker(copy.compactLeadingSlot, selection: $configuration.compactLeading) {
                ForEach(PresentationSlot.allCases, id: \.self) { slot in
                    Text(copy.slotName(slot)).tag(slot)
                }
            }
            Picker(copy.compactTrailingSlot, selection: $configuration.compactTrailing) {
                ForEach(PresentationSlot.allCases, id: \.self) { slot in
                    Text(copy.slotName(slot)).tag(slot)
                }
            }

            Text(copy.expandedDetails)
                .font(.headline)
            ForEach(0..<3, id: \.self) { index in
                Picker(copy.detail(index + 1), selection: Binding(
                    get: { expandedSlot(at: index) },
                    set: { updateExpandedSlot(at: index, value: $0) }
                )) {
                    ForEach(PresentationSlot.allCases, id: \.self) { slot in
                        Text(copy.slotName(slot)).tag(slot)
                    }
                }
            }

            TextField(copy.completionMessage, text: $configuration.completionMessage)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(copy.completionMessage)

            Button {
                let errors = PresentationComposer.validate(configuration)
                if errors.isEmpty {
                    model.saveComposition(configuration, for: kind)
                    validationMessage = nil
                } else {
                    validationMessage = errors.map { copy.validationMessage(code: String(describing: $0)) }.joined(separator: ", ")
                }
            } label: {
                Label(copy.saveLayout, systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .islandifyBrightCardBackground(cornerRadius: 24)
    }

    private var preview: some View {
        let copy = IslandifyCopy.current
        let state = PresentationComposer.previewState(for: kind, configuration: configuration)
        return VStack(alignment: .leading, spacing: 12) {
            Text(copy.previewAllSurfaces)
                .font(.headline)
            ForEach(ActivitySurface.allCases, id: \.self) { surface in
                let rendered = ActivityPresentationRenderer.render(state, on: surface)
                PreviewSurfaceView(rendered: rendered, state: state)
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
        VStack(alignment: .leading, spacing: 6) {
            Text(copy.surfaceName(rendered.surface))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
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
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: state.palette.backgroundHex), in: RoundedRectangle(cornerRadius: 14))
        .foregroundStyle(Color(hex: state.palette.foregroundHex))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rendered.accessibilityLabel)
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
