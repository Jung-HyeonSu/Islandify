import Foundation

#if canImport(IslandifyDomain)
@testable import IslandifyDomain
#else
@testable import Islandify
#endif

#if canImport(XCTest)
import XCTest

final class LocalStoreTests: XCTestCase {
    func testRoundTripsVersionedCodableValue() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("IslandifyTests-\(UUID().uuidString)", isDirectory: true)
        let store = JSONLocalStore(directoryURL: directory)
        let value = PreviewActivity(title: "Timer", subtitle: "Focus", primaryValue: "01:00")

        try store.save(value, forKey: "preview")
        let restored = try store.load(PreviewActivity.self, forKey: "preview")

        XCTAssertEqual(restored, value)
        try store.removeValue(forKey: "preview")
        XCTAssertNil(try store.load(PreviewActivity.self, forKey: "preview"))
    }

    func testMissingValueIsNil() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("IslandifyTests-\(UUID().uuidString)", isDirectory: true)
        let store = JSONLocalStore(directoryURL: directory)

        XCTAssertNil(try store.load(PreviewActivity.self, forKey: "missing"))
    }

    func testLoadsSchemaOneValueThroughExplicitMigrationPath() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("IslandifyTests-\(UUID().uuidString)", isDirectory: true)
        let legacyStore = JSONLocalStore(directoryURL: directory)
        let value = PreviewActivity(title: "Legacy", subtitle: "Migrated", primaryValue: "00:30")
        try legacyStore.save(value, forKey: "legacy", schemaVersion: 1)

        let migratedStore = JSONLocalStore(directoryURL: directory, migrations: [1: { _, data in data }])
        XCTAssertEqual(try migratedStore.load(PreviewActivity.self, forKey: "legacy"), value)
    }
}
#endif
