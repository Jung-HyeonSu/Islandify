import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: IslandifyAppModel

    var body: some View {
        NavigationStack {
            TabView {
                TimerFeatureView()
                    .tabItem { Label("Timer", systemImage: "timer") }
                TravelFeatureView()
                    .tabItem { Label("Travel", systemImage: "airplane.departure") }
            }
            .navigationTitle("Islandify")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(IslandifyAppModel())
}
