import Foundation
import SwiftData

/// Represents one eye-protection session (a 20-min work block).
///
/// State transitions (see SessionManager):
///   IDLE → ACTIVE: startSession() — creates this record
///   ACTIVE → PAUSED: pauseSession() — writes pausedAt + remainingSecondsAtPause
///   PAUSED → ACTIVE: resumeSession() — clears pausedAt, recalculates targetDate
///   ACTIVE → ALERTING: notification fires — SessionManager moves to .alerting
///   ALERTING → IDLE: confirmBreak() / skipBreak() — writes endedAt; BreakRecord on confirm or skip
@Model
final class Session {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?                   // written on endSession(); nil if session still active
    var intervalMinutes: Int             // 20 (Free) or 5-60 (Pro custom)
    var targetDate: Date                 // startedAt + intervalMinutes*60; recalculated on resume
    var isPaused: Bool
    var pausedAt: Date?
    var remainingSecondsAtPause: Int?    // snapshot for resume recalculation
    var wasAlerted: Bool                 // true when session first transitions to .alerting state
                                         // used by PetMoodEngine as the "triggered breaks" denominator

    @Relationship(deleteRule: .cascade)
    var breaks: [BreakRecord] = []

    init(
        startedAt: Date = .now,
        intervalMinutes: Int = 20
    ) {
        self.id = UUID()
        self.startedAt = startedAt
        self.endedAt = nil
        self.intervalMinutes = intervalMinutes
        self.targetDate = startedAt.addingTimeInterval(Double(intervalMinutes) * 60)
        self.isPaused = false
        self.pausedAt = nil
        self.remainingSecondsAtPause = nil
        self.wasAlerted = false
    }

    /// Duration of this session in seconds. Returns nil if session hasn't ended yet.
    var duration: TimeInterval? {
        guard let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }
}
