import Foundation
import SwiftData

// MARK: - PetMood

enum PetMood: String, CaseIterable {
    case happy    = "happy"
    case okay     = "okay"
    case tired    = "tired"
    case sad      = "sad"
    case ghost    = "ghost"
    case sleeping = "sleeping"

    var label: String {
        switch self {
        case .happy:    return "Happy"
        case .okay:     return "Doing well"
        case .tired:    return "Tired"
        case .sad:      return "Unhappy"
        case .ghost:    return "Needs attention"
        case .sleeping: return "Sleeping"
        }
    }

    var message: String {
        switch self {
        case .happy:    return "You're doing great! Keep it up."
        case .okay:     return "Looking good. Stay consistent."
        case .tired:    return "Take your breaks — I can tell you're tired."
        case .sad:      return "Your eyes need more rest. Try to take breaks."
        case .ghost:    return "Long time no see... your eyes miss you."
        case .sleeping: return "Time to rest. Goodnight."
        }
    }

    /// Maps mood to a pixel-cat animation name (matches filenames in exsec-dev/pixel-cat).
    var gifAnimation: String {
        switch self {
        case .happy:    return "with_ball"
        case .okay:     return "idle"
        case .tired:    return "walk"
        case .sad:      return "fall_from_grab"
        case .ghost:    return "fall_from_grab"
        case .sleeping: return "idle"
        }
    }
}

// MARK: - PetColor

enum PetColor: String, CaseIterable {
    case gray       = "gray"
    case lightbrown = "lightbrown"
    case brown      = "brown"
    case black      = "black"
    case white      = "white"

    var displayName: String {
        switch self {
        case .gray:       return "Gray"
        case .lightbrown: return "Light Brown"
        case .brown:      return "Brown"
        case .black:      return "Black"
        case .white:      return "White"
        }
    }
}

// MARK: - PetState

/// Singleton SwiftData model holding the user's pet configuration.
/// Always fetch via PetState.fetchOrCreate(context:).
///
/// createdAt is used for the 7-day grace period in PetMoodEngine:
///   if Date().timeIntervalSince(createdAt) < 7 * 86400 → force .okay
@Model
final class PetState {
    var name: String        // default "Mochi", max 12 chars
    var colorRaw: String    // PetColor.rawValue
    var createdAt: Date

    var color: PetColor {
        get { PetColor(rawValue: colorRaw) ?? .gray }
        set { colorRaw = newValue.rawValue }
    }

    init(name: String = "Mochi", color: PetColor = .gray, createdAt: Date = .now) {
        self.name = name
        self.colorRaw = color.rawValue
        self.createdAt = createdAt
    }

    @discardableResult
    static func fetchOrCreate(context: ModelContext) -> PetState {
        let descriptor = FetchDescriptor<PetState>()
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let pet = PetState()
        context.insert(pet)
        try? context.save()
        return pet
    }
}
