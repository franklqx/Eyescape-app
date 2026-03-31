//
//  EyescapeWidgetBundle.swift
//  EyescapeWidget
//
//  Eyescape only uses a Live Activity (no home-screen widget).
//

import WidgetKit
import SwiftUI

@main
struct EyescapeWidgetBundle: WidgetBundle {
    var body: some Widget {
        EyescapeWidgetLiveActivity()
    }
}
