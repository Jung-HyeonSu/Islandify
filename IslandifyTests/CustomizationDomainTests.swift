import Foundation

#if canImport(IslandifyDomain)
@testable import IslandifyDomain
#else
@testable import Islandify
#endif

#if canImport(XCTest)
import XCTest

final class CustomizationDomainTests: XCTestCase {
    func testPreviewUsesOnlyPredefinedSlotsAcrossAllSurfaces() {
        let configuration = PresentationConfiguration(
            title: "Focus",
            description: "Deep work",
            icon: .flame,
            theme: .neonTimer,
            numberFormat: .compactDuration,
            progressStyle: .circle,
            alignment: .center,
            compactLeading: .icon,
            compactTrailing: .primaryValue,
            expandedDetails: [.title, .primaryValue, .progress],
            completionMessage: "Done"
        )
        let state = PresentationComposer.previewState(for: .timer, configuration: configuration)

        XCTAssertEqual(state.compactLeading, "flame.fill")
        XCTAssertEqual(state.compactTrailing, "24:58")
        XCTAssertEqual(ActivitySurface.allCases.count, 4)
        XCTAssertTrue(ActivitySurface.allCases.allSatisfy { !ActivityPresentationRenderer.render(state, on: $0).primaryText.isEmpty })
    }

    func testValidationNormalizesUserTextWithoutAllowingArbitraryRegions() {
        let configuration = PresentationConfiguration(
            title: String(repeating: "x", count: 50),
            description: String(repeating: "d", count: 100),
            icon: .heart,
            theme: .pastelCouple,
            numberFormat: .dayCount,
            progressStyle: .dots,
            expandedDetails: Array(repeating: .title, count: 10),
            completionMessage: String(repeating: "c", count: 100)
        )

        XCTAssertFalse(PresentationComposer.validate(configuration).isEmpty)
        let normalized = PresentationComposer.normalized(configuration)
        XCTAssertLessThanOrEqual(normalized.title.count, 32)
        XCTAssertLessThanOrEqual(normalized.description.count, 80)
        XCTAssertLessThanOrEqual(normalized.expandedDetails.count, 4)
        XCTAssertLessThanOrEqual(normalized.completionMessage.count, 80)
    }
}
#endif
