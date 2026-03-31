import Foundation
import SwiftData

/// A completed or skipped eye break.
///
/// Written by `SessionManager.confirmBreak()` (`wasSkipped: false`) and
/// `SessionManager.skipBreak()` (`wasSkipped: true`).
@Model
final class BreakRecord {
    var id: UUID
    var completedAt: Date
    var wasSkipped: Bool    // true if user tapped "Skip"; false = full 20s completed

    @Relationship
    var session: Session?

    init(completedAt: Date = .now, wasSkipped: Bool = false, session: Session? = nil) {
        self.id = UUID()
        self.completedAt = completedAt
        self.wasSkipped = wasSkipped
        self.session = session
    }
}
