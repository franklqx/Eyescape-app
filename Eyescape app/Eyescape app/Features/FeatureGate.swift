import Foundation

// MARK: - Feature Enum

enum Feature: CaseIterable {
    case dynamicIsland      // Live Activity / DI amber dot + break alert
    case customInterval     // 5-60 min custom reminder interval
    case haptic             // vibration on break alert
    case diAlertSize        // S / M / L DI expanded height (stored in ContentState)

    var displayName: String {
        switch self {
        case .dynamicIsland:  return "Dynamic Island"
        case .customInterval: return "Custom Interval"
        case .haptic:         return "Haptic Alert"
        case .diAlertSize:    return "DI Alert Size"
        }
    }
}

// MARK: - FeatureGate

/// Central feature availability check. All Pro guards must go through here.
///
/// Usage:
///   guard FeatureGate.isAvailable(.haptic, settings: settings) else { return }
///   if FeatureGate.isAvailable(.dynamicIsland, settings: settings) { ... }
///
/// Free tier: Live Activity (compact DI), push reminders, fixed 20-min interval, no haptic / custom DI size.
/// Pro tier: custom interval, haptics, DI size control.
enum FeatureGate {
    /// Returns true if the feature is available given the user's current settings.
    static func isAvailable(_ feature: Feature, settings: UserSettings) -> Bool {
        switch feature {
        case .dynamicIsland:
            // Live Activity / compact DI for everyone; Pro unlocks custom DI size via `.diAlertSize`.
            return true
        case .customInterval, .haptic, .diAlertSize:
            guard settings.isPro else { return false }
            return true
        }
    }

    /// Convenience: returns the effective DI alert size.
    /// Free users always get .medium regardless of stored setting.
    static func effectiveAlertSize(settings: UserSettings) -> AlertSize {
        isAvailable(.diAlertSize, settings: settings) ? settings.diAlertSize : .medium
    }
}
