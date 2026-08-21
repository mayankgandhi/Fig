//
//  AlarmControls.swift
//  alarm
//
//  Control buttons for Live Activity
//

import AlarmKit
import SwiftUI
import TickerCore

/// Control buttons for Live Activity alarm management.
struct AlarmControls: View {

    var presentation: AlarmPresentation
    var state: AlarmPresentationState

    private var alarmIDString: String { state.alarmID.uuidString }

    var body: some View {
        HStack(spacing: TickerSpacing.sm) {
            switch state.mode {
            case .countdown:
                ButtonView(
                    config: presentation.countdown?.pauseButton,
                    intent: PauseIntent(alarmID: alarmIDString),
                    tint: TickerColor.paused
                )
                stopButton(prominent: false)

            case .paused:
                ButtonView(
                    config: presentation.paused?.resumeButton,
                    intent: ResumeIntent(alarmID: alarmIDString),
                    tint: TickerColor.running
                )
                stopButton(prominent: false)

            case .alert:
                // The alerting state previously fell into `default: EmptyView()`
                // and then appended Stop, so snooze was unreachable from every
                // Live Activity surface — `presentation.alert.secondaryButton`
                // was never read anywhere in the widget target.
                alertControls

            @unknown default:
                stopButton(prominent: false)
            }
        }
    }

    @ViewBuilder
    private var alertControls: some View {
        // Snooze leads and is the larger target. A mis-tap on Stop at 7am is
        // unrecoverable; a mis-tap on Snooze costs nine minutes.
        if let secondary = presentation.alert.secondaryButton {
            switch presentation.alert.secondaryButtonBehavior {
            case .countdown:
                ButtonView(
                    config: secondary,
                    intent: RepeatIntent(alarmID: alarmIDString),
                    tint: TickerColor.snooze,
                    prominent: true
                )
            case .custom:
                ButtonView(
                    config: secondary,
                    intent: OpenAlarmAppIntent(alarmID: alarmIDString),
                    tint: TickerColor.snooze,
                    prominent: true
                )
            default:
                EmptyView()
            }
        }

        stopButton(prominent: true)
    }

    @ViewBuilder
    private func stopButton(prominent: Bool) -> some View {
        ButtonView(
            config: Self.stopConfig,
            intent: StopIntent(alarmID: alarmIDString),
            tint: TickerColor.stop,
            prominent: prominent
        )
    }

    /// Defined locally rather than read from `presentation.alert.stopButton`,
    /// which is deprecated in the iOS 26.5 SDK ("This property is not used
    /// anymore and will be removed") and absent from the iOS 26.1 initializer.
    private static let stopConfig = AlarmButton(
        text: "Stop",
        textColor: .white,
        systemImageName: "stop.fill"
    )
}
