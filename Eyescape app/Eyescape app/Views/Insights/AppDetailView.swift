import SwiftUI

/// L3 — Single app detail. Hero is this app's longest session today, with the
/// time range. Below: hourly distribution + chronological session log.
///
/// Currently driven by the mock `AppEntry` passed from `CategoryDetailView`;
/// replace once DeviceActivity returns per-app hourly segments and we have
/// our own DeviceActivityMonitor extension producing real session boundaries.
struct AppDetailView: View {
    let app: AppEntry
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

                    hourlyBlock
                        .padding(.horizontal, 22)
                        .padding(.bottom, 28)

                    sessionsBlock
                        .padding(.horizontal, 22)

                    Color.clear.frame(height: 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                appIconBadge
                Text(app.name)
                    .appText(.pageTitle)
                    .foregroundStyle(Color.textPrimary)
            }
            Text("\(category.displayName) · \(app.pickups) sessions today")
                .appText(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var appIconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(category.color.opacity(0.15))
            Text(app.iconLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(category.color)
        }
        .frame(width: 32, height: 32)
    }

    // MARK: - Range picker

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
            Text("Longest session today")
                .appText(.subHeader)
                .foregroundStyle(Color.textSecondary)
            durationLargeLabel(app.longest)
            if app.longest >= 20 * 60 {
                Text("\(app.timeRangeLabel) · 78% longer than your weekly average")
                    .appText(.caption)
                    .foregroundStyle(Color.textSecondary)
            } else if app.totalToday > 0 {
                Text("All sessions stayed under 20 min.")
                    .appText(.caption)
                    .foregroundStyle(Color.accentSage)
            } else {
                Text("Not used today.")
                    .appText(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func durationLargeLabel(_ seconds: TimeInterval) -> some View {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        let color: Color = (seconds >= 20 * 60)
            ? .accentAmber
            : (seconds > 0 ? .accentSage : .textTertiary)

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
        let avgGap = app.pickups > 1
            ? app.totalToday / Double(app.pickups)
            : 0
        return HStack(spacing: 0) {
            subStat(value: durationShort(app.totalToday), label: "Total")
            divider
            subStat(value: "\(app.pickups)", label: "Pickups")
            divider
            subStat(value: avgGap > 0 ? durationShort(avgGap) : "—", label: "Avg gap")
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) { hairline }
        .overlay(alignment: .bottom) { hairline }
    }

    private func subStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .appText(.statValueLarge)
                .foregroundStyle(Color.textPrimary)
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

    // MARK: - Hourly distribution

    private var hourlyBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hourly use")
                    .appText(.captionStrong)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(peakLabel)
                    .appText(.caption)
                    .foregroundStyle(Color.accentAmber)
                    .monospacedDigit()
            }
            HStack(spacing: 1) {
                ForEach(0..<24, id: \.self) { hour in
                    let value = mockHourlyValues[hour]
                    let isPeak = hour == peakHour
                    Rectangle()
                        .fill(Color.accentAmber)
                        .opacity(isPeak ? 1.0 : (value > 0 ? 0.5 : 0.15))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(2, value * 56))
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                }
            }
            .frame(height: 56, alignment: .bottom)
            .padding(2)
            .background(Color.hairline)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack {
                Text("0").font(.system(size: 9, weight: .medium)).foregroundStyle(Color.textSecondary)
                Spacer()
                Text("6").font(.system(size: 9, weight: .medium)).foregroundStyle(Color.textSecondary)
                Spacer()
                Text("12").font(.system(size: 9, weight: .medium)).foregroundStyle(Color.textSecondary)
                Spacer()
                Text("18").font(.system(size: 9, weight: .medium)).foregroundStyle(Color.textSecondary)
                Spacer()
                Text("24").font(.system(size: 9, weight: .medium)).foregroundStyle(Color.textSecondary)
            }
            .monospacedDigit()
        }
    }

    private var peakLabel: String {
        guard app.totalToday > 0 else { return "no data" }
        return "peak \(peakHour)h · \(durationShort(app.longest))"
    }

    /// Mock hourly distribution (24 normalized values). Real implementation
    /// will read from `DeviceActivityResults<DeviceActivityData>` segmented by
    /// hour inside the report extension.
    private var mockHourlyValues: [CGFloat] {
        guard app.totalToday > 0 else { return Array(repeating: 0, count: 24) }
        return [0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
                0.12, 0.28, 0.18, 0.16, 0.08,
                0.36, 0.22, 1.00, 0.92, 0.32, 0.18,
                0.12, 0.24, 0.18, 0.08, 0.05, 0.05]
    }

    private var peakHour: Int {
        mockHourlyValues.indices.max(by: { mockHourlyValues[$0] < mockHourlyValues[$1] }) ?? 14
    }

    // MARK: - Sessions log

    private var sessionsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sessions today")
                .appText(.captionStrong)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, 4)

            if mockSessions.isEmpty {
                Text("No sessions recorded today.")
                    .appText(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.vertical, 14)
            } else {
                ForEach(Array(mockSessions.enumerated()), id: \.offset) { i, session in
                    sessionRow(session, isLongest: i == 0 && session.duration >= 20 * 60)
                        .overlay(alignment: .top) {
                            if i > 0 { hairline }
                        }
                }
            }
        }
    }

    private func sessionRow(_ session: SessionLog, isLongest: Bool) -> some View {
        HStack(spacing: 10) {
            Text(session.timeLabel)
                .appText(.caption)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 110, alignment: .leading)

            if isLongest {
                Text("LONGEST")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.accentAmber)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.accentAmberSoft, in: Capsule())
            }

            Spacer(minLength: 0)

            Text(durationShort(session.duration))
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .tracking(-0.3)
                .foregroundStyle(session.duration >= 20 * 60 ? Color.accentAmber : Color.textPrimary)
        }
        .padding(.vertical, 12)
    }

    /// Mock sessions list. Real implementation depends on the
    /// DeviceActivityMonitor extension capturing session-start/-end events.
    private var mockSessions: [SessionLog] {
        guard app.totalToday > 0 else { return [] }
        return [
            SessionLog(timeLabel: "14:22 → 15:04", duration: 42 * 60),
            SessionLog(timeLabel: "16:30 → 16:52", duration: 22 * 60),
            SessionLog(timeLabel: "12:10 → 12:28", duration: 18 * 60),
            SessionLog(timeLabel: "10:35 → 10:51", duration: 16 * 60),
            SessionLog(timeLabel: "09:47 → 09:55", duration:  8 * 60),
            SessionLog(timeLabel: "07:55 → 07:58", duration:  3 * 60),
        ]
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

// MARK: - Mock data types

private struct SessionLog: Identifiable {
    let id = UUID()
    let timeLabel: String
    let duration: TimeInterval
}

#Preview {
    NavigationStack {
        AppDetailView(
            app: AppEntry(
                name: "Instagram", iconLabel: "IG",
                longest: 42 * 60, totalToday: 56 * 60, pickups: 6,
                timeRangeLabel: "14:22 → 15:04"
            ),
            category: .social
        )
    }
}
