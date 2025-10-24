//
//  AlarmControls.swift
//  alarm
//
//  Control buttons for Live Activity
//  Displays pause/resume and stop buttons based on alarm state
//

import AlarmKit
import SwiftUI

/// Control buttons for Live Activity alarm management
struct AlarmControls: View {
    var presentation: AlarmPresentation
    var state: AlarmPresentationState

    var body: some View {
        HStack(spacing: 4) {
            switch state.mode {
            case .countdown:
                ButtonView(config: presentation.countdown?.pauseButton, intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: .orange)
            case .paused:
                ButtonView(config: presentation.paused?.resumeButton, intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: .orange)
            default:
                EmptyView()
            }

            ButtonView(config: presentation.alert.stopButton, intent: StopIntent(alarmID: state.alarmID.uuidString), tint: .red)
        }
    }
}
