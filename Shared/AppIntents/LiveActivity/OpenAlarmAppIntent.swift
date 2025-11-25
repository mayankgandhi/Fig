//
//  OpenAlarmAppIntent.swift
//  fig
//
//  AppIntent for opening the app
//

import AlarmKit
import AppIntents
import SwiftData
import Factory

/// An intent that opens the app and stops the alarm
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// as a custom secondary button action. When triggered, it stops the alarm
/// and opens the main app.
struct OpenAlarmAppIntent: LiveActivityIntent {
    
    
    private func getSharedModelContext() -> ModelContext {
        // Get shared ModelContainer for App Groups access
        let schema = Schema([Ticker.self])
        let modelConfiguration: ModelConfiguration
        
        if let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.m.fig") {
            modelConfiguration = ModelConfiguration(schema: schema, url: sharedURL.appendingPathComponent("Ticker.sqlite"))
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return ModelContext(container)
        } catch {
            fatalError("Could not create ModelContext: \(error)")
        }
    }
    
    func perform() throws -> some IntentResult {
        let alarmUUID = UUID(uuidString: alarmID)!
        print("🛑 OpenAlarmAppIntent.perform() called with alarmID: \(alarmUUID)")
        
        // Use TickerService to ensure proper cleanup
        let context = getSharedModelContext()
        let tickerService = Container.shared.tickerService()

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
