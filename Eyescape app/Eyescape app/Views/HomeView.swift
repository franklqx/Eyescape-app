import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(SessionManager.self) private var sessionManager

    @Query private var pickups: [PickupSession]
    @Query private var exercises: [EyeExerciseRecord]

    @State private var showBreakView  = false
    @State private var pendingExercise: EyeExercise?
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()
            warmOrbs

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 50)        // DI clearance

                    headerBlock
                        .padding(.horizontal, 22)
                        .padding(.bottom, 28)

                    heroBlock
                        .padding(.horizontal, 22)
                        .padding(.bottom, 18)

                    subStatsBlock
                        .padding(.horizontal, 22)
                        .padding(.bottom, 24)

                    recommendationHeader
                        .padding(.horizontal, 22)
                        .padding(.bottom, 12)

                    recommendationCard
                        .padding(.horizontal, 22)
                        .padding(.bottom, 12)

                    otherExercisesList
                        .padding(.horizontal, 26)

                    Color.clear.frame(height: 200)       // pill + tab bar clearance
                }
            }

            sessionPill
                .padding(.horizontal, 24)
                .padding(.bottom, 96)                    // sit above tab bar
        }
        .task { await sessionManager.requestNotificationPermission() }
        .onAppear {
            if sessionManager.isIdle {
                try? sessionManager.startSession()
            }
        }
        .onChange(of: sessionManager.isAlerting) { _, alerting in
            if alerting { showBreakView = true }
        }
        .sheet(isPresented: $showBreakView) {
            BreakView().environment(sessionManager)
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

    // MARK: - Derived state

    private var longest: TimeInterval {
        ScreenTimeAggregator.todayLongestPickup(pickups: pickups)
    }
    private var total: TimeInterval {
        ScreenTimeAggregator.todayTotalScreenTime(pickups: pickups)
    }
    private var avgPickup: TimeInterval {
        ScreenTimeAggregator.todayAveragePickupDuration(pickups: pickups)
    }
    private var exerciseCount: Int {
        ScreenTimeAggregator.todayExerciseCount(records: exercises)
    }
    private var pickupCount: Int {
        ScreenTimeAggregator.todayPickupCount(pickups: pickups)
    }
    /// "Compliant day" = at least one pickup today AND none over 20 min.
    /// Used to flip hero color and recommendation copy.
    private var isCompliantDay: Bool {
        pickupCount > 0 && longest < 20 * 60
    }

    // MARK: - Header

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: .now)
    }

    private var greetingText: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  return "Good morning."
        case 12..<17: return "Good afternoon."
        case 17..<21: return "Good evening."
        default:      return "Good night."
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateText)
                .appText(.subHeader)
                .foregroundStyle(Color.textSecondary)
            Text(greetingText)
                .appText(.greeting)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Hero block

    private var heroBlock: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's longest session")
                    .appText(.subHeader)
                    .foregroundStyle(Color.textSecondary)

                heroValueRow
                    .padding(.top, 2)

                heroSubtitle
                    .padding(.top, 4)
            }
            Spacer(minLength: 0)
            heroRing
        }
    }

    @ViewBuilder
    private var heroValueRow: some View {
        if pickupCount == 0 {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("—")
                    .appText(.heroValue)
                    .foregroundStyle(Color.textTertiary)
            }
        } else {
            durationLabel(longest, baseStyle: .heroValue, color: heroColor)
        }
    }

    private var heroColor: Color {
        if pickupCount == 0 { return .textTertiary }
        return isCompliantDay ? .accentSage : .accentAmber
    }

    @ViewBuilder
    private var heroSubtitle: some View {
        if pickupCount == 0 {
            Text("Open an app to start tracking today.")
                .appText(.caption)
                .foregroundStyle(Color.textSecondary)
        } else if isCompliantDay {
            Text("All sessions stayed under 20 min.")
                .appText(.caption)
                .foregroundStyle(Color.accentSage)
        } else {
            Text("Try to break long sessions into 20-min blocks.")
                .appText(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var heroRing: some View {
        let compliance = ScreenTimeAggregator.today2020ComplianceRate(pickups: pickups)
        let pct = Int((compliance * 100).rounded())
        return ZStack {
            Circle()
                .stroke(Color.hairlineStrong, lineWidth: 6)
            Circle()
                .trim(from: 0, to: compliance)
                .stroke(
                    isCompliantDay ? Color.accentSage : Color.accentAmber,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(pct)%")
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .tracking(-0.4)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .frame(width: 76, height: 76)
        .accessibilityLabel("\(pct)% of pickups under 20 minutes")
    }

    // MARK: - Sub stats (inline strip)

    private var subStatsBlock: some View {
        HStack(spacing: 0) {
            subStat(
                value: durationShort(total),
                label: "Total"
            )
            divider
            subStat(
                value: pickupCount > 0 ? durationShort(avgPickup) : "—",
                label: "Avg pickup"
            )
            divider
            subStat(
                value: "\(exerciseCount)",
                label: "Exercises",
                tint: exerciseCount > 0 ? .accentSage : nil
            )
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) { hairline }
        .overlay(alignment: .bottom) { hairline }
    }

    private func subStat(value: String, label: String, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .appText(.statValue)
                .foregroundStyle(tint ?? Color.textPrimary)
            Text(label)
                .appText(.statLabel)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(height: 1)
    }

    // MARK: - Recommendation

    /// Picks the right exercise based on today's compliance state.
    /// - Compliant day → maintenance (Quick rest with slow blinks framing)
    /// - Long session today → Quick rest, framed as relief
    private var recommendedExercise: EyeExercise { .quickRest }

    private var recommendationLabel: String {
        isCompliantDay ? "Maintenance" : "Recommended now"
    }

    private var recommendationHeader: some View {
        HStack {
            Text(recommendationLabel.uppercased())
                .appText(.sectionLabel)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text("More")
                .appText(.captionStrong)
                .foregroundStyle(Color.accentAmber)
        }
    }

    private var recommendationCard: some View {
        Button { pendingExercise = recommendedExercise } label: {
            HStack(alignment: .top, spacing: 16) {
                recommendationGlyph
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(recommendedExercise.totalDuration / 60)) min · \(recommendedExercise.displayName)")
                        .appText(.caption)
                        .foregroundStyle(isCompliantDay ? Color.accentSage : Color.accentAmber)
                    Text(recommendationTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.3)
                        .foregroundStyle(Color.textPrimary)
                    Text(recommendationReason)
                        .appText(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(2)
                        .padding(.top, 2)
                    HStack(spacing: 4) {
                        Text("Start")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(-0.1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(isCompliantDay ? Color.accentSage : Color.accentAmber)
                    .padding(.top, 6)
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var recommendationGlyph: some View {
        let tint = isCompliantDay ? Color.accentSage : Color.accentAmber
        let bg = isCompliantDay ? Color.accentSageSoft : Color.accentAmberSoft
        return ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(bg)
            Image(systemName: "eye.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 56, height: 56)
    }

    private var recommendationTitle: String {
        isCompliantDay ? "Slow blinks" : "Look far & blink"
    }

    private var recommendationReason: String {
        if pickupCount == 0 {
            return "A 2-min start to set the tone for the day."
        }
        if isCompliantDay {
            return "Day's looking good. Keep blinking — slow blinks help the tear film stay even."
        }
        let mins = Int((longest / 60).rounded())
        return "You just had a \(mins)-min stretch — give your ciliary muscles a break."
    }

    // MARK: - Other exercises (rows)

    private var otherExercisesList: some View {
        VStack(spacing: 0) {
            ForEach(otherExercises) { exercise in
                Button { pendingExercise = exercise } label: {
                    HStack(spacing: 12) {
                        Text("\(Int(exercise.totalDuration / 60)) min")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(-0.2)
                            .monospacedDigit()
                            .frame(width: 44, alignment: .leading)
                            .foregroundStyle(Color.textPrimary)
                        Text(exercise.displayName)
                            .appText(.body)
                            .foregroundStyle(Color.textPrimary)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.vertical, 13)
                    .padding(.horizontal, 4)
                    .overlay(alignment: .top) {
                        if exercise != otherExercises.first {
                            hairline
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var otherExercises: [EyeExercise] {
        EyeExercise.allCases.filter { $0 != recommendedExercise }
    }

    // MARK: - Floating session pill (Liquid Glass)

    private var sessionPill: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(pillDotColor)
                .frame(width: 8, height: 8)
                .shadow(color: pillDotColor.opacity(pillDotGlow), radius: 6)
                .accessibilityHidden(true)

            Text(pillLabel)
                .appText(.caption)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let action = pillAction {
                Button(action: action.run) {
                    Text(action.title)
                        .appText(.pillAction)
                        .foregroundStyle(action.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.a11y)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .liquidGlass(in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session: \(pillLabel)")
    }

    private var pillDotColor: Color {
        switch sessionManager.state {
        case .alerting:        return .accentAmber
        case .active:          return isCompliantDay ? .accentSage : .accentAmber
        case .paused, .idle:   return .accentAmber.opacity(0.35)
        }
    }

    private var pillDotGlow: Double {
        switch sessionManager.state {
        case .alerting: return 0.9
        case .active:   return 0.6
        case .paused, .idle: return 0
        }
    }

    private var pillLabel: String {
        switch sessionManager.state {
        case .idle:     return "Auto-protect off"
        case .active:   return isCompliantDay ? "All clear · auto-protecting" : "Auto-protecting your eyes"
        case .paused:   return "Paused"
        case .alerting: return "Time for a break"
        }
    }

    private var pillAction: PillAction? {
        switch sessionManager.state {
        case .idle:
            return PillAction(
                title: "Start", a11y: "Start auto-protect session",
                tint: .accentAmber,
                run: { try? sessionManager.startSession() }
            )
        case .active:
            return PillAction(
                title: "Pause", a11y: "Pause auto-protect session",
                tint: .textSecondary,
                run: { try? sessionManager.pauseSession() }
            )
        case .paused:
            return PillAction(
                title: "Resume", a11y: "Resume auto-protect session",
                tint: .accentAmber,
                run: { try? sessionManager.resumeSession() }
            )
        case .alerting:
            return PillAction(
                title: "Take it", a11y: "Take a break now",
                tint: .accentAmber,
                run: { showBreakView = true }
            )
        }
    }

    // MARK: - Background warmth

    private var warmOrbs: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.accentAmberSoft)
                    .frame(width: 280, height: 280)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.3)
                Circle()
                    .fill(Color.accentAmberSoft)
                    .frame(width: 240, height: 240)
                    .blur(radius: 60)
                    .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.25)
                    .opacity(0.7)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func durationShort(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(total)s"
    }

    private func durationLabel(
        _ seconds: TimeInterval,
        baseStyle: AppTextStyle,
        color: Color
    ) -> some View {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            if h > 0 {
                Text("\(h)").appText(baseStyle).foregroundStyle(color)
                Text("h").appText(.heroUnit).foregroundStyle(Color.textSecondary)
                Text("\(m)").appText(baseStyle).foregroundStyle(color)
                Text("m").appText(.heroUnit).foregroundStyle(Color.textSecondary)
            } else if m > 0 {
                Text("\(m)").appText(baseStyle).foregroundStyle(color)
                Text("m").appText(.heroUnit).foregroundStyle(Color.textSecondary)
            } else {
                Text("\(s)").appText(baseStyle).foregroundStyle(color)
                Text("s").appText(.heroUnit).foregroundStyle(Color.textSecondary)
            }
        }
    }
}

// MARK: - Pill action descriptor

private struct PillAction {
    let title: String
    let a11y: String
    let tint: Color
    let run: () -> Void
}

#Preview {
    let schema = Schema([
        Session.self, BreakRecord.self, UserSettings.self,
        PetState.self, EyeExerciseRecord.self, PickupSession.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    return HomeView()
        .environment(SessionManager())
        .modelContainer(container)
}
