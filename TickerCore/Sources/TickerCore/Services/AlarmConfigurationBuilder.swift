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

public protocol AlarmConfigurationBuilderProtocol {
    func buildConfiguration(from alarmItem: Ticker, occurrenceAlarmID: UUID) -> AlarmManager.AlarmConfiguration<TickerData>?
}

// MARK: - AlarmConfigurationBuilder Implementation

public struct AlarmConfigurationBuilder: AlarmConfigurationBuilderProtocol {

    public func buildConfiguration(from alarmItem: Ticker, occurrenceAlarmID: UUID) -> AlarmManager.AlarmConfiguration<TickerData>? {
        // Use the specific occurrence ID if provided, otherwise fall back to the ticker's main ID
        let alarmID = occurrenceAlarmID
        print("🔧 AlarmConfigurationBuilder: Building configuration")
        print("   → Main ticker ID: \(alarmItem.id)")
        print("   → Occurrence alarm ID: \(occurrenceAlarmID.uuidString)")
        print("   → Final alarm ID for StopIntent: \(alarmID)")
        
        // Build attributes
        let attributes = AlarmAttributes(
            presentation: buildPresentation(from: alarmItem),
            metadata: alarmItem.tickerData ?? TickerData(),
            tintColor: Color(
                hex: alarmItem.tickerData?.colorHex ?? "#F97330"
            ) ?? TickerColor.primary
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
    
    public init() { }

    // MARK: - Private Helpers

    private func buildSound(from alarmItem: Ticker) -> AlertConfiguration.AlertSound {
        guard let soundID = alarmItem.soundName else {
            print("🔊 Using default sound")
            return .default
        }
        let fileComponents = soundID.components(separatedBy: ".")
        let soundFileName = fileComponents[0]
        let soundsFileExtension = fileComponents[1]
        
        if let url = Bundle.main.url(forResource: soundFileName, withExtension: soundsFileExtension) {
            print("🔊 Using custom sound: \(soundFileName).\(soundsFileExtension) (found at \(url.path))")
            return .named(soundID)
            
        } else {
            // Sound file not found, log and fall back to default
            print("⚠️ Custom sound '\(soundID)' not found in bundle")
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
        // Note: Secondary intents should use the main ticker ID since they operate on the ticker level
        // (e.g., repeating the countdown, opening the app) rather than stopping a specific alarm instance
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
