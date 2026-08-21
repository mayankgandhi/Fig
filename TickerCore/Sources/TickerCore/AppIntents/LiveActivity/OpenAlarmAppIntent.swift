//
//  OpenAlarmAppIntent.swift
//  fig
//
//  AppIntent for opening the app
//

import AlarmKit
import AppIntents

/// An intent that stops the alarm and opens the app.
///
/// Installed as the secondary action when `TickerPresentation.secondaryButtonType`
/// is `.openApp` — which is the default, so this runs for most alarms.
///
/// It must be handed the AlarmKit *occurrence* ID. It previously received the
/// SwiftData Ticker ID, so `stop(id:)` threw on every invocation: the app opened
/// (`openAppWhenRun`) while the alarm carried on ringing.
@available(iOS 26.0, *)
public struct OpenAlarmAppIntent: LiveActivityIntent {

    public static let title: LocalizedStringResource = "Open App"
    public static let description = IntentDescription("Opens Ticker and stops the alarm")
    public static let openAppWhenRun = true

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init() {
        self.alarmID = ""
    }

    public init(alarmID: String) {
        self.alarmID = alarmID
    }

    public func perform() throws -> some IntentResult {
        guard let alarmUUID = UUID(uuidString: alarmID) else {
            print("⚠️ OpenAlarmAppIntent: ignoring malformed alarmID '\(alarmID)'")
            return .result()
        }

        print("🛑 OpenAlarmAppIntent.perform() for alarm \(alarmUUID)")

        do {
            try AlarmManager.shared.stop(id: alarmUUID)
            print("   ✅ Stopped alarm \(alarmUUID)")
            AlarmReactionRecorder.record(.openedApp, alarmID: alarmUUID)
        } catch {
            // Still open the app — that is the half of this intent the user asked
            // for — but do not pretend the alarm was stopped.
            print("   ❌ Failed to stop alarm \(alarmUUID): \(error)")
            AlarmReactionRecorder.record(.stopFailed, alarmID: alarmUUID)
        }

        return .result()
    }
}
