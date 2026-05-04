import Foundation
import SwiftData

/// One foreground period of the Eyescape app: opened to backgrounded.
///
/// Distinct from `Session` (which is the 20-min protect cycle).
/// Tracks granular pickup behavior so the aggregator can compute
/// pickup count, average duration, longest pickup, and 20-min compliance
/// even when no protect Session is active (eg. during sleep hours).
///
/// Wired in `SessionManager.handleForeground` / `handleBackground`.
/// Sub-5-second pickups are discarded as accidental wakes.
@Model
final class PickupSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    /// Optional link to the protect `Session` active during this pickup.
    var sessionId: UUID?

    init(startedAt: Date = .now, sessionId: UUID? = nil) {
        self.id = UUID()
        self.startedAt = startedAt
        self.endedAt = nil
        self.sessionId = sessionId
    }

    /// Seconds between startedAt and endedAt. For an open pickup, returns elapsed seconds.
    var duration: TimeInterval {
        guard let endedAt else { return Date.now.timeIntervalSince(startedAt) }
        return endedAt.timeIntervalSince(startedAt)
    }

    var isClosed: Bool { endedAt != nil }
}
