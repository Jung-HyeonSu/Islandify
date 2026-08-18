import Foundation

#if canImport(IslandifyDomain)
@testable import IslandifyDomain
#else
@testable import Islandify
#endif

#if canImport(XCTest)
import XCTest

final class TimerDomainTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 1_700_000_000)

    func testDurationRangeIsOneMinuteThroughEightHours() throws {
        XCTAssertThrowsError(try TimerConfiguration(name: "Too short", duration: 59)) { error in
            XCTAssertEqual(error as? TimerValidationError, .durationTooShort)
        }
        XCTAssertNoThrow(try TimerConfiguration(name: "Minimum", duration: 60))
        XCTAssertNoThrow(try TimerConfiguration(name: "Maximum", duration: 8 * 60 * 60))
        XCTAssertThrowsError(try TimerConfiguration(name: "Too long", duration: 8 * 60 * 60 + 1)) { error in
            XCTAssertEqual(error as? TimerValidationError, .durationTooLong)
        }
    }

    func testAbsoluteDateSnapshotSurvivesSuspension() throws {
        let configuration = try TimerConfiguration(name: "Focus", duration: 25 * 60)
        let state = TimerEngine.start(configuration: configuration, at: origin)

        let snapshot = TimerEngine.snapshot(for: state, at: origin.addingTimeInterval(10 * 60))

        XCTAssertEqual(snapshot.phase, .active)
        XCTAssertEqual(snapshot.remaining, 15 * 60, accuracy: 0.001)
        XCTAssertEqual(snapshot.progress, 0.4, accuracy: 0.001)
    }

    func testPauseAndResumePreserveRemainingDuration() throws {
        let configuration = try TimerConfiguration(name: "Focus", duration: 25 * 60)
        let started = TimerEngine.start(configuration: configuration, at: origin)
        let paused = try TimerEngine.pause(started, at: origin.addingTimeInterval(5 * 60))
        let resumed = try TimerEngine.resume(paused, at: origin.addingTimeInterval(2 * 60 * 60))

        XCTAssertEqual(paused.phase, .paused)
        XCTAssertEqual(paused.pausedRemaining ?? -1, 20 * 60, accuracy: 0.001)
        XCTAssertEqual(resumed.endDate, origin.addingTimeInterval(2 * 60 * 60 + 20 * 60))
    }

    func testResetCompletionAndAddMinute() throws {
        let configuration = try TimerConfiguration(name: "Focus", duration: 60)
        let started = TimerEngine.start(configuration: configuration, at: origin)
        let extended = try TimerEngine.addOneMinute(started, at: origin)
        XCTAssertEqual(extended.configuration.duration, 120, accuracy: 0.001)
        XCTAssertEqual(extended.endDate, origin.addingTimeInterval(120))

        let completed = TimerEngine.reconcile(extended, at: origin.addingTimeInterval(120))
        XCTAssertEqual(completed.phase, .completed)
        XCTAssertEqual(TimerEngine.snapshot(for: completed, at: origin.addingTimeInterval(120)).progress, 1)
        XCTAssertEqual(TimerEngine.reset(completed).phase, .configured)
    }

    func testPresentationUsesCompactTimeAndAccessibilityLabel() throws {
        let configuration = try TimerConfiguration(name: "Deep work", duration: 60 * 60)
        let state = TimerEngine.start(configuration: configuration, at: origin)
        let presentation = TimerEngine.presentation(for: state, at: origin.addingTimeInterval(62))

        XCTAssertEqual(presentation.primaryValue, "58:58")
        XCTAssertEqual(presentation.compactTrailing, "58:58")
        XCTAssertTrue(presentation.accessibilityLabel.contains("Deep work"))
    }
}
#endif
