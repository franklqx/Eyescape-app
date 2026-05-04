//
//  Eyescape_appApp.swift
//  Eyescape app
//
//  Created by Frank Li on 3/30/26.
//

import SwiftUI
import SwiftData
// Break alert actions (TAKE_BREAK / SNOOZE / default tap): UNUserNotificationCenterDelegate
// is implemented on SessionManager and installed in SessionManager.configure.

@main
struct Eyescape_appApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            BreakRecord.self,
            UserSettings.self,
            PetState.self,
            EyeExerciseRecord.self,
            PickupSession.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // @Observable uses @State, not @StateObject
    @State private var sessionManager  = SessionManager()
    @State private var storeManager    = StoreManager()
    @State private var screenTimeAuth  = ScreenTimeAuthManager()
    @State private var stoppedOnBackground = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionManager)
                .environment(storeManager)
                .environment(screenTimeAuth)
                // Handle deep links from Live Activity buttons
                .onOpenURL { url in
                    guard url.scheme == "eyescape" else { return }
                    switch url.host {
                    case "snooze": sessionManager.snoozeBreak()
                    default: break   // "break" — HomeView detects isAlerting and shows break sheet
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                sessionManager.handleForeground()
                if stoppedOnBackground {
                    stoppedOnBackground = false
                    let hour = Calendar.current.component(.hour, from: .now)
                    let isSleepTime = hour >= 22 || hour < 7
                    if !isSleepTime {
                        try? sessionManager.startSession()  // Auto-restart after screen turns back on.
                    }
                }
            case .background, .inactive:
                sessionManager.handleBackground()       // Close pickup + alerting → confirmBreak.
                sessionManager.stopSession()            // Screen off / call / interruption → cancel session.
                stoppedOnBackground = true
            @unknown default:
                break
            }
        }
    }
}
