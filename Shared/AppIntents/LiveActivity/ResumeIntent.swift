//
//  ResumeIntent.swift
//  fig
//
//  AppIntent for resuming a paused countdown
//

import AlarmKit
import AppIntents

/// An intent that resumes a paused countdown alarm
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// to allow users to resume a countdown timer that was previously paused.
struct ResumeIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.resume(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    static var title: LocalizedStringResource = "Resume"
    static var description = IntentDescription("Resume a countdown")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}
