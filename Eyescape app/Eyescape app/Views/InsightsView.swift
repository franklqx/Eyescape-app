import SwiftUI
import SwiftData

/// L1 — Insights overview. Hero is today's longest single session (not total).
/// Sub-stats: total · avg gap · compliance. Then a 7-day stacked-by-category
/// trend chart and a sortable category list. Tapping a category navigates
/// into `CategoryDetailView` (L2).
struct InsightsView: View {
    @Query private var pickups: [PickupSession]
    @Query private var sessions: [Session]
    @Query private var breaks: [BreakRecord]
    @Query private var exercises: [EyeExerciseRecord]

    @State private var range: TimeRange = .day

    enum TimeRange: String, CaseIterable, Identifiable {
        case day, week, month
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                warmOrbs

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear.frame(height: 50)

                        header
                            .padding(.horizontal, 22)
                            .padding(.bottom, 20)

                        rangePicker
                            .padding(.horizontal, 22)
                            .padding(.bottom, 24)

                        heroBlock
                            .padding(.horizontal, 22)
                            .padding(.bottom, 18)

                        subStatsBlock
                            .padding(.horizontal, 22)
                            .padding(.bottom, 28)

                        weeklyTrend
                            .padding(.horizontal, 22)
                            .padding(.bottom, 28)

                        categorySection
                            .padding(.horizontal, 22)

                        Color.clear.frame(height: 120)
                    }
                }
            }
            .navigationDestination(for: ScreenTimeCategory.self) { category in
                CategoryDetailView(category: category)
            }
        }
    }

    // MARK: - Derived

    private var longest: TimeInterval {
        ScreenTimeAggregator.todayLongestPickup(pickups: pickups)
    }
    private var total: TimeInterval {
        ScreenTimeAggregator.todayTotalScreenTime(pickups: pickups)
    }
    private var pickupCount: Int {
        ScreenTimeAggregator.todayPickupCount(pickups: pickups)
    }
    private var avgGap: TimeInterval {
        guard pickupCount > 0 else { return 0 }
        return total / Double(pickupCount)
    }
    private var compliance: Double {
        ScreenTimeAggregator.today2020ComplianceRate(pickups: pickups)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your eye health")
                .appText(.pageTitle)
                .foregroundStyle(Color.textPrimary)
            Text(headerSubtitle)
                .appText(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var headerSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return "\(formatter.string(from: .now)) · last 7 days tracked"
    }

    // MARK: - Range picker

    private var rangePicker: some View {
        HStack(spacing: 4) {
            ForEach(TimeRange.allCases) { r in
                Button { range = r } label: {
                    Text(r.label)
                        .appText(.captionStrong)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .foregroundStyle(range == r ? Color.textPrimary : Color.textSecondary)
                        .background {
                            if range == r {
                                Capsule().fill(Color.appSurface)
                                    .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.appSurfaceElev, in: Capsule())
    }

    // MARK: - Hero (longest session)

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Longest session today")
                .appText(.subHeader)
                .foregroundStyle(Color.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if pickupCount == 0 {
                    Text("—")
                        .appText(.heroValueLarge)
                        .foregroundStyle(Color.textTertiary)
                } else {
                    durationLargeLabel(longest)
                }
            }

            if pickupCount > 0 {
                Text(heroFootnote)
                    .appText(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var heroFootnote: String {
        if longest >= 20 * 60 {
            return "Try breaking long stretches into 20-min blocks."
        }
        return "All sessions stayed under 20 min."
    }

    @ViewBuilder
    private func durationLargeLabel(_ seconds: TimeInterval) -> some View {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        let color: Color = (seconds >= 20 * 60) ? .accentAmber : .accentSage

        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if h > 0 {
                Text("\(h)").appText(.heroValueLarge).foregroundStyle(color)
                Text("h").appText(.heroUnit).foregroundStyle(Color.textSecondary)
                Text("\(m)").appText(.heroValueLarge).foregroundStyle(color)
                Text("m").appText(.heroUnit).foregroundStyle(Color.textSecondary)
            } else if m > 0 {
                Text("\(m)").appText(.heroValueLarge).foregroundStyle(color)
                Text("m").appText(.heroUnit).foregroundStyle(Color.textSecondary)
            } else {
                Text("\(s)").appText(.heroValueLarge).foregroundStyle(color)
                Text("s").appText(.heroUnit).foregroundStyle(Color.textSecondary)
            }
        }
    }

    // MARK: - Sub-stats inline

    private var subStatsBlock: some View {
        HStack(spacing: 0) {
            subStat(value: durationShort(total), label: "Total")
            divider
            subStat(value: pickupCount > 0 ? durationShort(avgGap) : "—", label: "Avg gap")
            divider
            subStat(
                value: pickupCount > 0 ? "\(Int((compliance * 100).rounded()))%" : "—",
                label: "Compliance",
                tint: pickupCount > 0 && compliance >= 0.8 ? .accentSage : nil
            )
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) { hairline }
        .overlay(alignment: .bottom) { hairline }
    }

    private func subStat(value: String, label: String, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .appText(.statValueLarge)
                .foregroundStyle(tint ?? Color.textPrimary)
            Text(label)
                .appText(.statLabel)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }

    private var divider: some View {
        Rectangle().fill(Color.hairline).frame(width: 1).frame(maxHeight: .infinity)
    }
    private var hairline: some View {
        Rectangle().fill(Color.hairline).frame(height: 1)
    }

    // MARK: - Weekly trend

    private var weeklyTrend: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Daily by category")
                    .appText(.captionStrong)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Last 7 days")
                    .appText(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            HStack(alignment: .bottom, spacing: 7) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 8) {
                        stackedBar(item.segments)
                        Text(item.dayLabel)
                            .font(.system(size: 10, weight: item.isToday ? .semibold : .medium))
                            .monospacedDigit()
                            .foregroundStyle(item.isToday ? Color.textPrimary : Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.dayLabel): \(item.totalMinutes) minutes")
                }
            }
            .frame(height: 110)
        }
    }

    private func stackedBar(_ segments: [(category: ScreenTimeCategory, height: CGFloat)]) -> some View {
        VStack(spacing: 1) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                Rectangle()
                    .fill(segment.category.color)
                    .frame(height: segment.height)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 96)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .background(Color.appSurfaceElev, in: RoundedRectangle(cornerRadius: 5))
    }

    /// Mock weekly data — to be replaced once DeviceActivity per-category
    /// segments are wired through the Family Controls report extension.
    private var weeklyData: [DayBar] {
        let labels = ["M", "Tu", "W", "Th", "F", "Sa", "Su"]
        let mock: [[CGFloat]] = [
            [18, 8, 6],
            [36, 14, 8],
            [22, 12, 6],
            [42, 18, 10],
            [26, 14, 0],
            [14, 6, 0],
            [32, 14, 6],
        ]
        let cats: [ScreenTimeCategory] = [.social, .entertainment, .productivity]
        let todayIndex = Calendar.current.weekdayIndexFromMonday()

        return (0..<7).map { i in
            let segments = zip(cats, mock[i]).map { (category: $0, height: $1) }
            return DayBar(
                dayLabel: labels[i],
                isToday: i == todayIndex,
                totalMinutes: Int(mock[i].reduce(0, +)),
                segments: Array(segments)
            )
        }
    }

    // MARK: - Category list

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BY CATEGORY")
                    .appText(.sectionLabel)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("By longest session")
                    .appText(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            VStack(spacing: 0) {
                ForEach(mockCategories) { entry in
                    NavigationLink(value: entry.category) {
                        categoryRow(entry, isFirst: entry.id == mockCategories.first?.id)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func categoryRow(_ entry: CategoryEntry, isFirst: Bool) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(entry.category.color)
                .frame(width: 10, height: 10)

            Text(entry.category.displayName)
                .appText(.body)
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text(durationShort(entry.longest))
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .tracking(-0.2)
                    .foregroundStyle(entry.longest >= 20 * 60 ? Color.accentAmber : Color.accentSage)
                Text("\(durationShort(entry.totalToday)) today")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(Color.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            if !isFirst { hairline }
        }
    }

    private var mockCategories: [CategoryEntry] {
        [
            CategoryEntry(category: .social,        longest: 42 * 60, totalToday: 72 * 60),
            CategoryEntry(category: .entertainment, longest: 35 * 60, totalToday: 48 * 60),
            CategoryEntry(category: .productivity,  longest: 18 * 60, totalToday: 34 * 60),
            CategoryEntry(category: .games,         longest:  8 * 60, totalToday: 12 * 60),
        ]
    }

    // MARK: - Background warmth

    private var warmOrbs: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.accentAmberSoft)
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.3)
                .opacity(0.7)
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
}

// MARK: - Supporting types

/// Apple Screen Time-style category. Maps to `categoryTokens` returned by
/// DeviceActivity for the report extension.
enum ScreenTimeCategory: String, CaseIterable, Hashable, Identifiable {
    case social, entertainment, productivity, games, creativity, other
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .social:        return "Social"
        case .entertainment: return "Entertainment"
        case .productivity:  return "Productivity"
        case .games:         return "Games"
        case .creativity:    return "Creativity"
        case .other:         return "Other"
        }
    }

    var color: Color {
        switch self {
        case .social:        return .catSocial
        case .entertainment: return .catEntertainment
        case .productivity:  return .catProductivity
        case .games:         return .catGames
        case .creativity:    return .catCreativity
        case .other:         return .catOther
        }
    }
}

private struct DayBar: Identifiable {
    let id = UUID()
    let dayLabel: String
    let isToday: Bool
    let totalMinutes: Int
    let segments: [(category: ScreenTimeCategory, height: CGFloat)]
}

struct CategoryEntry: Identifiable {
    let id = UUID()
    let category: ScreenTimeCategory
    let longest: TimeInterval
    let totalToday: TimeInterval
}

extension Calendar {
    /// 0 = Monday … 6 = Sunday — matches the M/Tu/W/Th/F/Sa/Su axis order.
    func weekdayIndexFromMonday() -> Int {
        let weekday = component(.weekday, from: .now)   // 1=Sunday, 2=Monday ...
        return (weekday + 5) % 7                         // → 0=Monday … 6=Sunday
    }
}

#Preview {
    let schema = Schema([
        Session.self, BreakRecord.self, UserSettings.self,
        PetState.self, EyeExerciseRecord.self, PickupSession.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    return InsightsView()
        .modelContainer(container)
}
