import SwiftUI
import WidgetKit

struct IslandifyWidget: Widget {
    let kind = "IslandifyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: IslandifyWidgetProvider()) { entry in
            IslandifyWidgetView(entry: entry)
        }
        .configurationDisplayName("Islandify")
        .description("A glanceable view of your current activity.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct IslandifyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> IslandifyWidgetEntry {
        IslandifyWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (IslandifyWidgetEntry) -> Void) {
        completion(IslandifyWidgetEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IslandifyWidgetEntry>) -> Void) {
        let entry = IslandifyWidgetEntry(date: .now)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct IslandifyWidgetEntry: TimelineEntry {
    let date: Date
}

struct IslandifyWidgetView: View {
    let entry: IslandifyWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Islandify")
                .font(.headline)
            Text("No active activity")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Islandify, no active activity")
    }
}

@main
struct IslandifyWidgetBundle: WidgetBundle {
    var body: some Widget {
        IslandifyWidget()
    }
}
