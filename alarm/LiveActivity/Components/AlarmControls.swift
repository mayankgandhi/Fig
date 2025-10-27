//
//  AlarmControls.swift
//  alarm
//
//  Control buttons for Live Activity
//  Displays pause/resume, snooze, and stop buttons based on alarm state
//

import AlarmKit
import SwiftUI

/// Control buttons for Live Activity alarm management
struct AlarmControls: View {
    var presentation: AlarmPresentation
    var state: AlarmPresentationState

    var body: some View {
        HStack(spacing: TickerSpacing.xs) {
            switch state.mode {
            case .countdown:
                ButtonView(config: presentation.countdown?.pauseButton, intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: TickerColor.paused)
                
                // Snooze button for countdown
                ButtonView(config: AlarmButton(systemImageName: "moon.fill", text: "Snooze"), intent: SnoozeIntent(alarmID: state.alarmID.uuidString), tint: TickerColor.warning)
                
            case .paused:
                ButtonView(config: presentation.paused?.resumeButton, intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: TickerColor.running)
                
                // Snooze button for paused state
                ButtonView(config: AlarmButton(systemImageName: "moon.fill", text: "Snooze"), intent: SnoozeIntent(alarmID: state.alarmID.uuidString), tint: TickerColor.warning)
                
            default:
                EmptyView()
            }

            ButtonView(config: presentation.alert.stopButton, intent: StopIntent(alarmID: state.alarmID.uuidString), tint: TickerColor.danger)
        }
    }
}
