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
                "Quick Timer",
                isOn: value.isRunning,
                action: StartTimerIntent(value.name)
            ) { isRunning in
                VStack(spacing: 4) {
                    ZStack {
                        // Background circle with gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isRunning ? [
                                        Color.orange,
                                        Color.red
                                    ] : [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .shadow(
                                color: isRunning ? Color.orange.opacity(0.3) : Color.clear,
                                radius: isRunning ? 8 : 0,
                                x: 0,
                                y: 4
                            )
                        
                        // Icon
                        Image(systemName: isRunning ? "timer" : "timer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isRunning ? .white : .secondary)
                            .scaleEffect(isRunning ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isRunning)
                    }
                    
                    // Status text
                    Text(isRunning ? "Running" : "Stopped")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isRunning ? .primary : .secondary)
                }
            }
        }
        .displayName("Quick Timer")
        .description("Start or stop a quick timer from Control Center")
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
