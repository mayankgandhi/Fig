//
//  ResumeIntent.swift
//  fig
//
//  AppIntent for resuming a paused countdown
//

import AlarmKit
import AppIntents

/// An intent that resumes a paused countdown alarm.
@available(iOS 26.0, *)
public struct ResumeIntent: LiveActivityIntent {

    public static let title: LocalizedStringResource = "Resume"
    public static let description = IntentDescription("Resume a countdown")

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
            print("⚠️ ResumeIntent: ignoring malformed alarmID '\(alarmID)'")
            return .result()
        }

        do {
            try AlarmManager.shared.resume(id: alarmUUID)
            AlarmReactionRecorder.record(.resumed, alarmID: alarmUUID)
        } catch {
            print("❌ ResumeIntent: failed to resume \(alarmUUID): \(error)")
        }

        return .result()
    }
}
