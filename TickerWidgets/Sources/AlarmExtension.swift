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
import Gate
import TickerCore

@main
struct AlarmExtension: WidgetBundle {
    init() {
        // Configure subscription service for widget extension
        WidgetSubscriptionConfig.configure()

        // Initialize SubscriptionService asynchronously
        Task {
            try? await SubscriptionService.shared.initialize()
            SubscriptionAccessStore.setIsSubscribed(SubscriptionService.shared.isSubscribed)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    var body: some Widget {
        // Live Activity
        AlarmLiveActivity()

        // Home Screen Widgets (4 total)
        NextAlarmWidget()           // Small - Next upcoming alarm only
        AlarmListWidget()            // Medium - List of upcoming alarms (up to 2)
        ClockWidget()                // Large - Clock face with alarm indicators and detailed list (up to 4)
        DetailedAlarmListWidget()    // Large - Detailed alarm list only (up to 6)

        // Lock Screen / StandBy Widget
        StandByAlarmWidget()         // ExtraLarge - Nightstand display for lock screen
    }
}
