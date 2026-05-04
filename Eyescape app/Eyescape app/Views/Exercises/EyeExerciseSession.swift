import SwiftUI
import SwiftData
import UIKit

/// Full-screen sheet that walks the user through the steps of an `EyeExercise`.
///
/// On full completion the session writes one `EyeExerciseRecord` so HomeView's
/// "exercises today" counter and the aggregator can pick it up. Skipping or
/// closing early writes nothing.
struct EyeExerciseSession: View {
    let exercise: EyeExercise
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var stepIndex: Int = 0
    @State private var secondsLeft: Int = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var timerActive: Bool = true

    private var currentStep: ExerciseStep {
        exercise.steps[stepIndex]
    }

    private var totalElapsedFraction: Double {
        let completedDuration = exercise.steps.prefix(stepIndex).reduce(0) { $0 + $1.duration }
        let currentElapsed = currentStep.duration - Double(secondsLeft)
        return min(1.0, max(0.0, (completedDuration + currentElapsed) / exercise.totalDuration))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                pulseDot

                Spacer().frame(height: 24)

                Text(currentStep.name)
                    .font(.system(size: 24, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(Color.textPrimary)

                Spacer().frame(height: 8)

                Text(currentStep.instruction)
                    .appText(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 40)

                Text(String(format: "00:%02d", secondsLeft))
                    .appText(.countdown)
                    .foregroundStyle(Color.accentAmber)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: secondsLeft)
                    .accessibilityLabel("\(secondsLeft) seconds remaining")

                Spacer().frame(height: 44)

                Button { skipCurrentStep() } label: {
                    Text(stepIndex < exercise.steps.count - 1 ? "Skip step" : "Finish")
                        .appText(.body)
                        .foregroundStyle(Color.textSecondary)
                        .frame(minHeight: 44)
                }

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            secondsLeft = Int(currentStep.duration)
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
        .task { await runCountdown() }
    }

    // MARK: - Sub-views

    private var topBar: some View {
        HStack {
            Button { abort() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.appSurface, in: Circle())
                    .overlay { Circle().stroke(Color.hairline, lineWidth: 1) }
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 6) {
                Text(exercise.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(Color.textPrimary)
                ProgressView(value: totalElapsedFraction)
                    .tint(Color.accentAmber)
                    .frame(width: 140)
            }

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, 8)
        .padding(.horizontal, 22)
    }

    private var pulseDot: some View {
        Circle()
            .fill(Color.accentAmber)
            .frame(width: 56, height: 56)
            .shadow(color: Color.accentAmber.opacity(0.6), radius: 22)
            .shadow(color: Color.accentAmber.opacity(0.25), radius: 60)
            .scaleEffect(pulseScale)
            .overlay(
                Image(systemName: currentStep.symbolName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.appBackground)
            )
    }

    // MARK: - Timer & Flow

    private func runCountdown() async {
        while timerActive {
            try? await Task.sleep(for: .seconds(1))
            guard timerActive else { return }
            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                advanceStep()
            }
        }
    }

    private func advanceStep() {
        if stepIndex < exercise.steps.count - 1 {
            stepIndex += 1
            secondsLeft = Int(currentStep.duration)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            complete()
        }
    }

    private func skipCurrentStep() {
        advanceStep()
    }

    private func complete() {
        timerActive = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let record = EyeExerciseRecord(
            completedAt: .now,
            durationSeconds: Int(exercise.totalDuration)
        )
        modelContext.insert(record)
        try? modelContext.save()
        dismiss()
    }

    private func abort() {
        timerActive = false
        dismiss()
    }
}

#Preview {
    let schema = Schema([
        Session.self, BreakRecord.self, UserSettings.self,
        PetState.self, EyeExerciseRecord.self, PickupSession.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    return EyeExerciseSession(exercise: .quickRest)
        .modelContainer(container)
}
