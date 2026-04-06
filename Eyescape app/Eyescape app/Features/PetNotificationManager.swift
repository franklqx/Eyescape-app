import Foundation
import UserNotifications

/// Schedules the three daily pet notifications:
///   • Morning wake-up   (default 09:00) — cat mood determines body copy
///   • Eye exercise      (default 13:00) — fixed prompt to do 眼保健操
///   • Evening sleep     (default 22:00) — fixed sleep reminder
///
/// Call scheduleAll(petName:mood:) whenever the pet state changes, or on app launch.
/// Existing requests are removed and replaced so there is always exactly one set.
final class PetNotificationManager {
    static let shared = PetNotificationManager()
    private init() {}

    private let morningId  = "pet-morning"
    private let exerciseId = "pet-exercise"
    private let eveningId  = "pet-evening"

    // MARK: - Public

    func scheduleAll(petName: String, mood: PetMood) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningId, exerciseId, eveningId])

        scheduleMorning(center: center, petName: petName, mood: mood)
        scheduleExercise(center: center, petName: petName)
        scheduleEvening(center: center, petName: petName)
    }

    // MARK: - Private

    private func scheduleMorning(center: UNUserNotificationCenter, petName: String, mood: PetMood) {
        let content = UNMutableNotificationContent()
        content.title = petName
        content.body  = morningBody(mood: mood)
        content.sound = .default

        var components    = DateComponents()
        components.hour   = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: morningId, content: content, trigger: trigger))
    }

    private func scheduleExercise(center: UNUserNotificationCenter, petName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Eye exercise time"
        content.body  = "\(petName) wants you to do your eye exercises."
        content.sound = .default

        var components    = DateComponents()
        components.hour   = 13
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: exerciseId, content: content, trigger: trigger))
    }

    private func scheduleEvening(center: UNUserNotificationCenter, petName: String) {
        let content = UNMutableNotificationContent()
        content.title = petName
        content.body  = "Time to rest your eyes. Goodnight."
        content.sound = .default

        var components    = DateComponents()
        components.hour   = 22
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: eveningId, content: content, trigger: trigger))
    }

    private func morningBody(mood: PetMood) -> String {
        switch mood {
        case .happy:    return "Good morning! Your eyes are well-rested. Let's keep it up!"
        case .okay:     return "Good morning! Ready to protect your eyes today?"
        case .tired:    return "Good morning. Remember to take your breaks today."
        case .sad:      return "Good morning. Your eyes need more rest — please take your breaks."
        case .ghost:    return "Long time no see... let's start protecting your eyes again."
        case .sleeping: return "Good morning! Time to wake up and take care of your eyes."
        }
    }
}
