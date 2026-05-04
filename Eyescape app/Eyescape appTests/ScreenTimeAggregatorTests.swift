//
//  ScreenTimeAggregatorTests.swift
//  Eyescape appTests
//
//  Pure-function tests for ScreenTimeAggregator. No SwiftData needed —
//  PickupSession is constructed directly and mutated for fixtures.
//

import XCTest
@testable import Eyescape_app

final class ScreenTimeAggregatorTests: XCTestCase {

    // Fixed reference instant: 2026-05-04 14:00 local
    private let now = Calendar.current.date(from: DateComponents(
        year: 2026, month: 5, day: 4, hour: 14, minute: 0
    ))!

    // Helpers ---------------------------------------------------------

    private func pickup(startMinutesBeforeNow: Int, durationSec: Int) -> PickupSession {
        let p = PickupSession(
            startedAt: now.addingTimeInterval(-Double(startMinutesBeforeNow) * 60)
        )
        p.endedAt = p.startedAt.addingTimeInterval(Double(durationSec))
        return p
    }

    private func openPickup(startMinutesBeforeNow: Int) -> PickupSession {
        PickupSession(startedAt: now.addingTimeInterval(-Double(startMinutesBeforeNow) * 60))
    }

    // Tests -----------------------------------------------------------

    func testEmptyDataReturnsZeros() {
        XCTAssertEqual(ScreenTimeAggregator.todayTotalScreenTime(pickups: [], now: now), 0)
        XCTAssertEqual(ScreenTimeAggregator.todayPickupCount(pickups: [], now: now), 0)
        XCTAssertEqual(ScreenTimeAggregator.todayAveragePickupDuration(pickups: [], now: now), 0)
        XCTAssertEqual(ScreenTimeAggregator.todayLongestPickup(pickups: [], now: now), 0)
    }

    func testEmptyData2020RateIsPerfect() {
        // No pickups = no violations = perfect compliance (1.0).
        XCTAssertEqual(ScreenTimeAggregator.today2020ComplianceRate(pickups: [], now: now), 1.0)
    }

    func testAllPickupsUnder20MinAreCompliant() {
        let pickups = [
            pickup(startMinutesBeforeNow: 60, durationSec: 5 * 60),
            pickup(startMinutesBeforeNow: 30, durationSec: 19 * 60),
            pickup(startMinutesBeforeNow: 10, durationSec: 60),
        ]
        XCTAssertEqual(ScreenTimeAggregator.today2020ComplianceRate(pickups: pickups, now: now), 1.0)
    }

    func testAllPickupsOver20MinAreNonCompliant() {
        let pickups = [
            pickup(startMinutesBeforeNow: 90, durationSec: 25 * 60),
            pickup(startMinutesBeforeNow: 50, durationSec: 30 * 60),
        ]
        XCTAssertEqual(ScreenTimeAggregator.today2020ComplianceRate(pickups: pickups, now: now), 0.0)
    }

    func testMixedComplianceRate() {
        // 2 of 4 pickups ≤ 20min → 0.5.
        let pickups = [
            pickup(startMinutesBeforeNow: 120, durationSec: 10 * 60),
            pickup(startMinutesBeforeNow: 100, durationSec: 25 * 60),
            pickup(startMinutesBeforeNow: 60,  durationSec: 19 * 60),
            pickup(startMinutesBeforeNow: 30,  durationSec: 21 * 60),
        ]
        XCTAssertEqual(ScreenTimeAggregator.today2020ComplianceRate(pickups: pickups, now: now), 0.5)
    }

    func testYesterdayPickupsAreExcluded() {
        // 30h ago = yesterday's local day.
        let yesterday = PickupSession(startedAt: now.addingTimeInterval(-30 * 3600))
        yesterday.endedAt = yesterday.startedAt.addingTimeInterval(60 * 60)

        let today = pickup(startMinutesBeforeNow: 30, durationSec: 5 * 60)

        let pickups = [yesterday, today]
        XCTAssertEqual(ScreenTimeAggregator.todayPickupCount(pickups: pickups, now: now), 1)
        XCTAssertEqual(ScreenTimeAggregator.todayTotalScreenTime(pickups: pickups, now: now), 5 * 60)
    }

    func testAggregatesAcrossMultiplePickups() {
        let pickups = [
            pickup(startMinutesBeforeNow: 200, durationSec: 600),   // 10min
            pickup(startMinutesBeforeNow: 100, durationSec: 1200),  // 20min
            pickup(startMinutesBeforeNow: 30,  durationSec: 60),    // 1min
        ]
        XCTAssertEqual(ScreenTimeAggregator.todayTotalScreenTime(pickups: pickups, now: now), 1860)
        XCTAssertEqual(ScreenTimeAggregator.todayPickupCount(pickups: pickups, now: now), 3)
        XCTAssertEqual(
            ScreenTimeAggregator.todayAveragePickupDuration(pickups: pickups, now: now),
            620,
            accuracy: 0.5
        )
        XCTAssertEqual(ScreenTimeAggregator.todayLongestPickup(pickups: pickups, now: now), 1200)
    }

    func testOpenPickupCountsElapsedTime() {
        // Open pickup started 5 minutes before `now`.
        let open = openPickup(startMinutesBeforeNow: 5)
        let total = ScreenTimeAggregator.todayTotalScreenTime(pickups: [open], now: now)
        XCTAssertEqual(total, 5 * 60, accuracy: 0.5)
        XCTAssertEqual(ScreenTimeAggregator.todayPickupCount(pickups: [open], now: now), 1)
    }

    func testExerciseCountTodayOnly() {
        let calendar = Calendar.current
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: now)!
        let records = [
            EyeExerciseRecord(completedAt: now.addingTimeInterval(-3600), durationSeconds: 120),
            EyeExerciseRecord(completedAt: now.addingTimeInterval(-1800), durationSeconds: 180),
            EyeExerciseRecord(completedAt: yesterdayDate, durationSeconds: 300),
        ]
        XCTAssertEqual(ScreenTimeAggregator.todayExerciseCount(records: records, now: now), 2)
    }

    func testBreakComplianceRateNilWhenNoAlerts() {
        let session = Session(startedAt: now.addingTimeInterval(-3600))
        // wasAlerted defaults false
        let rate = ScreenTimeAggregator.todayBreakComplianceRate(
            sessions: [session], breaks: [], now: now
        )
        XCTAssertNil(rate)
    }

    func testBreakComplianceRateMixed() {
        // Two alerted sessions today: one with a taken break, one with a skipped break.
        let s1 = Session(startedAt: now.addingTimeInterval(-7200))
        s1.wasAlerted = true
        let s2 = Session(startedAt: now.addingTimeInterval(-3600))
        s2.wasAlerted = true

        let taken = BreakRecord(
            completedAt: now.addingTimeInterval(-7000),
            wasSkipped: false,
            session: s1
        )
        let skipped = BreakRecord(
            completedAt: now.addingTimeInterval(-3500),
            wasSkipped: true,
            session: s2
        )

        let rate = ScreenTimeAggregator.todayBreakComplianceRate(
            sessions: [s1, s2], breaks: [taken, skipped], now: now
        )
        XCTAssertEqual(rate, 0.5)
    }
}
