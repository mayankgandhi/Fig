//
//  StopIntent.swift
//  fig
//
//  AppIntent for stopping an alarm
//

import AlarmKit
import AppIntents

/// An intent that stops an active alarm
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// to allow users to stop an alerting alarm.
@available(iOS 26.0, *)
public struct StopIntent: LiveActivityIntent {
    
    public init() {
        self.alarmID = ""
    }


    public func perform() throws -> some IntentResult {
        guard let alarmUUID = UUID(uuidString: alarmID) else {
            print("⚠️ [StopIntent] Invalid alarmID string: '\(alarmID)'")
            throw IntentError.invalidAlarmID
        }
        print("🛑 StopIntent.perform() called with alarmID: \(alarmUUID)")

        // Stop the alarm — AlarmKit owns the Live Activity lifecycle
        try AlarmManager.shared.stop(id: alarmUUID)
        print("   ✅ Successfully stopped alarm \(alarmUUID)")

        return .result()
    }
    
    public static var title: LocalizedStringResource = "Stop"
    public static var description = IntentDescription("Stop an alert")
    
    @Parameter(title: "alarmID")
    public var alarmID: String
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
}
