//
//  AlarmControls.swift
//  alarm
//
//  Control buttons for Live Activity
//  Displays pause/resume, snooze, and stop buttons based on alarm state
//

import AlarmKit
import SwiftUI
import TickerCore

/// Control buttons for Live Activity alarm management
struct AlarmControls: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var presentation: AlarmPresentation
    var state: AlarmPresentationState
    
    var body: some View {
        HStack(spacing: TickerSpacing.xs) {
            switch state.mode {
                case .countdown:
                    ButtonView(config: presentation.countdown?.pauseButton, intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: TickerColor.paused)
                  
                case .paused:
                    ButtonView(config: presentation.paused?.resumeButton, intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: TickerColor.running)
                    
                default:
                    EmptyView()
            }
            
            ButtonView(config: presentation.alert.stopButton, intent: StopIntent(alarmID: state.alarmID.uuidString), tint: TickerColor.danger)
        }
    }
}
