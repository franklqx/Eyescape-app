import Foundation

/// Single instructional step inside an `EyeExercise`.
struct ExerciseStep: Identifiable, Hashable {
    let id: Int
    let name: String
    let duration: TimeInterval
    let instruction: String
    /// SF Symbol shown while the step plays. Decorative only.
    let symbolName: String
}

/// Three evidence-backed eye routines. Content sourced from:
///   - 20-20-20 + active-blink: AAO / AOA digital eye-strain guidance
///   - Palming: peer-reviewed yoga-eye literature (PubMed PMC4932063)
///   - Classic exercise: PRC Ministry of Education 2008 official routine
///     (graded A in 2023 中西医结合诊疗指南)
enum EyeExercise: String, CaseIterable, Identifiable {
    case quickRest      = "quickRest"
    case palming        = "palming"
    case classicChinese = "classicChinese"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quickRest:      return "Quick rest"
        case .palming:        return "Palming"
        case .classicChinese: return "Classic exercise"
        }
    }

    var subtitle: String {
        switch self {
        case .quickRest:      return "Look far, then blink"
        case .palming:        return "Cover your eyes and breathe"
        case .classicChinese: return "Six pressure points"
        }
    }

    /// User-visible duration label, eg. "2 min".
    var lengthLabel: String {
        let min = Int(totalDuration / 60)
        return "\(min) min"
    }

    var totalDuration: TimeInterval {
        steps.reduce(0) { $0 + $1.duration }
    }

    var steps: [ExerciseStep] {
        switch self {
        case .quickRest:
            return [
                ExerciseStep(
                    id: 0,
                    name: "Look far",
                    duration: 20,
                    instruction: "Find a point at least 20 feet (6 m) away. Hold your gaze and let your eyes relax.",
                    symbolName: "binoculars"
                ),
                ExerciseStep(
                    id: 1,
                    name: "Active blinks",
                    duration: 100,
                    instruction: "Close your eyes for two seconds. Open. Squeeze tight for two seconds. Release. Repeat slowly.",
                    symbolName: "eye"
                ),
            ]

        case .palming:
            return [
                ExerciseStep(
                    id: 0,
                    name: "Warm your palms",
                    duration: 30,
                    instruction: "Rub your palms together until they feel warm.",
                    symbolName: "hands.sparkles"
                ),
                ExerciseStep(
                    id: 1,
                    name: "Cover & breathe",
                    duration: 150,
                    instruction: "Cup your warm palms over your closed eyes. Sit in the dark and breathe slowly.",
                    symbolName: "hand.raised"
                ),
            ]

        case .classicChinese:
            // Six 50-second sections = 5:00 total.
            return [
                ExerciseStep(
                    id: 0,
                    name: "Cuanzhu",
                    duration: 50,
                    instruction: "Press your thumbs into the inner ends of your eyebrows. Massage gently in small circles.",
                    symbolName: "circle.dotted"
                ),
                ExerciseStep(
                    id: 1,
                    name: "Jingming",
                    duration: 50,
                    instruction: "Place your thumbs on the inner corners of your eyes, just below the brow ridge. Press straight down with steady pressure.",
                    symbolName: "circle.dotted"
                ),
                ExerciseStep(
                    id: 2,
                    name: "Sibai",
                    duration: 50,
                    instruction: "Find the small indent on the cheekbone, directly below your pupils. Use your index and middle fingers to massage in small circles.",
                    symbolName: "circle.dotted"
                ),
                ExerciseStep(
                    id: 3,
                    name: "Taiyang & orbit",
                    duration: 50,
                    instruction: "Massage your temples eight times, then sweep your fingertips along the upper edge of the eye socket eight times.",
                    symbolName: "circle.dotted"
                ),
                ExerciseStep(
                    id: 4,
                    name: "Fengchi",
                    duration: 50,
                    instruction: "Place your palms behind your neck. Massage the soft hollow at the base of the skull on both sides.",
                    symbolName: "circle.dotted"
                ),
                ExerciseStep(
                    id: 5,
                    name: "Earlobes & toes",
                    duration: 50,
                    instruction: "Pinch and rub your earlobes between thumb and index finger. At the same time, grip the floor with your toes.",
                    symbolName: "circle.dotted"
                ),
            ]
        }
    }
}
