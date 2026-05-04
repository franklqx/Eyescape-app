import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable, Identifiable {
        case home, insights, settings
        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .home:     HomeView()
                case .insights: InsightsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Liquid Glass tab bar
            LiquidGlassTabBar(selected: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            sessionManager.configure(modelContext: modelContext)
            storeManager.configure(modelContext: modelContext)
        }
    }
}

// MARK: - LiquidGlassTabBar

struct LiquidGlassTabBar: View {
    @Binding var selected: RootView.Tab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RootView.Tab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .frame(height: 64)
        .frame(maxWidth: .infinity)
        .liquidGlass(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private func tabButton(_ tab: RootView.Tab) -> some View {
        let isActive = selected == tab
        Button {
            withAnimation(.snappy(duration: 0.18)) { selected = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: iconName(for: tab, active: isActive))
                    .font(.system(size: 19, weight: .medium))
                Text(label(for: tab))
                    .appText(.tabLabel)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(isActive ? Color.accentAmber : Color.textSecondary)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.accentAmberSoft)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label(for: tab))
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private func iconName(for tab: RootView.Tab, active: Bool) -> String {
        switch tab {
        case .home:     return active ? "house.fill"      : "house"
        case .insights: return active ? "chart.bar.fill"  : "chart.bar"
        case .settings: return active ? "gearshape.fill"  : "gearshape"
        }
    }

    private func label(for tab: RootView.Tab) -> String {
        switch tab {
        case .home:     return "Home"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }
}

#Preview {
    let schema = Schema([
        Session.self, BreakRecord.self, UserSettings.self,
        PetState.self, EyeExerciseRecord.self, PickupSession.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    return RootView()
        .environment(SessionManager())
        .environment(StoreManager())
        .modelContainer(container)
}
