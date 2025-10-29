//
//  PauseIntent.swift
//  fig
//
//  AppIntent for pausing a countdown alarm
//

import AlarmKit
import AppIntents

/// An intent that pauses a running countdown alarm
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// to allow users to pause an active countdown timer.
@available(iOS 26.0, *)
public struct PauseIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        try AlarmManager.shared.pause(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    public static var title: LocalizedStringResource = "Pause"
    public static var description = IntentDescription("Pause a countdown")

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) {
        self.alarmID = alarmID
    }

    public init() {
        self.alarmID = ""
    }
}
