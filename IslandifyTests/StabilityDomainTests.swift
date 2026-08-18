import Foundation

#if canImport(IslandifyDomain)
@testable import IslandifyDomain
#else
@testable import Islandify
#endif

#if canImport(XCTest)
import XCTest

final class StabilityDomainTests: XCTestCase {
    func testExpiredTimerReconcilesFromAbsoluteEndDate() throws {
        let origin = Date(timeIntervalSince1970: 1_700_000_000)
        let configuration = try TimerConfiguration(name: "Short", duration: 60)
        let state = TimerEngine.start(configuration: configuration, at: origin)

        let reconciled = TimerEngine.reconcile(state, at: origin.addingTimeInterval(60))

        XCTAssertEqual(reconciled.phase, .completed)
        XCTAssertEqual(TimerEngine.snapshot(for: reconciled, at: origin.addingTimeInterval(120)).progress, 1)
    }

    func testFutureStoreVersionIsRejectedWithoutDataLoss() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("IslandifyTests-\(UUID().uuidString)", isDirectory: true)
        let store = JSONLocalStore(directoryURL: directory)
        try store.save(PreviewActivity.sample, forKey: "future", schemaVersion: IslandifyDataModel.currentVersion + 1)

        XCTAssertThrowsError(try store.load(PreviewActivity.self, forKey: "future")) { error in
            XCTAssertEqual(error as? LocalStoreError, .invalidSchemaVersion(IslandifyDataModel.currentVersion + 1))
        }
    }

    func testLocationFallbackStatesAreExplicit() {
        XCTAssertFalse(LocationAuthorizationState.denied.canCollectLocation)
        XCTAssertFalse(LocationAuthorizationState.restricted.canCollectLocation)
        XCTAssertFalse(LocationAuthorizationState.unavailable.canCollectLocation)
        XCTAssertTrue(LocationAuthorizationState.authorizedWhenInUse.canCollectLocation)
    }

    func testTerminalPresentationAndTruncationRemainAccessible() {
        let state = ActivityPresentationState(
            kind: .timer,
            phase: .completed,
            title: String(repeating: "Long title ", count: 5),
            icon: .flame,
            palette: IslandifyTheme.neonTimer.palette,
            primaryValue: "Done",
            compactLeading: String(repeating: "L", count: 30),
            compactTrailing: String(repeating: "T", count: 30),
            completionMessage: "Complete",
            accessibilityLabel: "Completed timer"
        )

        let compact = ActivityPresentationRenderer.render(state, on: .compact)
        let lockScreen = ActivityPresentationRenderer.render(state, on: .lockScreen)
        XCTAssertLessThanOrEqual(compact.leadingText?.count ?? 0, 10)
        XCTAssertEqual(lockScreen.accessibilityLabel, "Completed timer")
    }
}
#endif
