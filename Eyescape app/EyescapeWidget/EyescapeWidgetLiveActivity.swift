//
//  EyescapeWidgetLiveActivity.swift
//  EyescapeWidget
//
//  Live Activity UI for Eyescape.
//  Three states: work (amber timer dot), alerting (break prompt), paused.
//

import ActivityKit
import WidgetKit
import SwiftUI

// EyescapeAttributes is defined in EyescapeAttributes.swift, which is added
// to BOTH the main app target and this widget extension target.

struct EyescapeWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EyescapeAttributes.self) { context in
            // MARK: Lock Screen / Banner
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Expanded (long-press)
                DynamicIslandExpandedRegion(.leading) {
                    CatIconView(colorRaw: context.state.petColorRaw, size: 32)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isAlerting {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                        .padding(.bottom, 4)
                }
            } compactLeading: {
                // MARK: Compact Leading — pixel-cat head
                CatIconView(colorRaw: context.state.petColorRaw, size: 20)

            } compactTrailing: {
                // MARK: Compact Trailing — countdown or break alert
                CompactTrailingView(context: context)

            } minimal: {
                // MARK: Minimal — cat head only
                CatIconView(colorRaw: context.state.petColorRaw, size: 16)
            }
            .widgetURL(URL(string: "eyescape://open"))
            .keylineTint(context.state.isAlerting ? .orange : .accentColor)
        }
    }
}

// MARK: - Cat Icon View

/// Loads the pixel-cat PNG icon from GitHub raw, with amber pawprint fallback.
private struct CatIconView: View {
    let colorRaw: String
    let size: CGFloat

    private var iconURL: URL? {
        URL(string: "https://raw.githubusercontent.com/exsec-dev/pixel-cat/main/src/icon/cat/\(colorRaw)_icon.png")
    }

    var body: some View {
        AsyncImage(url: iconURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .interpolation(.none)   // keep pixel art crisp
                    .scaledToFit()
            default:
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(Color(red: 0.91, green: 0.58, blue: 0.29))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<EyescapeAttributes>

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(context.state.isAlerting ? Color.orange : Color(red: 0.91, green: 0.58, blue: 0.29))
                .frame(width: 20, height: 20)
                .shadow(color: Color(red: 0.91, green: 0.58, blue: 0.29).opacity(0.7), radius: context.state.isAlerting ? 10 : 6)

            VStack(alignment: .leading, spacing: 2) {
                if context.state.isAlerting {
                    Text("Time for a break!")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("Look 20 ft away for 20 seconds.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let target = context.state.targetDate {
                    Text("Next break in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(target, style: .timer)
                        .font(.headline)
                        .monospacedDigit()
                }
            }

            Spacer()

            if context.state.isAlerting {
                // Deep-link buttons — open app or snooze
                VStack(spacing: 6) {
                    Link(destination: URL(string: "eyescape://break")!) {
                        Text("Break")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.orange)
                            .clipShape(Capsule())
                    }
                    Link(destination: URL(string: "eyescape://snooze")!) {
                        Text("+20 min")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Expanded Bottom View

private struct ExpandedBottomView: View {
    let context: ActivityViewContext<EyescapeAttributes>

    var body: some View {
        if context.state.isAlerting {
            HStack(spacing: 12) {
                Link(destination: URL(string: "eyescape://break")!) {
                    Label("Take Break", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.orange)
                        .clipShape(Capsule())
                }
                Link(destination: URL(string: "eyescape://snooze")!) {
                    Label("+20 min", systemImage: "clock.arrow.circlepath")
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        } else if let target = context.state.targetDate {
            HStack {
                Text("Next break:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(target, style: .timer)
                    .font(.subheadline.monospacedDigit())
            }
        }
    }
}

// MARK: - Compact Trailing View

private struct CompactTrailingView: View {
    let context: ActivityViewContext<EyescapeAttributes>

    var body: some View {
        if context.state.isAlerting {
            Text("Break!")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
        } else if let target = context.state.targetDate {
            Text(target, style: .timer)
                .font(.caption2.monospacedDigit())
                .frame(minWidth: 36)
        }
    }
}

// MARK: - Previews

private let _attrs = EyescapeAttributes(sessionId: UUID(), intervalMinutes: 20)

#Preview("Compact — Work", as: .dynamicIsland(.compact), using: _attrs) {
    EyescapeWidgetLiveActivity()
} contentStates: {
    EyescapeAttributes.ContentState(
        targetDate: .now.addingTimeInterval(14 * 60),
        isPaused: false, isAlerting: false, diAlertSize: .medium
    )
}

#Preview("Compact — Break!", as: .dynamicIsland(.compact), using: _attrs) {
    EyescapeWidgetLiveActivity()
} contentStates: {
    EyescapeAttributes.ContentState(
        targetDate: nil,
        isPaused: false, isAlerting: true, diAlertSize: .medium
    )
}

#Preview("Compact — Paused", as: .dynamicIsland(.compact), using: _attrs) {
    EyescapeWidgetLiveActivity()
} contentStates: {
    EyescapeAttributes.ContentState(
        targetDate: nil,
        isPaused: true, isAlerting: false, diAlertSize: .medium
    )
}

#Preview("Expanded — Work", as: .dynamicIsland(.expanded), using: _attrs) {
    EyescapeWidgetLiveActivity()
} contentStates: {
    EyescapeAttributes.ContentState(
        targetDate: .now.addingTimeInterval(14 * 60),
        isPaused: false, isAlerting: false, diAlertSize: .medium
    )
}

#Preview("Expanded — Break!", as: .dynamicIsland(.expanded), using: _attrs) {
    EyescapeWidgetLiveActivity()
} contentStates: {
    EyescapeAttributes.ContentState(
        targetDate: nil,
        isPaused: false, isAlerting: true, diAlertSize: .medium
    )
}

#Preview("Lock Screen — Work", as: .content, using: _attrs) {
    EyescapeWidgetLiveActivity()
} contentStates: {
    EyescapeAttributes.ContentState(
        targetDate: .now.addingTimeInterval(14 * 60),
        isPaused: false, isAlerting: false, diAlertSize: .medium
    )
}

#Preview("Lock Screen — Break!", as: .content, using: _attrs) {
    EyescapeWidgetLiveActivity()
} contentStates: {
    EyescapeAttributes.ContentState(
        targetDate: nil,
        isPaused: false, isAlerting: true, diAlertSize: .medium
    )
}
