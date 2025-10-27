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
        HStack(spacing: TickerSpacing.xxs) {
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

// MARK: - Previews

#Preview("Alarm Controls - Countdown Mode") {
    AlarmControls(
        presentation: AlarmPresentation(
            countdown: AlarmPresentationState.CountdownPresentation(
                title: "Morning Run",
                pauseButton: AlarmButton(systemImageName: "pause.fill", text: "Pause")
            ),
            paused: nil,
            alert: AlarmPresentationState.AlertPresentation(
                stopButton: AlarmButton(systemImageName: "stop.fill", text: "Stop")
            )
        ),
        state: AlarmPresentationState(
            mode: .countdown(AlarmPresentationState.Countdown(fireDate: Date().addingTimeInterval(3600))),
            alarmID: UUID()
        )
    )
    .padding()
}

#Preview("Alarm Controls - Paused Mode") {
    AlarmControls(
        presentation: AlarmPresentation(
            countdown: nil,
            paused: AlarmPresentationState.PausedPresentation(
                title: "Morning Run",
                resumeButton: AlarmButton(systemImageName: "play.fill", text: "Resume")
            ),
            alert: AlarmPresentationState.AlertPresentation(
                stopButton: AlarmButton(systemImageName: "stop.fill", text: "Stop")
            )
        ),
        state: AlarmPresentationState(
            mode: .paused(AlarmPresentationState.Paused(
                totalCountdownDuration: 3600,
                previouslyElapsedDuration: 1800
            )),
            alarmID: UUID()
        )
    )
    .padding()
}
