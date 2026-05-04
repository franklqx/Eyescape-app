import SwiftUI

/// L2 — Category drilldown. Lists the apps inside one category, sorted by
/// each app's longest session. Tap → AppDetailView.
///
/// Uses mock data until the DeviceActivityReport extension is wired up.
struct CategoryDetailView: View {
    let category: ScreenTimeCategory

    @State private var range: InsightsView.TimeRange = .day

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 12)

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

                    appList
                        .padding(.horizontal, 22)

                    Color.clear.frame(height: 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: AppEntry.self) { app in
            AppDetailView(app: app, category: category)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(category.color)
                    .frame(width: 14, height: 14)
                Text(category.displayName)
                    .appText(.pageTitle)
                    .foregroundStyle(Color.textPrimary)
            }
            Text("\(mockApps.count) apps · \(durationShort(totalToday)) today")
                .appText(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Range picker (matches L1)

    private var rangePicker: some View {
        HStack(spacing: 4) {
            ForEach(InsightsView.TimeRange.allCases) { r in
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

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Longest in \(category.displayName) today")
                .appText(.subHeader)
                .foregroundStyle(Color.textSecondary)
            durationLargeLabel(longestInCategory)
            if let topApp = mockApps.first {
                Text("in \(topApp.name) · \(topApp.timeRangeLabel)")
                    .appText(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var longestInCategory: TimeInterval {
        mockApps.map(\.longest).max() ?? 0
    }

    private var totalToday: TimeInterval {
        mockApps.reduce(0) { $0 + $1.totalToday }
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

    // MARK: - Sub-stats

    private var subStatsBlock: some View {
        let totalPickups = mockApps.reduce(0) { $0 + $1.pickups }
        let overTwentyApps = mockApps.filter { $0.longest >= 20 * 60 }.count

        return HStack(spacing: 0) {
            subStat(value: durationShort(totalToday), label: "Total")
            divider
            subStat(value: "\(totalPickups)", label: "Pickups")
            divider
            subStat(
                value: "\(overTwentyApps)",
                label: "Over 20m",
                tint: overTwentyApps > 0 ? .accentAmber : nil
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

    // MARK: - App list

    private var appList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("APPS")
                    .appText(.sectionLabel)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("By longest session")
                    .appText(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            VStack(spacing: 0) {
                ForEach(mockApps) { app in
                    NavigationLink(value: app) {
                        appRow(app, isFirst: app.id == mockApps.first?.id)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func appRow(_ app: AppEntry, isFirst: Bool) -> some View {
        HStack(spacing: 12) {
            appIconBadge(for: app)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .appText(.body)
                    .foregroundStyle(Color.textPrimary)
                Text("\(app.pickups) sessions · \(durationShort(app.totalToday)) total")
                    .appText(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            Text(durationShort(app.longest))
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .tracking(-0.2)
                .foregroundStyle(app.longest >= 20 * 60 ? Color.accentAmber : Color.accentSage)
                .opacity(app.totalToday > 0 ? 1.0 : 0.4)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.vertical, 13)
        .overlay(alignment: .top) {
            if !isFirst { hairline }
        }
    }

    private func appIconBadge(for app: AppEntry) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(category.color.opacity(0.15))
            Text(app.iconLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(category.color)
        }
        .frame(width: 38, height: 38)
    }

    // MARK: - Mock data

    /// Mock app entries per category. Replace once DeviceActivity returns
    /// per-app `ApplicationToken`s for the selected category.
    private var mockApps: [AppEntry] {
        switch category {
        case .social:
            return [
                AppEntry(name: "Instagram", iconLabel: "IG", longest: 42 * 60, totalToday: 56 * 60, pickups: 6, timeRangeLabel: "14:22 → 15:04"),
                AppEntry(name: "X",         iconLabel: "𝕏",  longest: 22 * 60, totalToday: 32 * 60, pickups: 4, timeRangeLabel: "13:10 → 13:32"),
                AppEntry(name: "WhatsApp",  iconLabel: "WA", longest:  8 * 60, totalToday: 16 * 60, pickups: 3, timeRangeLabel: "11:00 → 11:08"),
                AppEntry(name: "TikTok",    iconLabel: "TT", longest:  0,      totalToday: 0,       pickups: 0, timeRangeLabel: "—"),
            ]
        case .entertainment:
            return [
                AppEntry(name: "YouTube", iconLabel: "YT", longest: 35 * 60, totalToday: 42 * 60, pickups: 3, timeRangeLabel: "20:00 → 20:35"),
                AppEntry(name: "Netflix", iconLabel: "NX", longest:  6 * 60, totalToday:  6 * 60, pickups: 1, timeRangeLabel: "21:30 → 21:36"),
            ]
        case .productivity:
            return [
                AppEntry(name: "Mail",     iconLabel: "✉", longest: 18 * 60, totalToday: 22 * 60, pickups: 5, timeRangeLabel: "09:15 → 09:33"),
                AppEntry(name: "Notes",    iconLabel: "▤", longest:  6 * 60, totalToday: 12 * 60, pickups: 4, timeRangeLabel: "10:40 → 10:46"),
            ]
        case .games:
            return [
                AppEntry(name: "Wordle",   iconLabel: "W", longest: 8 * 60,  totalToday: 12 * 60, pickups: 2, timeRangeLabel: "07:30 → 07:38"),
            ]
        case .creativity:
            return []
        case .other:
            return []
        }
    }

    private func durationShort(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(total)s"
    }
}

// MARK: - AppEntry

struct AppEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconLabel: String
    let longest: TimeInterval
    let totalToday: TimeInterval
    let pickups: Int
    let timeRangeLabel: String
}

#Preview {
    NavigationStack {
        CategoryDetailView(category: .social)
    }
}
