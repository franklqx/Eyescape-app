import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @Environment(ScreenTimeAuthManager.self) private var screenTimeAuth
    @State private var settings: UserSettings?
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Color.clear.frame(height: 60)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SETTINGS")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.accentAmber)
                                .tracking(1.2)
                            Text("Preferences")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                        }
                        .padding(.bottom, 32)

                        if let settings {
                            screenTimeSection
                            Spacer().frame(height: 24)
                            reminderSection(settings: settings)
                            Spacer().frame(height: 24)
                            proSection(settings: settings)
                            Spacer().frame(height: 24)
                            aboutSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            settings = UserSettings.fetchOrCreate(context: modelContext)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView {
                // Refresh settings after successful purchase
                settings = UserSettings.fetchOrCreate(context: modelContext)
            }
            .environment(storeManager)
        }
    }

    // MARK: - Screen Time Section

    private var screenTimeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Screen Time")

            SettingsCard {
                SettingsRow(
                    label: "System data",
                    subtitle: screenTimeStatusSubtitle
                ) {
                    if screenTimeAuth.status == .approved {
                        Text("Connected")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.accentAmber)
                    } else {
                        Button {
                            Task { await screenTimeAuth.requestAuthorization() }
                        } label: {
                            Text("Connect")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.accentAmber)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentAmber.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.accentAmber.opacity(0.4), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var screenTimeStatusSubtitle: String {
        switch screenTimeAuth.status {
        case .approved:      return "Real device data on. Stays on this iPhone."
        case .denied:        return "Permission denied. Re-enable in iOS Settings."
        case .notDetermined: return "Use real screen-time data from your device."
        }
    }

    // MARK: - Reminder Section

    private func reminderSection(settings: UserSettings) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Reminder")

            SettingsCard {
                SettingsRow(
                    label: "Interval",
                    subtitle: settings.isPro ? "Custom (Pro)" : "Fixed — 20 min"
                ) {
                    if settings.isPro {
                        Text("\(settings.customIntervalMinutes) min")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Color.accentAmber)
                    } else {
                        Text("20 min")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Pro Section

    private func proSection(settings: UserSettings) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: settings.isPro ? "Pro — Active" : "Pro Features")

            if !settings.isPro {
                Button { showPaywall = true } label: {
                    proUpsellBanner
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }

            SettingsCard {
                // DI Alert Size
                SettingsRow(label: "DI Alert Size", subtitle: "Dynamic Island expanded height", locked: !settings.isPro) {
                    PillGroup(
                        options: AlertSize.allCases,
                        selected: settings.diAlertSize,
                        label: { $0.rawValue },
                        enabled: settings.isPro
                    ) { selected in
                        settings.diAlertSize = selected
                        try? modelContext.save()
                    }
                }

                Divider().background(Color.white.opacity(0.07))

                // Haptic on alert
                SettingsRow(label: "Haptic on alert", subtitle: "Vibrate when reminder fires", locked: !settings.isPro) {
                    Toggle("", isOn: Binding(
                        get: { settings.hapticEnabled },
                        set: { settings.hapticEnabled = $0; try? modelContext.save() }
                    ))
                    .tint(Color.accentAmber)
                    .disabled(!settings.isPro)
                    .labelsHidden()
                }

                if settings.hapticEnabled && settings.isPro {
                    Divider().background(Color.white.opacity(0.07))

                    // Intensity
                    SettingsRow(label: "Intensity", subtitle: "Vibration strength") {
                        PillGroup(
                            options: HapticIntensity.allCases,
                            selected: settings.hapticIntensity,
                            label: { $0.rawValue },
                            enabled: true
                        ) { selected in
                            settings.hapticIntensity = selected
                            try? modelContext.save()
                        }
                    }

                    Divider().background(Color.white.opacity(0.07))

                    // Pattern
                    SettingsRow(label: "Pattern", subtitle: "Single or double tap") {
                        PillGroup(
                            options: HapticPattern.allCases,
                            selected: settings.hapticPattern,
                            label: { $0.rawValue },
                            enabled: true
                        ) { selected in
                            settings.hapticPattern = selected
                            try? modelContext.save()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pro Upsell Banner

    private var proUpsellBanner: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentAmber)
                .frame(width: 8, height: 8)
                .shadow(color: Color.accentAmber.opacity(0.7), radius: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text("Unlock Eyescape Pro")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text("DI size · Custom interval · Haptic control")
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
            }
            Spacer()
            Text("↗")
                .font(.system(size: 16))
                .foregroundColor(Color.accentAmber)
        }
        .padding(14)
        .background(Color.accentAmber.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentAmber.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "About")
            SettingsCard {
                SettingsRow(label: "Version") {
                    Text("1.0.0")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.textSecondary)
                }
                Divider().background(Color.white.opacity(0.07))
                SettingsRow(label: "Device") {
                    Text("iPhone 14 Pro+")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
    }
}

// MARK: - Sub-components

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(Color.accentAmber)
            .tracking(1.2)
            .padding(.bottom, 8)
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.vertical, 4)
            .background(Color.appSurface)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct SettingsRow<Trailing: View>: View {
    let label: String
    var subtitle: String? = nil
    var locked: Bool = false
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundColor(locked ? Color.textSecondary : Color.textPrimary)
                    if locked {
                        Text("PRO")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.accentAmber)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.accentAmber.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary.opacity(0.7))
                }
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct PillGroup<T: Hashable>: View {
    let options: [T]
    let selected: T
    let label: (T) -> String
    let enabled: Bool
    let onSelect: (T) -> Void

    var body: some View {
        HStack(spacing: 5) {
            ForEach(options, id: \.self) { option in
                Button {
                    guard enabled else { return }
                    onSelect(option)
                } label: {
                    Text(label(option))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(isSelected(option) ? Color.accentAmber : Color.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            isSelected(option)
                                ? Color.accentAmber.opacity(0.12)
                                : Color.appSurfaceElev
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isSelected(option) ? Color.accentAmber : Color.white.opacity(0.07),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .opacity(enabled ? 1 : 0.4)
            }
        }
    }

    private func isSelected(_ option: T) -> Bool { option == selected }
}

#Preview {
    let schema = Schema([Session.self, BreakRecord.self, UserSettings.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    SettingsView()
        .modelContainer(container)
        .environment(StoreManager())
        .environment(ScreenTimeAuthManager())
}
