/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The entry point for the app's widget (and Live Activity).
*/

import WidgetKit
import SwiftUI

@main
struct AlarmLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        // Live Activity
        AlarmLiveActivity()

        // Home Screen Widgets
        NextAlarmWidget()           // Small - Shows next alarm
        AlarmListWidget()            // Medium - Shows alarm list
        ClockWidget()                // Medium/Large - Shows clock with alarms
        DetailedAlarmListWidget()    // Large - Shows detailed alarm list

        // StandBy Widget
        StandByAlarmWidget()         // ExtraLarge - Nightstand display
    }
}
