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
                RelationshipFeatureView()
                    .tabItem { Label("Together", systemImage: "heart.fill") }
                RunningFeatureView()
                    .tabItem { Label("Run", systemImage: "figure.run") }
                CustomizationFeatureView()
                    .tabItem { Label("Style", systemImage: "slider.horizontal.3") }
            }
            .navigationTitle("Islandify")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(IslandifyAppModel())
}
