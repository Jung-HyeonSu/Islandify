import Foundation

#if canImport(IslandifyDomain)
@testable import IslandifyDomain
#else
@testable import Islandify
#endif

#if canImport(XCTest)
import XCTest

final class RunningDomainTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 1_700_000_000)

    private func sample(_ seconds: TimeInterval, latitude: Double, longitude: Double) -> LocationSample {
        LocationSample(timestamp: origin.addingTimeInterval(seconds), latitude: latitude, longitude: longitude)
    }

    func testInjectedLocationSamplesProduceDeterministicDistance() {
        let configuration = RunningConfiguration()
        var state = RunningCalculator.start(configuration: configuration, at: origin)
        state = RunningCalculator.addSample(state, sample: sample(0, latitude: 37.5665, longitude: 126.9780))
        state = RunningCalculator.addSample(state, sample: sample(60, latitude: 37.5750, longitude: 126.9780))

        let snapshot = RunningCalculator.snapshot(for: state, at: origin.addingTimeInterval(60))

        XCTAssertGreaterThan(snapshot.distanceMeters, 900)
        XCTAssertLessThan(snapshot.distanceMeters, 1_100)
        XCTAssertNotNil(snapshot.averagePaceSecondsPerKilometer)
    }

    func testPauseResumeExcludesPausedTimeFromExerciseDuration() {
        let configuration = RunningConfiguration()
        let state = RunningCalculator.start(configuration: configuration, at: origin)
        let paused = RunningCalculator.pause(state, at: origin.addingTimeInterval(60))
        let resumed = RunningCalculator.resume(paused, at: origin.addingTimeInterval(600))
        let snapshot = RunningCalculator.snapshot(for: resumed, at: origin.addingTimeInterval(660))

        XCTAssertEqual(snapshot.elapsed, 120, accuracy: 0.001)
    }

    func testPoorLocationSamplesAreIgnored() {
        let configuration = RunningConfiguration()
        let state = RunningCalculator.start(configuration: configuration, at: origin)
        let invalid = LocationSample(timestamp: origin, latitude: 200, longitude: 0, horizontalAccuracy: 5)
        let updated = RunningCalculator.addSample(state, sample: invalid)

        XCTAssertEqual(updated.distanceMeters, 0, accuracy: 0.001)
        XCTAssertNil(updated.lastSample)
    }

    func testFinishProducesLocalRunRecordAndCalories() {
        let configuration = RunningConfiguration(weightKg: 70)
        var state = RunningCalculator.start(configuration: configuration, at: origin)
        state = RunningCalculator.finish(state, at: origin.addingTimeInterval(30 * 60))
        let record = RunningCalculator.record(for: state, at: origin.addingTimeInterval(30 * 60), memo: "Easy run")

        XCTAssertEqual(record?.duration, 30 * 60, accuracy: 0.001)
        XCTAssertEqual(record?.memo, "Easy run")
        XCTAssertGreaterThan(record?.calories ?? 0, 0)
    }

    func testPaceAndFormattingUseMinutesPerKilometer() {
        XCTAssertEqual(RunningCalculator.pace(seconds: 600, distanceMeters: 2_000), 300, accuracy: 0.001)
        XCTAssertEqual(IslandifyTimeFormatter.pace(secondsPerKilometer: 300), "05:00/km")
    }
}
#endif
