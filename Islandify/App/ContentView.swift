import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: IslandifyAppModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "rectangle.topthird.inset.filled")
                    .font(.system(size: 48, weight: .medium))
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Islandify")
                        .font(.largeTitle.weight(.bold))
                    Text("A small view of what matters now.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                GroupBox("Preview") {
                    HStack {
                        Text(model.previewActivity.title)
                        Spacer()
                        Text(model.previewActivity.primaryValue)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(model.previewActivity.title), \(model.previewActivity.primaryValue)")
                }
                .frame(maxWidth: 420)

                Text("Create a timer, trip, relationship counter, or run to begin.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Islandify")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(IslandifyAppModel())
}
