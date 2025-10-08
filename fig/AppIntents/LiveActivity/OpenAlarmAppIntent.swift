//
//  OpenAlarmAppIntent.swift
//  fig
//
//  AppIntent for opening the app
//

import AlarmKit
import AppIntents

/// An intent that opens the app and stops the alarm
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// as a custom secondary button action. When triggered, it stops the alarm
/// and opens the main app.
struct OpenAlarmAppIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    static var title: LocalizedStringResource = "Open App"
    static var description = IntentDescription("Opens the Sample app")
    static var openAppWhenRun = true

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}
