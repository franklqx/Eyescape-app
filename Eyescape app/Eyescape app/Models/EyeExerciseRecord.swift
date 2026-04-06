import Foundation
import SwiftData

/// A completed eye exercise session.
///
/// Schema created in Week 1 so PetMoodEngine can query it from day one.
/// EyeExerciseManager (the UI + countdown flow) ships in Week 5+.
/// Until then this table is empty and PetMoodEngine treats the exercise bonus as 0.
@Model
final class EyeExerciseRecord {
    var id: UUID
    var completedAt: Date
    var durationSeconds: Int    // how long the user spent on the exercise

    init(completedAt: Date = .now, durationSeconds: Int = 0) {
        self.id = UUID()
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
    }
}
