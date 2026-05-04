import Foundation

/// Pure functions that compute eye-health metrics from local SwiftData records.
/// No SwiftData / framework imports — input arrays are passed in by the caller.
/// This keeps the aggregator trivially testable and reusable across views and the widget.
enum ScreenTimeAggregator {

    // MARK: - Today's Metrics (PickupSession-based)

    /// Sum of pickup durations in `now`'s local-day window. Open pickups count their elapsed time.
    static func todayTotalScreenTime(
        pickups: [PickupSession],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> TimeInterval {
        todayPickups(pickups, now: now, calendar: calendar)
            .reduce(0) { $0 + clamp($1, to: now) }
    }

    /// Number of pickups today (open + closed).
    static func todayPickupCount(
        pickups: [PickupSession],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        todayPickups(pickups, now: now, calendar: calendar).count
    }

    /// Average pickup duration today, in seconds. 0 when there are no pickups.
    static func todayAveragePickupDuration(
        pickups: [PickupSession],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> TimeInterval {
        let today = todayPickups(pickups, now: now, calendar: calendar)
        guard !today.isEmpty else { return 0 }
        let total = today.reduce(0.0) { $0 + clamp($1, to: now) }
        return total / Double(today.count)
    }

    /// Longest single pickup today.
    static func todayLongestPickup(
        pickups: [PickupSession],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> TimeInterval {
        todayPickups(pickups, now: now, calendar: calendar)
            .map { clamp($0, to: now) }
            .max() ?? 0
    }

    /// Fraction of today's pickups whose duration is ≤ 20 minutes.
    /// Returns 1.0 when there are no pickups (perfect by default).
    static func today2020ComplianceRate(
        pickups: [PickupSession],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double {
        let today = todayPickups(pickups, now: now, calendar: calendar)
        guard !today.isEmpty else { return 1.0 }
        let twentyMin: TimeInterval = 20 * 60
        let compliant = today.filter { clamp($0, to: now) <= twentyMin }.count
        return Double(compliant) / Double(today.count)
    }

    // MARK: - Today's Metrics (other models)

    /// Number of completed eye exercises today.
    static func todayExerciseCount(
        records: [EyeExerciseRecord],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        records.filter { calendar.isDate($0.completedAt, inSameDayAs: now) }.count
    }

    /// Of today's break alerts (Sessions where wasAlerted=true), the fraction where
    /// the user took the break (BreakRecord.wasSkipped=false). Returns nil when no
    /// alerts have fired today (UI should render "—" instead of a percentage).
    static func todayBreakComplianceRate(
        sessions: [Session],
        breaks: [BreakRecord],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double? {
        let alertedToday = sessions.filter {
            $0.wasAlerted && calendar.isDate($0.startedAt, inSameDayAs: now)
        }
        guard !alertedToday.isEmpty else { return nil }
        let alertedIds = Set(alertedToday.map(\.id))
        let takenToday = breaks.filter { record in
            !record.wasSkipped &&
            calendar.isDate(record.completedAt, inSameDayAs: now) &&
            (record.session.map { alertedIds.contains($0.id) } ?? false)
        }
        return Double(takenToday.count) / Double(alertedToday.count)
    }

    // MARK: - Helpers

    /// Pickups whose start falls in the local day of `now`.
    private static func todayPickups(
        _ pickups: [PickupSession],
        now: Date,
        calendar: Calendar
    ) -> [PickupSession] {
        pickups.filter { calendar.isDate($0.startedAt, inSameDayAs: now) }
    }

    /// Effective duration. For closed pickups, the recorded value. For open
    /// pickups, elapsed time from `startedAt` to `now` (never negative).
    private static func clamp(_ pickup: PickupSession, to now: Date) -> TimeInterval {
        if let endedAt = pickup.endedAt {
            return max(0, endedAt.timeIntervalSince(pickup.startedAt))
        }
        return max(0, now.timeIntervalSince(pickup.startedAt))
    }
}
