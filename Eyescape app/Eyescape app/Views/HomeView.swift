import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(SessionManager.self) private var sessionManager

    @Query(sort: \Session.startedAt, order: .reverse) private var sessions: [Session]
    @Query(sort: \BreakRecord.completedAt, order: .reverse) private var breakRecords: [BreakRecord]

    @State private var showBreakView = false
    @State private var errorMessage: String?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning."
        case 12..<17: return "Good afternoon."
        case 17..<21: return "Good evening."
        default:      return "Good night."
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "0C0C10").ignoresSafeArea()

            VStack(spacing: 0) {
                Color.clear.frame(height: 60)   // DI clearance

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                        Spacer().frame(height: 32)
                        sessionSection
                        Spacer().frame(height: 40)
                        quickStatsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            await sessionManager.requestNotificationPermission()
        }
        // Show break sheet when alert fires
        .onChange(of: sessionManager.isAlerting) { _, alerting in
            if alerting { showBreakView = true }
        }
        .sheet(isPresented: $showBreakView) {
            BreakView()
                .environment(sessionManager)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color(hex: "F2F2F5"))
            Text(statusSubtitle)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8A8A96"))
        }
    }

    private var statusSubtitle: String {
        switch sessionManager.state {
        case .idle:      return "Ready when you are."
        case .active:    return "Protection is active."
        case .paused:    return "Session paused."
        case .alerting:  return "Break time!"
        }
    }

    // MARK: - Session Section

    private var sessionSection: some View {
        Group {
            switch sessionManager.state {
            case .idle:
                idleCard
            case .active(let session), .alerting(let session):
                activeCard(session: session)
            case .paused(let session):
                pausedCard(session: session)
            }
        }
    }

    private var idleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "18181F"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
                    .frame(height: 110)
                VStack(spacing: 6) {
                    Text("No active session")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "8A8A96"))
                    Text("Start one to protect your eyes")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8A8A96").opacity(0.6))
                }
            }

            Button {
                do { try sessionManager.startSession() }
                catch { errorMessage = error.localizedDescription }
            } label: {
                Text("Start session")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "0C0C10"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(hex: "E8954A"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func activeCard(session: Session) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SESSION")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "8A8A96"))
                    .tracking(1.2)

                HStack(spacing: 8) {
                    // Amber breathing dot
                    Circle()
                        .fill(Color(hex: "E8954A"))
                        .frame(width: 8, height: 8)
                        .shadow(color: Color(hex: "E8954A"), radius: 5)
                    Text("Running")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "F2F2F5"))
                }

                Text(sessionTimeText(session: session))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "8A8A96"))
            }
            .padding(20)
            .background(Color(hex: "22222C"))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 12) {
                Button {
                    try? sessionManager.pauseSession()
                } label: {
                    Text("Pause")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8A8A96"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "22222C"))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    sessionManager.stopSession()
                } label: {
                    Text("Stop")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "E05454"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "E05454").opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "E05454").opacity(0.2), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func pausedCard(session: Session) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SESSION")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "8A8A96"))
                    .tracking(1.2)
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: "8A8A96")).frame(width: 8, height: 8)
                    Text("Paused")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "F2F2F5"))
                }
                if let remaining = session.remainingSecondsAtPause {
                    Text("\(remaining / 60)m \(remaining % 60)s remaining")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "8A8A96"))
                }
            }
            .padding(20)
            .background(Color(hex: "22222C"))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                try? sessionManager.resumeSession()
            } label: {
                Text("Resume")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "0C0C10"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(hex: "E8954A"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "E8954A"))
                .tracking(1.2)
            HStack(spacing: 12) {
                StatMiniCard(value: "\(todaySessionCount)", label: "Sessions")
                StatMiniCard(value: "\(todayBreaksCompleted)", label: "Breaks taken")
                StatMiniCard(value: todayBreakRateText, label: "Break rate")
            }
        }
    }

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: .now)
    }

    private var todaySessionCount: Int {
        sessions.filter { $0.startedAt >= startOfToday }.count
    }

    private var todayBreaksCompleted: Int {
        breakRecords.filter { $0.completedAt >= startOfToday && !$0.wasSkipped }.count
    }

    /// Completed breaks today ÷ sessions started today (matches Analytics semantics, day-scoped).
    private var todayBreakRateText: String {
        let todaySessions = sessions.filter { $0.startedAt >= startOfToday }
        guard !todaySessions.isEmpty else { return "—" }
        let completed = breakRecords.filter { $0.completedAt >= startOfToday && !$0.wasSkipped }.count
        let rate = Double(completed) / Double(todaySessions.count) * 100
        return "\(Int(min(rate, 100)))%"
    }

    // MARK: - Helpers

    private func sessionTimeText(session: Session) -> String {
        "Started \(Self.shortTimeFormatter.string(from: session.startedAt)) · next \(Self.shortTimeFormatter.string(from: session.targetDate))"
    }

    private static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}

// MARK: - StatMiniCard

private struct StatMiniCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .regular, design: .monospaced))
                .foregroundColor(Color(hex: "F2F2F5"))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "8A8A96"))
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "18181F"))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: 1)
    }
}

#Preview {
    let schema = Schema([Session.self, BreakRecord.self, UserSettings.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    HomeView()
        .environment(SessionManager())
        .modelContainer(container)
}
