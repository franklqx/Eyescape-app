import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Query private var sessions: [Session]
    @Query private var breaks: [BreakRecord]

    var body: some View {
        ZStack {
            Color(hex: "0C0C10").ignoresSafeArea()

            VStack(spacing: 0) {
                Color.clear.frame(height: 60)   // DI clearance

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("INSIGHTS")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(hex: "E8954A"))
                                    .tracking(1.2)
                                Text("Your eye health")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(Color(hex: "F2F2F5"))
                            }
                            Spacer()
                            Text("This week")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "E8954A"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "E8954A").opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color(hex: "E8954A").opacity(0.25), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .padding(.bottom, 24)

                        if sessions.isEmpty {
                            emptyState
                        } else {
                            statsGrid
                            Spacer().frame(height: 24)
                            weeklyTrend
                            Spacer().frame(height: 24)
                            aiInsightsSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)   // tab bar clearance
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Circle()
                .fill(Color(hex: "E8954A").opacity(0.12))
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .fill(Color(hex: "E8954A"))
                        .frame(width: 20, height: 20)
                        .shadow(color: Color(hex: "E8954A").opacity(0.6), radius: 8)
                )
            Text("No sessions yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "F2F2F5"))
            Text("Start your first session to see\nyour eye health insights here.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8A8A96"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatCard(
                value: todayTotalFormatted,
                unit: nil,
                label: "Today total"
            )
            StatCard(
                value: avgSessionFormatted,
                unit: "min",
                label: "Avg session",
                accent: false
            )
            StatCard(
                value: longestSessionFormatted,
                unit: "min",
                label: "Longest session"
            )
            StatCard(
                value: breakRateFormatted,
                unit: "%",
                label: "Break rate",
                accent: true
            )
        }
    }

    // MARK: - Weekly Trend

    private var weeklyTrend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DAILY SCREEN TIME")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "E8954A"))
                .tracking(1.2)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.isToday ? Color(hex: "E8954A") : barColor(minutes: item.minutes))
                            .frame(height: barHeight(minutes: item.minutes))
                        Text(item.dayLabel)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(item.isToday ? Color(hex: "E8954A") : Color(hex: "8A8A96"))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 72, alignment: .bottom)
        }
        .padding(16)
        .background(Color(hex: "18181F"))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - AI Insights

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI INSIGHTS")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "E8954A"))
                .tracking(1.2)

            ForEach(aiInsights, id: \.title) { insight in
                InsightCard(title: insight.title, content: insight.content)
            }
        }
    }

    // MARK: - Computed Analytics

    private var todaySessions: [Session] {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return sessions.filter { $0.startedAt >= startOfDay }
    }

    private var todayTotalFormatted: String {
        let total = todaySessions.compactMap(\.duration).reduce(0, +)
        let h = Int(total) / 3600
        let m = (Int(total) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    private var avgSessionFormatted: String {
        let durations = sessions.compactMap(\.duration)
        guard !durations.isEmpty else { return "—" }
        let avg = durations.reduce(0, +) / Double(durations.count) / 60
        return String(Int(avg))
    }

    private var longestSessionFormatted: String {
        guard let max = sessions.compactMap(\.duration).max() else { return "—" }
        return String(Int(max / 60))
    }

    private var breakRateFormatted: String {
        guard !sessions.isEmpty else { return "—" }
        let completed = breaks.filter { !$0.wasSkipped }.count
        let rate = Double(completed) / Double(sessions.count) * 100
        return String(Int(min(rate, 100)))
    }

    // Weekly data (Mon–Sun or Sun–Sat based on locale)
    private struct DayData {
        let dayLabel: String
        let minutes: Int
        let isToday: Bool
    }

    private var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

        return (0..<7).map { offset in
            let dayStart = calendar.date(byAdding: .day, value: -(6 - offset), to: today)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let isToday = calendar.isDateInToday(dayStart)

            let dayMinutes = sessions
                .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                .compactMap(\.duration)
                .reduce(0, +) / 60

            return DayData(dayLabel: dayLabels[offset], minutes: Int(dayMinutes), isToday: isToday)
        }
    }

    private func barHeight(minutes: Int) -> CGFloat {
        let maxMinutes = weeklyData.map(\.minutes).max() ?? 1
        guard maxMinutes > 0 else { return 4 }
        let ratio = CGFloat(minutes) / CGFloat(maxMinutes)
        return max(4, ratio * 48)
    }

    private func barColor(minutes: Int) -> Color {
        let maxMinutes = weeklyData.map(\.minutes).max() ?? 1
        guard maxMinutes > 0, minutes > 0 else { return Color(hex: "22222C") }
        let ratio = Double(minutes) / Double(maxMinutes)
        return ratio > 0.6 ? Color(hex: "E8954A").opacity(0.5) : Color(hex: "22222C")
    }

    // Rule-based AI insights
    private struct InsightData { let title: String; let content: String }

    private var aiInsights: [InsightData] {
        var results: [InsightData] = []
        let durations = sessions.compactMap(\.duration)
        guard !durations.isEmpty else { return results }

        let avgMin = durations.reduce(0, +) / Double(durations.count) / 60
        let maxMin = (durations.max() ?? 0) / 60
        let completed = breaks.filter { !$0.wasSkipped }.count
        let rate = sessions.isEmpty ? 0.0 : Double(completed) / Double(sessions.count)

        if avgMin > 30 {
            results.append(InsightData(
                title: "Sessions running long",
                content: "Your average session is \(Int(avgMin)) min. Try to take a break every 20 min to reduce eye strain."
            ))
        }
        if maxMin > 45 {
            results.append(InsightData(
                title: "Long session detected",
                content: "Your longest session was \(Int(maxMin)) min. Extended use increases eye fatigue significantly."
            ))
        }
        if rate >= 0.8 {
            results.append(InsightData(
                title: "Great break streak",
                content: "\(Int(rate * 100))% break completion this week. Consistent rest keeps eyes healthy long-term."
            ))
        } else if rate < 0.5 && !sessions.isEmpty {
            results.append(InsightData(
                title: "Low break rate",
                content: "You're completing \(Int(rate * 100))% of breaks. Try not to skip — even 20 seconds helps."
            ))
        }
        if results.isEmpty {
            results.append(InsightData(
                title: "Looking good",
                content: "Your eye health habits are on track. Keep using Eyescape consistently for best results."
            ))
        }
        return results
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let value: String
    let unit: String?
    let label: String
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .regular, design: .monospaced))
                    .foregroundColor(accent ? Color(hex: "E8954A") : Color(hex: "F2F2F5"))
                if let unit {
                    Text(unit)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(accent ? Color(hex: "E8954A").opacity(0.7) : Color(hex: "8A8A96"))
                }
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "8A8A96"))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "18181F"))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - InsightCard

private struct InsightCard: View {
    let title: String
    let content: String     // renamed: 'body' conflicts with SwiftUI View.body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "E8954A"))
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "F2F2F5"))
            }
            Text(content)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8A8A96"))
                .lineSpacing(3)
                .padding(.leading, 14)
        }
        .padding(14)
        .background(Color(hex: "18181F"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .overlay(
            Rectangle()
                .fill(Color(hex: "E8954A"))
                .frame(width: 2)
                .clipShape(RoundedRectangle(cornerRadius: 2)),
            alignment: .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let schema = Schema([Session.self, BreakRecord.self, UserSettings.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    AnalyticsView().modelContainer(container)
}
