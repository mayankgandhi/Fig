//
//  AlarmConfigurationBuilder.swift
//  fig
//
//  Handles building AlarmKit configuration objects from Ticker models
//

import Foundation
import SwiftUI
import AlarmKit
import AppIntents
import ActivityKit

// MARK: - AlarmConfigurationBuilder Protocol

protocol AlarmConfigurationBuilderProtocol {
    func buildConfiguration(from alarmItem: Ticker, occurrenceAlarmID: UUID?) -> AlarmManager.AlarmConfiguration<TickerData>?
}

// MARK: - AlarmConfigurationBuilder Implementation

struct AlarmConfigurationBuilder: AlarmConfigurationBuilderProtocol {

    func buildConfiguration(from alarmItem: Ticker, occurrenceAlarmID: UUID?) -> AlarmManager.AlarmConfiguration<TickerData>? {
        // Use the specific occurrence ID if provided, otherwise fall back to the ticker's main ID
        let alarmID = occurrenceAlarmID ?? alarmItem.id
        
        // Build attributes
        let attributes = AlarmAttributes(
            presentation: buildPresentation(from: alarmItem),
            metadata: alarmItem.tickerData ?? TickerData(),
            tintColor: Color.accentColor
        )

        // Build sound configuration
        let sound = buildSound(from: alarmItem)

        // Build configuration
        let configuration = AlarmManager.AlarmConfiguration<TickerData>(
            countdownDuration: alarmItem.alarmKitCountdownDuration,
            schedule: alarmItem.alarmKitSchedule,
            attributes: attributes,
            stopIntent: StopIntent(alarmID: alarmID.uuidString),
            secondaryIntent: buildSecondaryIntent(for: alarmItem),
            sound: sound
        )

        return configuration
    }

    // MARK: - Private Helpers

    private func buildSound(from alarmItem: Ticker) -> AlertConfiguration.AlertSound {
        guard let soundID = alarmItem.soundName else {
            print("🔊 Using default sound")
            return .default
        }

        // Map sound ID to actual filename
        let soundMap: [String: String] = [
            "classic_digital_alarm": "classic_digital_alarm",
            "casino_jackpot": "mixkit-casino-jackpot-alarm-and-coins-1991",
            "happy_countdown": "mixkit-children-happy-countdown-923",
            "marimba_ringtone": "mixkit-marimba-ringtone-1359",
            "retro_game_alarm": "mixkit-retro-game-emergency-alarm-1000",
            "tick_tock_clock": "mixkit-tick-tock-clock-timer-1045"
        ]

        let fileName = soundMap[soundID] ?? soundID

        // Verify the sound file exists in the bundle before using it
        let extensions = ["wav", "caf", "mp3", "m4a"]
        var foundURL: URL?

        for ext in extensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                foundURL = url
                print("🔊 Using custom sound: \(fileName).\(ext) (found at \(url.path))")
                break
            }
        }

        if foundURL != nil {
            // Sound file exists in bundle, use it
            return .named(fileName)
        } else {
            // Sound file not found, log and fall back to default
            print("⚠️ Custom sound '\(fileName)' not found in bundle with extensions: \(extensions.joined(separator: ", "))")
            print("⚠️ Falling back to default sound")
            return .default
        }
    }

    private func buildPresentation(from alarmItem: Ticker) -> AlarmPresentation {
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

    private func buildSecondaryIntent(for alarmItem: Ticker) -> (any LiveActivityIntent)? {
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
