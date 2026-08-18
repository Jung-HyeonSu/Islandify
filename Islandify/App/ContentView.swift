import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let copy = IslandifyCopy.current
        NavigationStack {
            TabView {
                TimerFeatureView()
                    .tabItem { Label(copy.timer, systemImage: "timer") }
                TravelFeatureView()
                    .tabItem { Label(copy.travel, systemImage: "airplane.departure") }
                RelationshipFeatureView()
                    .tabItem { Label(copy.relationship, systemImage: "heart.fill") }
                RunningFeatureView()
                    .tabItem { Label(copy.running, systemImage: "figure.run") }
                CustomizationFeatureView()
                    .tabItem { Label(copy.style, systemImage: "slider.horizontal.3") }
            }
            .navigationTitle(copy.appName)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                model.refresh()
            }
        }
        .onOpenURL { url in
            model.handleDeepLink(url)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(IslandifyAppModel())
}
