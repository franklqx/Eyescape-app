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
    // Three states:
    //   Work period:  isPaused=false, isAlerting=false, targetDate=future  → amber dot
    //   Break alert:  isPaused=false, isAlerting=true,  targetDate=nil     → expanded alert
    //   Paused:       isPaused=true,  isAlerting=false, targetDate=nil     → paused indicator
    struct ContentState: Codable, Hashable {
        var targetDate: Date?       // nil when paused or alerting
        var isPaused: Bool
        var isAlerting: Bool
        var diAlertSize: AlertSize  // S/M/L — controls expanded layout density
    }
}
