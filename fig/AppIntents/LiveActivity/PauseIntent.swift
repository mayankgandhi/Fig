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
struct PauseIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.pause(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    static var title: LocalizedStringResource = "Pause"
    static var description = IntentDescription("Pause a countdown")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}
