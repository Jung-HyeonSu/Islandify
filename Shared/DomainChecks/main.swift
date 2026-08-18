import Foundation
import IslandifyDomain

@main
struct IslandifyDomainChecks {
    static func main() throws {
        let origin = Date(timeIntervalSince1970: 1_700_000_000)

        let timerConfiguration = try TimerConfiguration(name: "Check", duration: 25 * 60)
        let timer = TimerEngine.start(configuration: timerConfiguration, at: origin)
        let paused = try TimerEngine.pause(timer, at: origin.addingTimeInterval(5 * 60))
        let resumed = try TimerEngine.resume(paused, at: origin.addingTimeInterval(100))
        let timerSnapshot = TimerEngine.snapshot(for: resumed, at: origin.addingTimeInterval(100))
        precondition(timerSnapshot.remaining == 20 * 60)

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let departure = utc.date(from: DateComponents(year: 2025, month: 8, day: 1, hour: 18, minute: 45))!
        let travelConfiguration = try TravelConfiguration(tripName: "Check trip", destination: "Seoul", departureDate: departure, timeZoneIdentifier: "UTC")
        let travelState = TravelCalculator.state(for: travelConfiguration, at: utc.date(from: DateComponents(year: 2025, month: 7, day: 25))!, calendar: utc)
        precondition(travelState.kind == .d7)

        let relationshipConfiguration = RelationshipConfiguration(name: "Us", startDate: origin, timeZoneIdentifier: "UTC", countingMode: .dPlus1)
        precondition(RelationshipCalculator.dayCount(for: relationshipConfiguration, at: origin) == 1)
        precondition(RelationshipCalculator.nextDayMilestone(for: relationshipConfiguration, at: origin).value == 100)

        let runConfiguration = RunningConfiguration()
        var run = RunningCalculator.start(configuration: runConfiguration, at: origin)
        run = RunningCalculator.addSample(run, sample: LocationSample(timestamp: origin, latitude: 37.5665, longitude: 126.9780))
        run = RunningCalculator.addSample(run, sample: LocationSample(timestamp: origin.addingTimeInterval(60), latitude: 37.5750, longitude: 126.9780))
        precondition(RunningCalculator.snapshot(for: run, at: origin.addingTimeInterval(60)).distanceMeters > 900)

        let composition = PresentationComposer.previewState(for: .timer, configuration: .default(for: .timer))
        precondition(ActivitySurface.allCases.allSatisfy { !ActivityPresentationRenderer.render(composition, on: $0).primaryText.isEmpty })

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Islandify-domain-check-\(UUID().uuidString)", isDirectory: true)
        let store = JSONLocalStore(directoryURL: directory, migrations: [1: { _, data in data }])
        let preview = PreviewActivity.sample
        try store.save(preview, forKey: "preview", schemaVersion: 1)
        let restored = try store.load(PreviewActivity.self, forKey: "preview")
        precondition(restored == preview)
        try? store.removeValue(forKey: "preview")
        try? FileManager.default.removeItem(at: directory)

        print("Islandify domain checks: OK")
    }
}
