import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, analytics, settings
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .home:      HomeView()
                case .analytics: AnalyticsView()
                case .settings:  SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            sessionManager.configure(modelContext: modelContext)
            storeManager.configure(modelContext: modelContext)
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house",
                iconSelected: "house.fill",
                label: "Home",
                isSelected: selectedTab == .home
            ) { selectedTab = .home }

            TabBarButton(
                icon: "chart.bar",
                iconSelected: "chart.bar.fill",
                label: "Insights",
                isSelected: selectedTab == .analytics
            ) { selectedTab = .analytics }

            TabBarButton(
                icon: "gearshape",
                iconSelected: "gearshape.fill",
                label: "Settings",
                isSelected: selectedTab == .settings
            ) { selectedTab = .settings }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)     // safe area for home indicator
        .background(
            Rectangle()
                .fill(Color(hex: "18181F"))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.white.opacity(0.07)),
                    alignment: .top
                )
        )
    }
}

// MARK: - TabBarButton

private struct TabBarButton: View {
    let icon: String
    let iconSelected: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? iconSelected : icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color(hex: "E8954A") : Color(hex: "8A8A96"))

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "E8954A") : Color(hex: "8A8A96"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let schema = Schema([Session.self, BreakRecord.self, UserSettings.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    RootView()
        .environment(SessionManager())
        .environment(StoreManager())
        .modelContainer(container)
}
