import Foundation
import SwiftData

// MARK: - Supporting Enums

enum HapticIntensity: String, Codable, CaseIterable {
    case light   = "Light"
    case medium  = "Medium"
    case strong  = "Strong"
}

enum HapticPattern: String, Codable, CaseIterable {
    case single = "Single"
    case double = "Double"
}

// AlertSize is defined in EyescapeAttributes.swift (shared with Widget Extension).

// MARK: - UserSettings

/// Singleton settings record. Always fetch via UserSettings.fetchOrCreate(context:).
///
/// isPro is a cache of StoreKit 2 entitlements — updated on every app launch
/// and after every purchase/restore via StoreKit.Transaction.currentEntitlements.
/// FeatureGate reads isPro at runtime; never rely on this value alone for security.
@Model
final class UserSettings {
    // Pro status — StoreKit 2 is the source of truth
    var isPro: Bool

    // Reminder interval (Free: always 20, Pro: 5-60)
    var customIntervalMinutes: Int

    // Haptic (Pro only)
    var hapticEnabled: Bool
    var hapticIntensityRaw: String      // HapticIntensity.rawValue
    var hapticPatternRaw: String        // HapticPattern.rawValue

    // Dynamic Island alert size (Pro only; Free always renders medium)
    var diAlertSizeRaw: String          // AlertSize.rawValue

    // MARK: Typed accessors

    var hapticIntensity: HapticIntensity {
        get { HapticIntensity(rawValue: hapticIntensityRaw) ?? .light }
        set { hapticIntensityRaw = newValue.rawValue }
    }

    var hapticPattern: HapticPattern {
        get { HapticPattern(rawValue: hapticPatternRaw) ?? .single }
        set { hapticPatternRaw = newValue.rawValue }
    }

    var diAlertSize: AlertSize {
        get { AlertSize(rawValue: diAlertSizeRaw) ?? .medium }
        set { diAlertSizeRaw = newValue.rawValue }
    }

    /// Effective interval: Pro uses customIntervalMinutes, Free is always 20.
    var effectiveIntervalMinutes: Int {
        isPro ? customIntervalMinutes : 20
    }

    init(
        isPro: Bool = false,
        customIntervalMinutes: Int = 20,
        hapticEnabled: Bool = false,
        hapticIntensity: HapticIntensity = .light,
        hapticPattern: HapticPattern = .single,
        diAlertSize: AlertSize = .medium
    ) {
        self.isPro = isPro
        self.customIntervalMinutes = customIntervalMinutes
        self.hapticEnabled = hapticEnabled
        self.hapticIntensityRaw = hapticIntensity.rawValue
        self.hapticPatternRaw = hapticPattern.rawValue
        self.diAlertSizeRaw = diAlertSize.rawValue
    }

    // MARK: Singleton fetch

    /// Fetch existing settings or insert defaults. Always call this instead of Query.
    @discardableResult
    static func fetchOrCreate(context: ModelContext) -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        let results = try? context.fetch(descriptor)
        if let existing = results?.first { return existing }
        let defaults = UserSettings()
        context.insert(defaults)
        return defaults
    }
}
