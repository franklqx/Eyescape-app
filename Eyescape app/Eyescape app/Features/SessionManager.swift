import Foundation
import Observation
import SwiftData
import UserNotifications
import ActivityKit

// MARK: - Session State

enum SessionState {
    case idle
    case active(session: Session)
    case paused(session: Session)
    case alerting(session: Session)

    var currentSession: Session? {
        switch self {
        case .idle:              return nil
        case .active(let s):    return s
        case .paused(let s):    return s
        case .alerting(let s):  return s
        }
    }

    var isRunning: Bool {
        if case .active = self { return true }
        return false
    }
}

// MARK: - Errors

enum SessionError: LocalizedError {
    case alreadyActive
    case noActiveSession

    var errorDescription: String? {
        switch self {
        case .alreadyActive:    return "A session is already running. Stop it before starting a new one."
        case .noActiveSession:  return "No active session to modify."
        }
    }
}

// MARK: - SessionManager

/// Central coordinator for Eyescape session lifecycle.
///
/// State machine:
///
///   IDLE ──startSession()──► ACTIVE ──targetDate reached──► ALERTING
///                              │                                │
///                         stopSession()              confirmBreak() / skipBreak()
///                              │                                │
///                              ▼                                ▼
///                             IDLE                    ACTIVE (timer reset +20 min)
///
/// Sessions run indefinitely until the user taps Stop or the screen turns off.
/// After each break (taken or skipped) the 20-min timer resets automatically.

@Observable
final class SessionManager: NSObject {
    private(set) var state: SessionState = .idle
    private var modelContext: ModelContext?
    private var settings: UserSettings?
    private var wasAutoPaused = false
    /// Cold launch from a lock-screen action can deliver a response before `configure` runs.
    private var pendingNotificationResponse: UNNotificationResponse?

    // ActivityKit — stored as Any to avoid compile errors when running on non-DI devices
    private var currentActivity: Activity<EyescapeAttributes>?

    // Pet fields — updated by the app when PetMoodEngine refreshes; passed into every LA update.
    var currentPetMoodRaw: String  = "okay"
    var currentPetColorRaw: String = "gray"

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: Derived state

    var isAlerting: Bool {
        if case .alerting = state { return true }
        return false
    }

    var isIdle: Bool {
        if case .idle = state { return true }
        return false
    }

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        self.settings = UserSettings.fetchOrCreate(context: modelContext)
        recoverSessionIfNeeded()
        if let pending = pendingNotificationResponse {
            pendingNotificationResponse = nil
            handleNotificationResponse(pending)
        }
    }

    // MARK: - Notification Permission

    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Start

    func startSession() throws {
        guard case .idle = state else { throw SessionError.alreadyActive }
        guard let context = modelContext, let settings else { return }

        let interval = settings.effectiveIntervalMinutes
        let session = Session(startedAt: .now, intervalMinutes: interval)
        context.insert(session)
        try? context.save()

        state = .active(session: session)
        scheduleNotification(for: session)
        scheduleRenewalNotification(for: session)

        Task { await startLiveActivity(session: session, settings: settings) }
    }

    // MARK: - Pause / Resume

    func pauseSession() throws {
        guard case .active(let session) = state else { throw SessionError.noActiveSession }
        performPause(session: session, isAuto: false)
    }

    func resumeSession() throws {
        guard case .paused(let session) = state else { throw SessionError.noActiveSession }
        performResume(session: session)
    }

    // MARK: - Break Actions

    func confirmBreak() {
        guard case .alerting(let session) = state else { return }
        let record = BreakRecord(completedAt: .now, wasSkipped: false, session: session)
        modelContext?.insert(record)
        rescheduleForNextCycle(session: session)
    }

    func skipBreak() {
        guard case .alerting(let session) = state else { return }
        let record = BreakRecord(completedAt: .now, wasSkipped: true, session: session)
        modelContext?.insert(record)
        rescheduleForNextCycle(session: session)
    }

    /// Resets the 20-min timer after a break is taken or skipped. Session continues.
    private func rescheduleForNextCycle(session: Session) {
        let interval = Double(session.intervalMinutes) * 60
        session.targetDate = Date.now.addingTimeInterval(interval)
        session.wasAlerted = false
        try? modelContext?.save()
        cancelNotification(for: session)
        scheduleNotification(for: session)
        state = .active(session: session)
        Task { await updateLiveActivity(session: session, isAlerting: false) }
    }

    func snoozeBreak() {
        guard case .alerting(let session) = state else { return }
        let newTarget = Date.now.addingTimeInterval(20 * 60)
        session.targetDate = newTarget
        try? modelContext?.save()
        state = .active(session: session)
        cancelNotification(for: session)
        scheduleNotification(for: session)
        Task { await updateLiveActivity(session: session, isAlerting: false) }
    }

    // MARK: - Stop

    func stopSession() {
        guard let session = state.currentSession else { return }
        session.endedAt = .now
        try? modelContext?.save()
        cancelNotification(for: session)
        state = .idle
        Task { await endLiveActivity() }
    }

    // MARK: - Scene Phase

    func handleForeground() {
        if case .active(let session) = state, session.targetDate < .now {
            if !session.wasAlerted {
                session.wasAlerted = true
                try? modelContext?.save()
            }
            state = .alerting(session: session)
            Task { await updateLiveActivity(session: session, isAlerting: true) }
        }
    }

    func handleBackground() {
        // Lock screen while alerting = user completed the break (look away 20 sec).
        if case .alerting = state {
            confirmBreak()
            return
        }
        if case .active(let session) = state {
            performPause(session: session, isAuto: true)
            wasAutoPaused = true
        }
    }

    // MARK: - Cold Start Recovery

    private func recoverSessionIfNeeded() {
        guard let context = modelContext else { return }
        var descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.endedAt == nil }
        )
        descriptor.sortBy = [SortDescriptor(\.startedAt, order: .reverse)]
        guard let session = (try? context.fetch(descriptor))?.first else { return }

        if session.isPaused {
            state = .paused(session: session)
            return
        }
        if session.targetDate < .now {
            if !session.wasAlerted {
                session.wasAlerted = true
                try? context.save()
            }
            state = .alerting(session: session)
            Task { await reattachOrRestartLiveActivity(session: session, isAlerting: true) }
        } else {
            state = .active(session: session)
            scheduleNotification(for: session)
            Task { await reattachOrRestartLiveActivity(session: session, isAlerting: false) }
        }
    }

    /// On app relaunch, re-attach to an existing Live Activity for this session,
    /// or start a fresh one if none exists.
    private func reattachOrRestartLiveActivity(session: Session, isAlerting: Bool) async {
        // Try to reuse a still-running activity for this session.
        if let existing = Activity<EyescapeAttributes>.activities
            .first(where: { $0.attributes.sessionId == session.id }) {
            currentActivity = existing
            await updateLiveActivity(session: session, isAlerting: isAlerting)
            return
        }
        // No existing activity — start a fresh one.
        guard let s = settings else { return }
        await startLiveActivity(session: session, settings: s)
        if isAlerting {
            await updateLiveActivity(session: session, isAlerting: true)
        }
    }

    /// Routes lock-screen / banner actions (TAKE_BREAK, SNOOZE) and default tap on break alerts.
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            if response.notification.request.content.categoryIdentifier == "BREAK_ALERT" {
                ensureAlertingForOpenSessionIfDue()
            }
        case "TAKE_BREAK":
            ensureAlertingForOpenSessionIfDue()
        case "SNOOZE":
            guard response.notification.request.content.categoryIdentifier == "BREAK_ALERT" else { return }
            if case .alerting = state {
                snoozeBreak()
            } else {
                ensureAlertingForOpenSessionIfDue()
                if case .alerting = state { snoozeBreak() }
            }
        default:
            break
        }
    }

    /// If an un-ended session is past its target, move to alerting so the break sheet can appear.
    private func ensureAlertingForOpenSessionIfDue() {
        guard let context = modelContext else { return }
        var descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.endedAt == nil && !$0.isPaused }
        )
        descriptor.sortBy = [SortDescriptor(\.startedAt, order: .reverse)]
        guard let session = (try? context.fetch(descriptor))?.first else { return }
        guard session.targetDate < .now else { return }
        if !session.wasAlerted {
            session.wasAlerted = true
            try? context.save()
        }
        state = .alerting(session: session)
        Task { await updateLiveActivity(session: session, isAlerting: true) }
    }

    // MARK: - Private Helpers

    private func performPause(session: Session, isAuto: Bool) {
        let remaining = max(0, Int(session.targetDate.timeIntervalSinceNow))
        session.isPaused = true
        session.pausedAt = .now
        session.remainingSecondsAtPause = remaining
        try? modelContext?.save()
        cancelNotification(for: session)
        state = .paused(session: session)
        Task { await updateLiveActivity(session: session, isPaused: true) }
    }

    private func performResume(session: Session) {
        guard let remaining = session.remainingSecondsAtPause else { return }
        let newTarget = Date.now.addingTimeInterval(Double(remaining))
        session.targetDate = newTarget
        session.isPaused = false
        session.pausedAt = nil
        session.remainingSecondsAtPause = nil
        try? modelContext?.save()
        state = .active(session: session)
        scheduleNotification(for: session)
        Task { await updateLiveActivity(session: session, isPaused: false) }
    }

    // MARK: - ActivityKit

    private func startLiveActivity(session: Session, settings: UserSettings) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[Eyescape] Live Activity not started: areActivitiesEnabled=false. " +
                  "Check Settings → Eyescape → Live Activities.")
            return
        }
        guard FeatureGate.isAvailable(.dynamicIsland, settings: settings) else { return }

        let attributes = EyescapeAttributes(
            sessionId: session.id,
            intervalMinutes: session.intervalMinutes
        )
        let contentState = EyescapeAttributes.ContentState(
            targetDate: session.targetDate,
            isPaused: false,
            isAlerting: false,
            diAlertSize: FeatureGate.effectiveAlertSize(settings: settings),
            petMoodRaw: currentPetMoodRaw,
            petColorRaw: currentPetColorRaw
        )
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: session.targetDate.addingTimeInterval(120))
            )
            print("[Eyescape] Live Activity started: \(currentActivity?.id ?? "?")")
        } catch {
            print("[Eyescape] Live Activity request failed: \(error)")
        }
    }

    private func updateLiveActivity(
        session: Session,
        isPaused: Bool = false,
        isAlerting: Bool = false
    ) async {
        guard let activity = currentActivity else { return }
        let size = settings.map { FeatureGate.effectiveAlertSize(settings: $0) } ?? .medium
        let newState = EyescapeAttributes.ContentState(
            targetDate: isAlerting || isPaused ? nil : session.targetDate,
            isPaused: isPaused,
            isAlerting: isAlerting,
            diAlertSize: size,
            petMoodRaw: currentPetMoodRaw,
            petColorRaw: currentPetColorRaw
        )
        let alertConfig: AlertConfiguration? = isAlerting ? AlertConfiguration(
            title: LocalizedStringResource("Time for a break"),
            body: LocalizedStringResource("Rest your eyes for 20 seconds."),
            sound: .default
        ) : nil

        await activity.update(
            ActivityContent(state: newState, staleDate: .now.addingTimeInterval(300)),
            alertConfiguration: alertConfig
        )
    }

    private func endLiveActivity() async {
        guard let activity = currentActivity else { return }
        // Use the non-deprecated API: end(content:dismissalPolicy:)
        let finalState = activity.content.state
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )
        currentActivity = nil
    }

    // MARK: - 8-Hour LA Renewal

    /// Live Activities expire after 8 hours. Schedule a renewal notification at 7.5h.
    private func scheduleRenewalNotification(for session: Session) {
        let renewalId = "la-renewal-\(session.id)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [renewalId])

        let delay = 7.5 * 3600.0
        guard delay > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Eyescape"
        content.body = "Refreshing protection…"
        content.sound = nil
        content.userInfo = ["action": "la_renewal", "sessionId": session.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: renewalId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Notifications

    private func scheduleNotification(for session: Session) {
        let content = UNMutableNotificationContent()
        content.title = "Time for a break"
        content.body = "You've been on your phone for \(session.intervalMinutes) min. Rest your eyes."
        content.sound = .default
        content.categoryIdentifier = "BREAK_ALERT"

        let takeBreak = UNNotificationAction(identifier: "TAKE_BREAK", title: "Take break", options: [.foreground])
        let snooze    = UNNotificationAction(identifier: "SNOOZE",     title: "+20 min",    options: [])
        let category  = UNNotificationCategory(identifier: "BREAK_ALERT", actions: [takeBreak, snooze], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])

        let delay = max(1, session.targetDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: session.id.uuidString, content: content, trigger: trigger)
        )
    }

    private func cancelNotification(for session: Session) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [session.id.uuidString])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension SessionManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if modelContext == nil {
            pendingNotificationResponse = response
        } else {
            handleNotificationResponse(response)
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
