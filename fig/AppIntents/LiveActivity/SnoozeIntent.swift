//
//  SnoozeIntent.swift
//  fig
//
//  AppIntent for snoozing alarms with customizable duration
//

import AlarmKit
import AppIntents

/// An intent that snoozes an alarm for a specified duration
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// to provide snooze functionality with customizable duration options.
struct SnoozeIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.snooze(id: UUID(uuidString: alarmID)!, duration: Duration.seconds(snoozeDuration))
        return .result()
    }

    static var title: LocalizedStringResource = "Snooze"
    static var description = IntentDescription("Snoozes the alarm for the specified duration")
    static var openAppWhenRun = false

    @Parameter(title: "alarmID")
    var alarmID: String
    
    @Parameter(title: "snoozeDuration", default: 300) // Default 5 minutes
    var snoozeDuration: TimeInterval

    init(alarmID: String, snoozeDuration: TimeInterval = 300) {
        self.alarmID = alarmID
        self.snoozeDuration = snoozeDuration
    }

    init() {
        self.alarmID = ""
        self.snoozeDuration = 300
    }
}
