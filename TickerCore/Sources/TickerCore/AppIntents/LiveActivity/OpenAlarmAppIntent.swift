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
@available(iOS 26.0, *)
public struct OpenAlarmAppIntent: LiveActivityIntent {
    

    public func perform() throws -> some IntentResult {
        guard let alarmUUID = UUID(uuidString: alarmID) else {
            print("⚠️ [OpenAlarmAppIntent] Invalid alarmID string: '\(alarmID)'")
            throw IntentError.invalidAlarmID
        }
        print("🛑 OpenAlarmAppIntent.perform() called with alarmID: \(alarmUUID)")

        // Stop the alarm using AlarmManager
        try AlarmManager.shared.stop(id: alarmUUID)
        print("   ✅ Successfully stopped alarm \(alarmUUID)")

        return .result()
    }
    
    public static var title: LocalizedStringResource = "Open App"
    public static var description = IntentDescription("Opens the Ticker app")
    public static var openAppWhenRun = true
    
    @Parameter(title: "alarmID")
    public var alarmID: String
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public init() {
        self.alarmID = ""
    }
}
