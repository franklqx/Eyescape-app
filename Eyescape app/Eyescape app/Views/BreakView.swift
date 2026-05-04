import SwiftUI
import UIKit

struct BreakView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var secondsLeft = 20
    @State private var timerActive = true
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Breathing amber dot — scale 1.0→1.3 every 3s, mimics slow breath
                Circle()
                    .fill(Color.accentAmber)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.accentAmber.opacity(0.6), radius: 20)
                    .shadow(color: Color.accentAmber.opacity(0.25), radius: 60)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 3).repeatForever(autoreverses: true)
                        ) { pulseScale = 1.3 }
                    }

                Spacer().frame(height: 24)

                Text("Rest for 20 seconds")
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(Color.textPrimary)

                Spacer().frame(height: 8)

                Text("Look at something 20 feet away.\nBlink slowly. Let your eyes relax.")
                    .appText(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer().frame(height: 40)

                // Countdown — the ONLY place in the app where a timer number is visible
                Text(String(format: "00:%02d", secondsLeft))
                    .appText(.countdown)
                    .foregroundStyle(Color.accentAmber)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: secondsLeft)
                    .accessibilityLabel("\(secondsLeft) seconds remaining")

                Spacer().frame(height: 44)

                Button { confirm() } label: {
                    Text(secondsLeft > 0 ? "Done early" : "Done")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.3)
                        .foregroundStyle(Color.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentAmber, in: RoundedRectangle(cornerRadius: 16))
                }

                Spacer().frame(height: 12)

                Button { skip() } label: {
                    Text("Skip this break")
                        .appText(.body)
                        .foregroundStyle(Color.textSecondary)
                        .frame(minHeight: 44)
                }

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .task { await runCountdown() }
    }

    // MARK: - Timer

    private func runCountdown() async {
        while timerActive && secondsLeft > 0 {
            try? await Task.sleep(for: .seconds(1))
            guard timerActive else { return }
            secondsLeft -= 1
        }
        if timerActive {
            confirm()
        }
    }

    // MARK: - Actions

    private func confirm() {
        timerActive = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        sessionManager.confirmBreak()
        dismiss()
    }

    private func skip() {
        timerActive = false
        sessionManager.skipBreak()
        dismiss()
    }
}

#Preview {
    BreakView()
        .environment(SessionManager())
}
