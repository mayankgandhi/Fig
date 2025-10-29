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
@available(iOS 26.0, *)
public struct ResumeIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        try AlarmManager.shared.resume(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    public static var title: LocalizedStringResource = "Resume"
    public static var description = IntentDescription("Resume a countdown")

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) {
        self.alarmID = alarmID
    }

    public init() {
        self.alarmID = ""
    }
}
