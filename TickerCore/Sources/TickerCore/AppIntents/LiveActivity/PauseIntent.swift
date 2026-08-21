//
//  PauseIntent.swift
//  fig
//
//  AppIntent for pausing a countdown alarm
//

import AlarmKit
import AppIntents

/// An intent that pauses a running countdown alarm.
@available(iOS 26.0, *)
public struct PauseIntent: LiveActivityIntent {

    // `static let` rather than `static var`: a mutable static is shared mutable
    // state across the process and is not concurrency-safe.
    public static let title: LocalizedStringResource = "Pause"
    public static let description = IntentDescription("Pause a countdown")

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
            print("⚠️ PauseIntent: ignoring malformed alarmID '\(alarmID)'")
            return .result()
        }

        do {
            try AlarmManager.shared.pause(id: alarmUUID)
            AlarmReactionRecorder.record(.paused, alarmID: alarmUUID)
        } catch {
            print("❌ PauseIntent: failed to pause \(alarmUUID): \(error)")
        }

        return .result()
    }
}
