//
//  DailyActivityView.swift
//  DeviceActivityReportExtension
//
//  Renders the Daily report. Note that DeviceActivityReport extensions run
//  in a sandboxed process with a restricted SwiftUI subset — no animations,
//  no async images, no SwiftData. Keep it static and simple.
//

import SwiftUI

struct DailyActivityView: View {
    let totalActivity: TotalActivityModel

    private var totalLabel: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: totalActivity.totalDuration) ?? "0m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY · SCREEN TIME")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.91, green: 0.58, blue: 0.29))
                    .tracking(1.2)
                Text(totalLabel)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.primary)
            }

            if !totalActivity.topApps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOP APPS")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .tracking(1.0)

                    ForEach(totalActivity.topApps) { app in
                        HStack {
                            Text(app.name)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Spacer()
                            Text(durationLabel(app.duration))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func durationLabel(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: seconds) ?? "0m"
    }
}
