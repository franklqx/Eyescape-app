import Foundation
import Observation
import SwiftData

/// Computes the user's virtual pet mood from 7-day rolling eye-health data.
///
/// Scoring formula:
///   weekly_score = (rate_2020 × 0.7) + min(weekly_exercises / 5.0, 1.0) × 0.3
///
///   rate_2020 = completed_breaks / triggered_sessions  (wasAlerted == true)
///   weekly_exercises = EyeExerciseRecord count in last 7 days, capped at 5
///
/// Mood thresholds:
///   ≥ 0.90 → happy  |  0.70–0.89 → okay  |  0.50–0.69 → tired
///   0.20–0.49 → sad  |  < 0.20 → ghost  |  22:00–07:00 → sleeping (override)
///
/// 7-day grace period: new users (PetState.createdAt < 7 days ago) are forced to .okay
/// so they don't start with a ghost cat from zero data.
@Observable
final class PetMoodEngine {
    private(set) var mood: PetMood = .okay
    private(set) var petState: PetState?
    private var modelContext: ModelContext?

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        self.petState = PetState.fetchOrCreate(context: modelContext)
        refresh()
    }

    // MARK: - Refresh

    func refresh() {
        guard let context = modelContext, let petState else { return }

        // Sleeping override: 22:00–07:00 local time takes precedence over everything.
        let hour = Calendar.current.component(.hour, from: .now)
        if hour >= 22 || hour < 7 {
            mood = .sleeping
            return
        }

        // 7-day grace period: new users always show .okay (no cold-start punishment).
        let daysSinceCreation = Date.now.timeIntervalSince(petState.createdAt) / 86400
        if daysSinceCreation < 7 {
            mood = .okay
            return
        }

        let sevenDaysAgo = Date.now.addingTimeInterval(-7 * 86400)

        // Triggered sessions: sessions where the DI alert actually fired.
        let sessionDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.startedAt >= sevenDaysAgo && $0.wasAlerted == true }
        )
        let triggered = (try? context.fetch(sessionDescriptor))?.count ?? 0

        // Completed breaks (not skipped) in the 7-day window.
        let breakDescriptor = FetchDescriptor<BreakRecord>(
            predicate: #Predicate { $0.completedAt >= sevenDaysAgo && $0.wasSkipped == false }
        )
        let completedBreaks = (try? context.fetch(breakDescriptor))?.count ?? 0

        // rate_2020: division-by-zero guard — no triggered sessions = 0 (not 1).
        let rate2020 = triggered > 0 ? Double(completedBreaks) / Double(triggered) : 0.0

        // Eye exercises in window, capped at 5 for the bonus.
        let exerciseDescriptor = FetchDescriptor<EyeExerciseRecord>(
            predicate: #Predicate { $0.completedAt >= sevenDaysAgo }
        )
        let exerciseCount = (try? context.fetch(exerciseDescriptor))?.count ?? 0
        let exerciseBonus = exerciseCount > 0 ? min(Double(exerciseCount) / 5.0, 1.0) * 0.3 : 0.0

        let weeklyScore = (rate2020 * 0.7) + exerciseBonus

        mood = moodFromScore(weeklyScore, triggered: triggered)
    }

    // MARK: - Private

    private func moodFromScore(_ score: Double, triggered: Int) -> PetMood {
        // No triggered alerts yet (brand-new user past grace period) → start at okay.
        if triggered == 0 { return .okay }
        switch score {
        case 0.90...: return .happy
        case 0.70..<0.90: return .okay
        case 0.50..<0.70: return .tired
        case 0.20..<0.50: return .sad
        default: return .ghost
        }
    }
}
