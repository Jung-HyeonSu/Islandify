import Foundation

#if canImport(IslandifyDomain)
@testable import IslandifyDomain
#else
@testable import Islandify
#endif

#if canImport(XCTest)
import XCTest

final class RelationshipDomainTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var start: Date {
        calendar.date(from: DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2024, month: 2, day: 29, hour: 12))!
    }

    func testDPlus0AndDPlus1DifferOnStartDate() {
        let zero = RelationshipConfiguration(name: "Us", startDate: start, timeZoneIdentifier: "GMT", countingMode: .dPlus0)
        let one = RelationshipConfiguration(name: "Us", startDate: start, timeZoneIdentifier: "GMT", countingMode: .dPlus1)

        XCTAssertEqual(RelationshipCalculator.dayCount(for: zero, at: start, calendar: calendar), 0)
        XCTAssertEqual(RelationshipCalculator.dayCount(for: one, at: start, calendar: calendar), 1)
    }

    func testLeapYearDateCountingUsesCalendarDays() {
        let configuration = RelationshipConfiguration(name: "Us", startDate: start, timeZoneIdentifier: "GMT", countingMode: .dPlus0)
        let followingDay = calendar.date(byAdding: .day, value: 1, to: start)!
        let nextYear = calendar.date(from: DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2025, month: 2, day: 28, hour: 12))!

        XCTAssertEqual(RelationshipCalculator.dayCount(for: configuration, at: followingDay, calendar: calendar), 1)
        XCTAssertEqual(RelationshipCalculator.dayCount(for: configuration, at: nextYear, calendar: calendar), 365)
    }

    func testNextHundredAndAnnualMilestonesAreStrictlyFuture() {
        let configuration = RelationshipConfiguration(name: "Us", startDate: start, timeZoneIdentifier: "GMT", countingMode: .dPlus1)
        let date = calendar.date(byAdding: .day, value: 99, to: start)!
        let snapshot = RelationshipCalculator.snapshot(for: configuration, at: date, calendar: calendar)

        XCTAssertEqual(snapshot.dayCount, 100)
        XCTAssertEqual(snapshot.nextDayMilestone?.value, 200)
        XCTAssertGreaterThan(snapshot.nextDayMilestone?.date ?? .distantPast, date)
        XCTAssertGreaterThan(snapshot.nextAnnualMilestone?.date ?? .distantPast, date)
    }

    func testNotificationPlansRemainLocalAndDeterministic() {
        let configuration = RelationshipConfiguration(name: "Us", startDate: start, timeZoneIdentifier: "GMT", countingMode: .dPlus1)
        let plans = RelationshipNotificationPlan.upcoming(for: configuration, at: start)

        XCTAssertEqual(plans.count, 2)
        XCTAssertTrue(plans.allSatisfy { $0.identifier.contains(configuration.id.uuidString) })
    }
}
#endif
