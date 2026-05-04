//
//  EyescapeReportExtension.swift
//  DeviceActivityReportExtension
//
//  @main entry point. Apple-required boilerplate. The interesting code is in
//  DailyActivityReport.swift and DailyActivityView.swift.
//

import DeviceActivity
import SwiftUI

@main
struct EyescapeReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        DailyActivityReport { totalActivity in
            DailyActivityView(totalActivity: totalActivity)
        }
    }
}
