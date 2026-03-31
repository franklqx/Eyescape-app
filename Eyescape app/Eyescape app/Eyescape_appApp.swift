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
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // @Observable uses @State, not @StateObject
    @State private var sessionManager = SessionManager()
    @State private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionManager)
                .environment(storeManager)
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
        // Auto-pause/resume: timer only runs when user is actively looking at the phone
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                sessionManager.handleForeground()
            case .background, .inactive:
                sessionManager.handleBackground()
            @unknown default:
                break
            }
        }
    }
}
