//
//  AlarmConfigurationBuilder.swift
//  fig
//
//  Handles building AlarmKit configuration objects from AlarmItem models
//

import Foundation
import SwiftUI
import AlarmKit
import AppIntents

// MARK: - AlarmConfigurationBuilder Protocol

protocol AlarmConfigurationBuilderProtocol {
    func buildConfiguration(from alarmItem: AlarmItem) -> AlarmManager.AlarmConfiguration<TickerData>?
}

// MARK: - AlarmConfigurationBuilder Implementation

struct AlarmConfigurationBuilder: AlarmConfigurationBuilderProtocol {

    func buildConfiguration(from alarmItem: AlarmItem) -> AlarmManager.AlarmConfiguration<TickerData>? {
        // Build attributes
        let attributes = AlarmAttributes(
            presentation: buildPresentation(from: alarmItem),
            metadata: alarmItem.tickerData ?? TickerData(),
            tintColor: Color.accentColor
        )

        // Build configuration
        let configuration = AlarmManager.AlarmConfiguration<TickerData>(
            countdownDuration: alarmItem.alarmKitCountdownDuration,
            schedule: alarmItem.alarmKitSchedule,
            attributes: attributes,
            stopIntent: StopIntent(alarmID: alarmItem.id.uuidString),
            secondaryIntent: buildSecondaryIntent(for: alarmItem)
        )

        return configuration
    }

    // MARK: - Private Helpers

    private func buildPresentation(from alarmItem: AlarmItem) -> AlarmPresentation {
        let secondaryButtonBehavior = alarmItem.alarmKitSecondaryButtonBehavior
        let secondaryButton: AlarmButton? = switch secondaryButtonBehavior {
            case .countdown: .repeatButton
            case .custom: .openAppButton
            default: nil
        }

        let alertContent = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: alarmItem.label),
            stopButton: .stopButton,
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: secondaryButtonBehavior
        )

        guard alarmItem.countdown != nil else {
            // An alarm without a countdown only specifies an alert state
            return AlarmPresentation(alert: alertContent)
        }

        // With countdown enabled, a presentation appears for both countdown and paused state
        let countdownContent = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: alarmItem.label),
            pauseButton: .pauseButton
        )

        let pausedContent = AlarmPresentation.Paused(
            title: "Paused",
            resumeButton: .resumeButton
        )

        return AlarmPresentation(alert: alertContent, countdown: countdownContent, paused: pausedContent)
    }

    private func buildSecondaryIntent(for alarmItem: AlarmItem) -> (any LiveActivityIntent)? {
        switch alarmItem.presentation.secondaryButtonType {
        case .none:
            return nil
        case .countdown:
            return RepeatIntent(alarmID: alarmItem.id.uuidString)
        case .openApp:
            return OpenAlarmAppIntent(alarmID: alarmItem.id.uuidString)
        }
    }
}

// MARK: - AlarmButton Extensions

extension AlarmButton {
    static var openAppButton: Self {
        AlarmButton(text: "Open", textColor: .black, systemImageName: "swift")
    }

    static var pauseButton: Self {
        AlarmButton(text: "Pause", textColor: .black, systemImageName: "pause.fill")
    }

    static var resumeButton: Self {
        AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
    }

    static var repeatButton: Self {
        AlarmButton(text: "Repeat", textColor: .black, systemImageName: "repeat.circle")
    }

    static var stopButton: Self {
        AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle")
    }
}
