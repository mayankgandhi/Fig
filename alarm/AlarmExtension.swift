//
//  AlarmExtension.swift
//  alarm
//
//  Widget extension bundle entry point
//  Aggregates all widgets, Live Activity, and control center widgets
//
//  Renamed from AlarmLiveActivityBundle.swift for better clarity
//

import WidgetKit
import SwiftUI

@main
struct AlarmExtension: WidgetBundle {
    var body: some Widget {
        // Live Activity
        AlarmLiveActivity()

        // Home Screen Widgets
        NextAlarmWidget()           // Small - Shows next alarm
        AlarmListWidget()            // Medium - Shows alarm list
        ClockWidget()                // Medium/Large - Shows clock with alarms
        DetailedAlarmListWidget()    // Large - Shows detailed alarm list

        // Lock Screen / StandBy Widget
        StandByAlarmWidget()         // ExtraLarge - Nightstand display

        // Control Center Widget
        TimerControlWidget()         // Control Center - Quick timer toggle
    }
}
