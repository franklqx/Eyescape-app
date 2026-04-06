import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(PetMoodEngine.self) private var petMoodEngine

    @State private var showBreakView  = false
    @State private var showPetBubble  = false
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

                Spacer()                          // pushes pet toward center

                petSection
                    .padding(.horizontal, 24)

                Spacer().frame(height: 36)        // fixed gap between pet and info

                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    sessionSection
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 100)       // tab bar clearance
            }
        }
        .task {
            await sessionManager.requestNotificationPermission()
        }
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
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: "F2F2F5"))
            Text(statusSubtitle)
                .font(.system(size: 13))
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

    // MARK: - Pet Section

    private var petSection: some View {
        VStack(spacing: 12) {
            // Dialogue bubble — appears above the cat when tapped
            if showPetBubble {
                Text(petMoodEngine.mood.message)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "F2F2F5"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "22222C"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottom)))
            }

            // Cat + name + mood label — tap to toggle dialogue bubble
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPetBubble.toggle()
                }
            } label: {
                VStack(spacing: 6) {
                    PetView(
                        mood: petMoodEngine.mood,
                        petColor: petMoodEngine.petState?.color ?? .gray
                    )
                    .frame(width: 80, height: 80)

                    if let petState = petMoodEngine.petState {
                        Text(petState.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "F2F2F5"))
                    }

                    Text(petMoodEngine.mood.label)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A96"))
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Session Section

    private var sessionSection: some View {
        Group {
            switch sessionManager.state {
            case .idle:
                idleCard
            case .active(let session), .alerting(let session), .paused(let session):
                activeCard(session: session)
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
                    .frame(height: 80)
                VStack(spacing: 4) {
                    Text("No active session")
                        .font(.system(size: 14, weight: .medium))
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
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "E8954A"))
                    .frame(width: 8, height: 8)
                    .shadow(color: Color(hex: "E8954A"), radius: 5)
                Text("Monitoring your screen time")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8A8A96"))
                Spacer()
            }
            .padding(20)
            .background(Color(hex: "22222C"))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                sessionManager.stopSession()
            } label: {
                Text("Stop")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "E05454"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(hex: "E05454").opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "E05454").opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
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
    let schema = Schema([Session.self, BreakRecord.self, UserSettings.self, PetState.self, EyeExerciseRecord.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    HomeView()
        .environment(SessionManager())
        .environment(PetMoodEngine())
        .modelContainer(container)
}
