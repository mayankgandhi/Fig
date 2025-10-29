//
//  StopIntent.swift
//  fig
//
//  AppIntent for stopping an alarm
//

import AlarmKit
import AppIntents
import SwiftData

/// An intent that stops an active alarm
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// to allow users to stop an alerting alarm.
struct StopIntent: LiveActivityIntent {

    func perform() throws -> some IntentResult {
        let alarmUUID = UUID(uuidString: alarmID)!
        print("🛑 StopIntent.perform() called with alarmID: \(alarmUUID)")
        print("   → This should only stop the current alarm instance, not future ones")
        
        // Use TickerService to ensure proper cleanup
        let context = getSharedModelContext()
        let tickerService = TickerService()
        
        do {
            try tickerService.stopAlarm(id: alarmUUID)
            print("   ✅ Successfully stopped alarm \(alarmUUID) with proper cleanup")
        } catch {
            print("   ❌ Failed to stop alarm \(alarmUUID): \(error)")
            // Fallback to direct AlarmManager call
            try AlarmManager.shared.stop(id: alarmUUID)
            print("   ⚠️ Used fallback AlarmManager.stop() - cleanup may be incomplete")
        }
        
        return .result()
    }

    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop an alert")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}
