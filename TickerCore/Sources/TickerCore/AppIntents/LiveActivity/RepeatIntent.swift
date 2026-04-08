//
//  RepeatIntent.swift
//  fig
//
//  AppIntent for repeating a countdown alarm
//

import AlarmKit
import AppIntents

/// An intent that repeats a countdown alarm
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// to allow users to restart the countdown timer from the beginning.
@available(iOS 26.0, *)
public struct RepeatIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        guard let alarmUUID = UUID(uuidString: alarmID) else {
            print("⚠️ [RepeatIntent] Invalid alarmID string: '\(alarmID)'")
            throw IntentError.invalidAlarmID
        }
        try AlarmManager.shared.countdown(id: alarmUUID)
        return .result()
    }

    public static var title: LocalizedStringResource = "Repeat"
    public static var description = IntentDescription("Repeat a countdown")

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) {
        self.alarmID = alarmID
    }

    public init() {
        self.alarmID = ""
    }
}
