import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: IslandifyAppModel

    var body: some View {
        NavigationStack {
            TimerFeatureView()
            .navigationTitle("Islandify")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(IslandifyAppModel())
}
