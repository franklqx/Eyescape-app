// EyescapeAttributes.swift
// Shared between main app target AND EyescapeWidget target.
// ⚠️  When adding to Xcode: select BOTH targets in the "Add to targets" dialog.

import ActivityKit
import Foundation

// MARK: - AlertSize
// Defined here (not in UserSettings) so the Widget Extension can access it without SwiftData.

enum AlertSize: String, Codable, CaseIterable {
    case small  = "S"
    case medium = "M"
    case large  = "L"
}

// MARK: - EyescapeAttributes

struct EyescapeAttributes: ActivityAttributes {
    // Static — set once when the activity starts, never changes.
    var sessionId: UUID
    var intervalMinutes: Int

    // Dynamic — updated via Activity.update() throughout the session.
    //
    // Three DI states:
    //   Compact (always-on):  isPaused=false, isAlerting=false → cat head on left
    //   Expanded (long-press): same fields, shows cat full body + countdown from targetDate
    //   Alert (time's up):    isAlerting=true, targetDate=nil → cat full body + lock-screen prompt
    struct ContentState: Codable, Hashable {
        var targetDate: Date?       // nil when paused or alerting; drives countdown in Expanded view
        var isPaused: Bool
        var isAlerting: Bool
        var diAlertSize: AlertSize  // S/M/L — controls expanded layout density

        // Pet fields — added with defaults so pre-pet Live Activities decode safely
        var petMoodRaw: String      // PetMood.rawValue — drives cat expression
        var petColorRaw: String     // PetColor.rawValue — drives cat color (asset slot-in)

        init(
            targetDate: Date? = nil,
            isPaused: Bool = false,
            isAlerting: Bool = false,
            diAlertSize: AlertSize = .medium,
            petMoodRaw: String = "okay",
            petColorRaw: String = "gray"
        ) {
            self.targetDate = targetDate
            self.isPaused = isPaused
            self.isAlerting = isAlerting
            self.diAlertSize = diAlertSize
            self.petMoodRaw = petMoodRaw
            self.petColorRaw = petColorRaw
        }

        // Custom decoder: old ContentState (without pet fields) decodes safely using defaults.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            targetDate  = try c.decodeIfPresent(Date.self,      forKey: .targetDate)
            isPaused    = try c.decode(Bool.self,                forKey: .isPaused)
            isAlerting  = try c.decode(Bool.self,                forKey: .isAlerting)
            diAlertSize = try c.decode(AlertSize.self,           forKey: .diAlertSize)
            petMoodRaw  = try c.decodeIfPresent(String.self,     forKey: .petMoodRaw)  ?? "okay"
            petColorRaw = try c.decodeIfPresent(String.self,     forKey: .petColorRaw) ?? "gray"
        }
    }
}
