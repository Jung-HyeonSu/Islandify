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
        .onAppear { loadConfiguration() }
        .onChange(of: kind) { _ in loadConfiguration() }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Customize", systemImage: "slider.horizontal.3")
                .font(.title2.weight(.semibold))

            Text("Choose semantic values for Apple’s fixed Live Activity slots. Islandify never turns the Dynamic Island into a free-form canvas.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Activity", selection: $kind) {
                ForEach(ActivityKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue.capitalized).tag(kind)
                }
            }

            TextField("Title", text: $configuration.title)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Live Activity title")
            TextField("Short description", text: $configuration.description)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Live Activity description")

            HStack {
                Label("Icon / emoji", systemImage: "face.smiling")
                Spacer()
                TextField("🔥", text: $iconText)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .accessibilityLabel("Live Activity icon or emoji")
                    .onChange(of: iconText) { value in
                        configuration.icon = ActivityIcon(emoji: value)
                    }
            }

            Picker("Theme / color", selection: $configuration.theme) {
                ForEach(IslandifyTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            Picker("Number format", selection: $configuration.numberFormat) {
                ForEach(NumberFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            Picker("Progress", selection: $configuration.progressStyle) {
                ForEach(ProgressStyle.allCases, id: \.self) { style in
                    Text(style.rawValue.capitalized).tag(style)
                }
            }
            Picker("Alignment", selection: $configuration.alignment) {
                ForEach(SlotAlignment.allCases, id: \.self) { alignment in
                    Text(alignment.rawValue.capitalized).tag(alignment)
                }
            }
            Picker("Compact leading slot", selection: $configuration.compactLeading) {
                ForEach(PresentationSlot.allCases, id: \.self) { slot in
                    Text(slot.rawValue).tag(slot)
                }
            }
            Picker("Compact trailing slot", selection: $configuration.compactTrailing) {
                ForEach(PresentationSlot.allCases, id: \.self) { slot in
                    Text(slot.rawValue).tag(slot)
                }
            }

            Text("Expanded details")
                .font(.headline)
            ForEach(0..<3, id: \.self) { index in
                Picker("Detail \(index + 1)", selection: Binding(
                    get: { expandedSlot(at: index) },
                    set: { updateExpandedSlot(at: index, value: $0) }
                )) {
                    ForEach(PresentationSlot.allCases, id: \.self) { slot in
                        Text(slot.rawValue).tag(slot)
                    }
                }
            }

            TextField("Completion message", text: $configuration.completionMessage)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Completion message")

            Button {
                let errors = PresentationComposer.validate(configuration)
                if errors.isEmpty {
                    model.saveComposition(configuration, for: kind)
                    validationMessage = nil
                } else {
                    validationMessage = errors.map { String(describing: $0) }.joined(separator: ", ")
                }
            } label: {
                Label("Save layout", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var preview: some View {
        let state = PresentationComposer.previewState(for: kind, configuration: configuration)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Preview all system surfaces")
                .font(.headline)
            ForEach(ActivitySurface.allCases, id: \.self) { surface in
                let rendered = ActivityPresentationRenderer.render(state, on: surface)
                PreviewSurfaceView(rendered: rendered, state: state)
            }
        }
    }

    private func loadConfiguration() {
        configuration = model.composition(for: kind)
        iconText = configuration.icon.value
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
        VStack(alignment: .leading, spacing: 6) {
            Text(rendered.surface.rawValue.capitalized)
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
