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

        let schedule = alarmItem.alarmKitSchedule
        let countdownDuration = alarmItem.alarmKitCountdownDuration

        // An alarm with neither a schedule nor a countdown can never fire, so
        // there is nothing worth handing to AlarmKit. This guard used to be dead
        // code — the function always returned non-nil, which made the
        // `guard let configuration` at every call site unreachable and hid
        // exactly this misconfiguration.
        guard schedule != nil || countdownDuration != nil else {
            print("   ❌ Ticker '\(alarmItem.label)' has neither a schedule nor a countdown")
            return nil
        }

        // Build configuration
        let configuration = AlarmManager.AlarmConfiguration<TickerData>(
            countdownDuration: countdownDuration,
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopIntent(alarmID: alarmID.uuidString),
            secondaryIntent: buildSecondaryIntent(for: alarmItem, occurrenceAlarmID: alarmID),
            sound: sound
        )

        return configuration
    }
    
    public init() { }

    // MARK: - Private Helpers

    /// Builds the alert presentation, avoiding the deprecated `stopButton`.
    ///
    /// In the iOS 26.5 SDK `AlarmPresentation.Alert.stopButton` is marked
    /// `@available(*, deprecated, message: "This property is not used anymore and
    /// will be removed.")`, and iOS 26.1 added an initializer that omits it. The
    /// system draws its own stop affordance.
    private static func makeAlert(
        title: LocalizedStringResource,
        secondaryButton: AlarmButton?,
        secondaryButtonBehavior: AlarmPresentation.Alert.SecondaryButtonBehavior?
    ) -> AlarmPresentation.Alert {
        if #available(iOS 26.1, *) {
            return AlarmPresentation.Alert(
                title: title,
                secondaryButton: secondaryButton,
                secondaryButtonBehavior: secondaryButtonBehavior
            )
        } else {
            return AlarmPresentation.Alert(
                title: title,
                stopButton: .stopButton,
                secondaryButton: secondaryButton,
                secondaryButtonBehavior: secondaryButtonBehavior
            )
        }
    }

    private func buildSound(from alarmItem: Ticker) -> AlertConfiguration.AlertSound {
        guard let soundID = alarmItem.soundName else {
            print("🔊 Using default sound")
            return .default
        }
        // A sound name without a dot used to crash here on `fileComponents[1]`.
        let fileComponents = soundID.components(separatedBy: ".")
        guard fileComponents.count >= 2, !fileComponents[0].isEmpty else {
            print("⚠️ Sound name '\(soundID)' has no file extension - using default sound")
            return .default
        }
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

    /// Internal rather than private: `AlarmManager.AlarmConfiguration` exposes no
    /// readable properties, so the only way to assert that the presentation and
    /// the countdown duration agree on their gate is to build the presentation
    /// directly.
    func buildPresentation(from alarmItem: Ticker) -> AlarmPresentation {
        // A `.countdown` secondary behavior is only valid when there is actually a
        // countdown to restart. Requesting it without one is an invalid
        // configuration that AlarmKit rejects at schedule time.
        var secondaryButtonBehavior = alarmItem.alarmKitSecondaryButtonBehavior
        if secondaryButtonBehavior == .countdown, alarmItem.alarmKitCountdownDuration == nil {
            print("   ⚠️ '\(alarmItem.label)' asks for a Repeat button but has no countdown - dropping it")
            secondaryButtonBehavior = nil
        }

        let secondaryButton: AlarmButton? = switch secondaryButtonBehavior {
            case .countdown: .repeatButton
            case .custom: .openAppButton
            default: nil
        }

        let alertContent = Self.makeAlert(
            title: LocalizedStringResource(stringLiteral: alarmItem.label),
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: secondaryButtonBehavior
        )

        // Gate on the same predicate `alarmKitCountdownDuration` uses. Gating on
        // `countdown != nil` here while the duration gated on `preAlert != nil`
        // produced a countdown presentation with no countdown duration.
        guard alarmItem.hasPreAlertCountdown else {
            // An alarm without a pre-alert countdown only specifies an alert state
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

    private func buildSecondaryIntent(
        for alarmItem: Ticker,
        occurrenceAlarmID: UUID
    ) -> (any LiveActivityIntent)? {
        // Secondary intents call into AlarmManager (`countdown(id:)`, `stop(id:)`),
        // which only knows AlarmKit alarm IDs. Alarms are always scheduled under a
        // freshly generated occurrence UUID, never under `alarmItem.id` (the
        // SwiftData Ticker ID) — passing the Ticker ID here made every secondary
        // button throw, so "Open" left the alarm ringing and "Repeat" did nothing.
        switch alarmItem.presentation.secondaryButtonType {
        case .none:
            return nil
        case .countdown:
            return RepeatIntent(alarmID: occurrenceAlarmID.uuidString)
        case .openApp:
            return OpenAlarmAppIntent(alarmID: occurrenceAlarmID.uuidString)
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
