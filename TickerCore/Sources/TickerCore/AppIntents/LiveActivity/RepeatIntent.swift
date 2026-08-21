//
//  RepeatIntent.swift
//  fig
//
//  AppIntent for repeating a countdown alarm
//

import AlarmKit
import AppIntents

/// An intent that restarts an alarm's countdown — the snooze action.
///
/// Requires the AlarmKit *occurrence* ID. It previously received the SwiftData
/// Ticker ID from `AlarmConfigurationBuilder`, so `countdown(id:)` threw and the
/// Repeat button silently did nothing.
@available(iOS 26.0, *)
public struct RepeatIntent: LiveActivityIntent {

    public static let title: LocalizedStringResource = "Repeat"
    public static let description = IntentDescription("Repeat a countdown")

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
            print("⚠️ RepeatIntent: ignoring malformed alarmID '\(alarmID)'")
            return .result()
        }

        do {
            try AlarmManager.shared.countdown(id: alarmUUID)
            AlarmReactionRecorder.record(.snoozed, alarmID: alarmUUID)
        } catch {
            print("❌ RepeatIntent: failed to restart countdown \(alarmUUID): \(error)")
        }

        return .result()
    }
}
