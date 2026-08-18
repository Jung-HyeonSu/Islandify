import Foundation

#if canImport(IslandifyDomain)
@testable import IslandifyDomain
#else
@testable import Islandify
#endif

#if canImport(XCTest)
import XCTest

final class TravelDomainTests: XCTestCase {
    private func calendar(timeZoneIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier)!
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        _ second: Int = 0,
        in calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        ))!
    }

    func testCalendarDayBoundariesAndMilestonesUseDepartureTimezone() throws {
        let utc = calendar(timeZoneIdentifier: "UTC")
        let departure = date(2025, 7, 31, 9, in: utc)
        let configuration = try TravelConfiguration(
            tripName: "Summer trip",
            destination: "Paris",
            departureDate: departure,
            timeZoneIdentifier: "UTC"
        )

        let d30 = TravelCalculator.state(
            for: configuration,
            at: date(2025, 7, 1, 12, in: utc),
            calendar: utc
        )
        let d7 = TravelCalculator.state(
            for: configuration,
            at: date(2025, 7, 24, 12, in: utc),
            calendar: utc
        )
        let d1 = TravelCalculator.state(
            for: configuration,
            at: date(2025, 7, 30, 23, 59, 59, in: utc),
            calendar: utc
        )
        let dDay = TravelCalculator.state(
            for: configuration,
            at: date(2025, 7, 31, 0, in: utc),
            calendar: utc
        )

        XCTAssertEqual(d30.kind, .d30)
        XCTAssertEqual(d30.label, "D-30")
        XCTAssertEqual(d7.kind, .d7)
        XCTAssertEqual(d7.label, "D-7")
        XCTAssertEqual(d1.kind, .d1)
        XCTAssertEqual(d1.label, "D-1")
        XCTAssertEqual(dDay.kind, .dDay)
        XCTAssertEqual(dDay.label, "D-DAY")
    }

    func testDepartureDayProvidesDeterministicHourAndMinuteCountdown() throws {
        let utc = calendar(timeZoneIdentifier: "UTC")
        let departure = date(2025, 8, 1, 18, 45, in: utc)
        let configuration = try TravelConfiguration(
            tripName: "Evening flight",
            destination: "Seoul",
            departureDate: departure,
            timeZoneIdentifier: "UTC"
        )

        let state = TravelCalculator.state(
            for: configuration,
            at: date(2025, 8, 1, 16, 12, 30, in: utc),
            calendar: utc
        )

        XCTAssertEqual(state.kind, .dDay)
        XCTAssertEqual(state.remainingUntilDeparture ?? -1, 9_150, accuracy: 0.001)
        XCTAssertEqual(state.hoursRemaining, 2)
        XCTAssertEqual(state.minutesRemaining, 32)
        XCTAssertEqual(state.countdownText, "02:32")
        XCTAssertEqual(state.displayValue, "2시간 32분")
    }

    func testPastDepartureIsThePostDepartureTravelStartedState() throws {
        let utc = calendar(timeZoneIdentifier: "UTC")
        let departure = date(2025, 8, 1, 9, in: utc)
        let configuration = try TravelConfiguration(
            tripName: "Past trip",
            destination: "Busan",
            departureDate: departure,
            timeZoneIdentifier: "UTC"
        )

        let state = TravelCalculator.state(
            for: configuration,
            at: date(2025, 8, 3, in: utc),
            calendar: utc
        )

        XCTAssertEqual(state.kind, .started)
        XCTAssertTrue(state.isPostDeparture)
        XCTAssertEqual(state.label, "여행 시작")
        XCTAssertNil(state.countdown)
    }

    func testPersistedTimezoneControlsDayBoundaryAndCountdown() throws {
        let tokyo = calendar(timeZoneIdentifier: "Asia/Tokyo")
        let utc = calendar(timeZoneIdentifier: "UTC")
        let departure = date(2025, 1, 2, 0, 30, in: tokyo)
        let configuration = try TravelConfiguration(
            tripName: "New year trip",
            destination: "Tokyo",
            departureDate: departure,
            timeZoneIdentifier: "Asia/Tokyo"
        )

        // The injected calendar is UTC, but the persisted departure timezone makes
        // this 00:00 on the departure day in Tokyo.
        let state = TravelCalculator.state(
            for: configuration,
            at: date(2025, 1, 1, 15, in: utc),
            calendar: utc
        )

        XCTAssertEqual(state.kind, .dDay)
        XCTAssertEqual(state.hoursRemaining, 0)
        XCTAssertEqual(state.minutesRemaining, 30)
        XCTAssertEqual(configuration.departureTimeZoneIdentifier, "Asia/Tokyo")
    }

    func testConfigurationRoundTripPreservesIANATimezoneIdentifier() throws {
        let configuration = try TravelConfiguration(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            tripName: "Round trip",
            destination: "New York",
            departureDate: Date(timeIntervalSince1970: 1_750_000_000),
            timeZoneIdentifier: "America/New_York"
        )

        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(TravelConfiguration.self, from: data)

        XCTAssertEqual(decoded, configuration)
        XCTAssertEqual(decoded.timeZoneIdentifier, "America/New_York")
    }
}
#endif
