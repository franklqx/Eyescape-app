import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(SessionManager.self) private var sessionManager

    @Query private var pickups: [PickupSession]
    @Query private var exercises: [EyeExerciseRecord]

    @State private var showBreakView = false
    @State private var pendingExercise: EyeExercise?
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

    // MARK: - Aggregated stats

    private var todayTotalLabel: String {
        formatDuration(ScreenTimeAggregator.todayTotalScreenTime(pickups: pickups))
    }

    private var todayAvgLabel: String {
        let avg = ScreenTimeAggregator.todayAveragePickupDuration(pickups: pickups)
        return avg > 0 ? formatDuration(avg) : "—"
    }

    private var todayComplianceLabel: String {
        let pickupCount = ScreenTimeAggregator.todayPickupCount(pickups: pickups)
        guard pickupCount > 0 else { return "—" }
        let rate = ScreenTimeAggregator.today2020ComplianceRate(pickups: pickups)
        return "\(Int((rate * 100).rounded()))%"
    }

    private var todayExerciseCount: Int {
        ScreenTimeAggregator.todayExerciseCount(records: exercises)
    }

    var body: some View {
        ZStack {
            Color(hex: "0C0C10").ignoresSafeArea()

            VStack(spacing: 0) {
                Color.clear.frame(height: 60)   // DI clearance

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        statsGrid
                        exerciseCard
                        sessionStatusBar
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)      // tab bar clearance
                }
            }
        }
        .task {
            await sessionManager.requestNotificationPermission()
        }
        .onAppear {
            if sessionManager.isIdle {
                try? sessionManager.startSession()
            }
        }
        .onChange(of: sessionManager.isAlerting) { _, alerting in
            if alerting { showBreakView = true }
        }
        .sheet(isPresented: $showBreakView) {
            BreakView()
                .environment(sessionManager)
        }
        .sheet(item: $pendingExercise) { exercise in
            EyeExerciseSession(exercise: exercise)
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
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: "F2F2F5"))
            Text("Your eyes today")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8A8A96"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Stats grid (2×2)

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            StatMiniCard(label: "TODAY", value: todayTotalLabel, suffix: "screen time")
            StatMiniCard(label: "AVG PICKUP", value: todayAvgLabel, suffix: "per session")
            StatMiniCard(label: "≤ 20 MIN", value: todayComplianceLabel, suffix: "compliance")
            StatMiniCard(label: "EXERCISES", value: "\(todayExerciseCount)", suffix: "today")
        }
    }

    // MARK: - Exercise card

    private var exerciseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("EYE EXERCISES")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "E8954A"))
                    .tracking(1.2)
                Text("Take a moment for your eyes")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "F2F2F5"))
            }

            HStack(spacing: 8) {
                ForEach(EyeExercise.allCases) { exercise in
                    exerciseButton(exercise)
                }
            }
        }
        .padding(20)
        .background(Color(hex: "18181F"))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func exerciseButton(_ exercise: EyeExercise) -> some View {
        Button {
            pendingExercise = exercise
        } label: {
            VStack(spacing: 6) {
                Text(exercise.lengthLabel)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "F2F2F5"))
                Text(exercise.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "F2F2F5"))
                Text(exercise.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "8A8A96"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(Color(hex: "22222C"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session status bar

    private var sessionStatusBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusDotColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusDotColor.opacity(statusDotGlow), radius: 5)
                .accessibilityHidden(true)

            Text(statusLabel)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8A8A96"))

            Spacer()

            if let action = primaryAction {
                Button { action.run() } label: {
                    Text(action.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(action.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(action.background)
                        .clipShape(Capsule())
                }
                .accessibilityLabel(action.a11y)
            }
        }
        .padding(16)
        .background(Color(hex: "18181F"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session status: \(statusLabel)")
    }

    private var statusDotColor: Color {
        switch sessionManager.state {
        case .active, .alerting: return Color(hex: "E8954A")
        case .paused, .idle:     return Color(hex: "E8954A").opacity(0.4)
        }
    }

    private var statusDotGlow: Double {
        switch sessionManager.state {
        case .alerting: return 0.9
        case .active:   return 0.6
        case .paused, .idle: return 0
        }
    }

    private var statusLabel: String {
        switch sessionManager.state {
        case .idle:     return "Auto-protect off"
        case .active:   return "Auto-protecting your eyes"
        case .paused:   return "Paused"
        case .alerting: return "Time for a break"
        }
    }

    private var primaryAction: SessionBarAction? {
        switch sessionManager.state {
        case .idle:
            return SessionBarAction(
                label: "Start",
                a11y: "Start auto-protect session",
                tint: Color(hex: "E8954A"),
                background: Color(hex: "E8954A").opacity(0.12),
                run: { try? sessionManager.startSession() }
            )
        case .active:
            return SessionBarAction(
                label: "Pause",
                a11y: "Pause auto-protect session",
                tint: Color(hex: "8A8A96"),
                background: Color(hex: "22222C"),
                run: { try? sessionManager.pauseSession() }
            )
        case .paused:
            return SessionBarAction(
                label: "Resume",
                a11y: "Resume auto-protect session",
                tint: Color(hex: "E8954A"),
                background: Color(hex: "E8954A").opacity(0.12),
                run: { try? sessionManager.resumeSession() }
            )
        case .alerting:
            return nil
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(total)s"
    }
}

// MARK: - Stat mini card

private struct StatMiniCard: View {
    let label: String
    let value: String
    let suffix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "E8954A"))
                .tracking(1.2)

            Text(value)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(Color(hex: "F2F2F5"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(suffix)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "8A8A96"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "18181F"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Session bar action descriptor

private struct SessionBarAction {
    let label: String
    let a11y: String
    let tint: Color
    let background: Color
    let run: () -> Void
}

// MARK: - Color extension

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
    let schema = Schema([
        Session.self, BreakRecord.self, UserSettings.self,
        PetState.self, EyeExerciseRecord.self, PickupSession.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    HomeView()
        .environment(SessionManager())
        .modelContainer(container)
}
