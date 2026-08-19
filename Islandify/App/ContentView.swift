import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: IslandifyTab = .home
    @State private var showStyle = false

    var body: some View {
        let copy = IslandifyCopy.current
        NavigationStack {
            TabView(selection: $selectedTab) {
                HomeDashboardView(selectedTab: $selectedTab, showStyle: $showStyle)
                    .tabItem { Label(homeTabLabel, systemImage: "house.fill") }
                    .tag(IslandifyTab.home)
                TimerFeatureView()
                    .tabItem { Label(copy.timer, systemImage: "timer") }
                    .tag(IslandifyTab.timer)
                TravelFeatureView()
                    .tabItem { Label(copy.travel, systemImage: "airplane.departure") }
                    .tag(IslandifyTab.travel)
                RelationshipFeatureView()
                    .tabItem { Label(copy.relationship, systemImage: "heart.fill") }
                    .tag(IslandifyTab.relationship)
                RunningFeatureView()
                    .tabItem { Label(copy.running, systemImage: "figure.run") }
                    .tag(IslandifyTab.running)
            }
            .tint(IslandifyBrightPalette.accent)
            .toolbarBackground(IslandifyBrightPalette.surface, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.light, for: .tabBar)
            .background(IslandifyBrightPalette.background.ignoresSafeArea())
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showStyle) {
            NavigationStack {
                CustomizationFeatureView()
                    .navigationTitle(copy.style)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(IslandifyBrightPalette.surface, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }
            .tint(IslandifyBrightPalette.lavender)
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

    private var homeTabLabel: String {
        IslandifyLanguage.current == .korean ? "오늘" : "Today"
    }
}

#Preview {
    ContentView()
        .environmentObject(IslandifyAppModel())
}
