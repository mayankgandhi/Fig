//
//  TimerControlWidget.swift
//  alarm
//
//  Control Center widget for quick timer control
//  Renamed and moved from alarmControl.swift
//

import AppIntents
import SwiftUI
import WidgetKit

// Note: TimerConfiguration and StartTimerIntent are located
// at fig/AppIntents/ControlWidget/

struct TimerControlWidget: ControlWidget {
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
                            .Subheadline()
                            .foregroundStyle(isRunning ? .white : .secondary)
                            .scaleEffect(isRunning ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isRunning)
                    }

                    // Status text
                    Text(isRunning ? "Running" : "Stopped")
                        .Caption2()
                        .foregroundStyle(isRunning ? .primary : .secondary)
                }
                .containerBackground(for: .widget) {
                    Color.clear
                }
            }
        }
        .displayName("Quick Timer")
        .description("Start or stop a quick timer from Control Center")
    }
}

extension TimerControlWidget {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            TimerControlWidget.Value(isRunning: false, name: configuration.timerName)
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let isRunning = true // Check if the timer is running
            return TimerControlWidget.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}
