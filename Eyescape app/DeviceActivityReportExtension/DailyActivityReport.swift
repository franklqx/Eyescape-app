//
//  DailyActivityReport.swift
//  DeviceActivityReportExtension
//
//  Defines the report scene for context "Daily". The main app embeds it via
//  `DeviceActivityReport(.init(rawValue: "Daily"), filter: ...)` in AnalyticsView.
//

import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    static let daily = Self("Daily")
}

struct DailyActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .daily
    let content: (TotalActivityModel) -> DailyActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityModel {
        var total: TimeInterval = 0
        var topApps: [(String, TimeInterval)] = []

        for await activity in data {
            for await segment in activity.activitySegments {
                total += segment.totalActivityDuration
                for await categoryActivity in segment.categories {
                    for await application in categoryActivity.applications {
                        let name = application.application.localizedDisplayName ?? "Unknown"
                        let duration = application.totalActivityDuration
                        topApps.append((name, duration))
                    }
                }
            }
        }

        topApps.sort { $0.1 > $1.1 }
        let trimmed = Array(topApps.prefix(5))

        return TotalActivityModel(
            totalDuration: total,
            topApps: trimmed.map { TotalActivityModel.AppEntry(name: $0.0, duration: $0.1) }
        )
    }
}

struct TotalActivityModel {
    struct AppEntry: Identifiable {
        let id = UUID()
        let name: String
        let duration: TimeInterval
    }
    let totalDuration: TimeInterval
    let topApps: [AppEntry]
}
