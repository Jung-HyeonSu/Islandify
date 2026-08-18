import Foundation

#if canImport(IslandifyDomain)
@testable import IslandifyDomain
#else
@testable import Islandify
#endif

#if canImport(XCTest)
import XCTest

final class PresentationTests: XCTestCase {
    func testAllBaselineThemesMeetContrastRequirement() {
        XCTAssertEqual(IslandifyTheme.allCases.count, 6)
        XCTAssertTrue(IslandifyTheme.allCases.allSatisfy { $0.palette.isContrastSafe })
    }

    func testRendererProvidesEveryRequiredSurface() {
        let state = ActivityPresentationState(
            kind: .timer,
            phase: .active,
            title: "Focus",
            icon: .flame,
            palette: IslandifyTheme.neonTimer.palette,
            primaryValue: "24:58",
            compactLeading: "🔥",
            compactTrailing: "24:58"
        )

        for surface in ActivitySurface.allCases {
            let rendered = ActivityPresentationRenderer.render(state, on: surface)
            XCTAssertEqual(rendered.surface, surface)
            XCTAssertFalse(rendered.primaryText.isEmpty)
            XCTAssertFalse(rendered.accessibilityLabel.isEmpty)
        }
    }

    func testCompactValuesAreTruncatedForSystemSlots() {
        let state = ActivityPresentationState(
            kind: .timer,
            phase: .active,
            title: "A very long activity title",
            icon: .flame,
            palette: IslandifyTheme.neonTimer.palette,
            primaryValue: "24:58",
            compactLeading: "A leading value that cannot fit",
            compactTrailing: "A trailing value that cannot fit"
        )

        let compact = ActivityPresentationRenderer.render(state, on: .compact)
        XCTAssertLessThanOrEqual(compact.leadingText?.count ?? 0, 10)
        XCTAssertLessThanOrEqual(compact.trailingText?.count ?? 0, 10)
    }
}
#endif
