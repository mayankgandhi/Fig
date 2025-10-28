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
struct RepeatIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.countdown(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    static var title: LocalizedStringResource = "Repeat"
    static var description = IntentDescription("Repeat a countdown")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}
