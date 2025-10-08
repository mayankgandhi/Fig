//
//  alarmControl.swift
//  alarm
//
//  Created by Mayank Gandhi on 05/10/25.
//

import AppIntents
import SwiftUI
import WidgetKit

// Note: TimerConfiguration and StartTimerIntent are now located
// at fig/AppIntents/ControlWidget/

struct alarmControl: ControlWidget {
    static let kind: String = "m.fig.alarm"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value.isRunning,
                action: StartTimerIntent(value.name)
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("A an example control that runs a timer.")
    }
}

extension alarmControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            alarmControl.Value(isRunning: false, name: configuration.timerName)
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let isRunning = true // Check if the timer is running
            return alarmControl.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}
