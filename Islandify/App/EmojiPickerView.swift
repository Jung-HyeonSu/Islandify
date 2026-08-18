import SwiftUI

struct IslandifyEmojiPickerField: View {
    @Binding var selection: String
    let title: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 12) {
            Label(title, systemImage: "face.smiling")

            Spacer(minLength: 8)

            TextField(placeholder, text: $selection)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width: 90)
                .keyboardType(.default)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .accessibilityLabel(selection.isEmpty ? title : "\(title), \(selection)")
                .accessibilityHint(IslandifyLanguage.current == .korean ? "탭한 뒤 키보드의 이모지 키로 선택" : "Tap, then use the emoji key on the keyboard")
        }
    }
}

struct IslandifyAppIconView: View {
    let icon: ActivityIcon

    var body: some View {
        Group {
            if icon.kind == .emoji {
                Text(icon.value)
            } else {
                Image(systemName: icon.value)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityHidden(true)
    }
}
