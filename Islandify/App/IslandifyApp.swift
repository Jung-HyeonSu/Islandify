import SwiftUI

@main
struct IslandifyApp: App {
    @StateObject private var model = IslandifyAppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
