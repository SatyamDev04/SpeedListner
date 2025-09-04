//
//  SpeedListerBundle.swift
//  SpeedLister
//
//  Created by YATIN  KALRA on 26/08/25.
//

import WidgetKit
import SwiftUI

@main
struct SpeedListerBundle: WidgetBundle {
    var body: some Widget {
        SpeedLister()
        SpeedListerControl()
        SpeedListerLiveActivity()
    }
}
