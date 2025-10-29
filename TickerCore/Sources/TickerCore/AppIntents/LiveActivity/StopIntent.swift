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
@available(iOS 26.0, *)
public struct StopIntent: LiveActivityIntent {
    
    public init() {
        self.alarmID = ""
    }

    
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
    
    public func perform() throws -> some IntentResult {
        let alarmUUID = UUID(uuidString: alarmID)!
        print("🛑 StopIntent.perform() called with alarmID: \(alarmUUID)")
        print("   → This should only stop the current alarm instance, not future ones")

        // Stop the alarm using AlarmManager
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
