//
//  OpenAlarmAppIntent.swift
//  fig
//
//  AppIntent for opening the app
//

import AlarmKit
import AppIntents
import SwiftData

/// An intent that opens the app and stops the alarm
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// as a custom secondary button action. When triggered, it stops the alarm
/// and opens the main app.
@available(iOS 26.0, *)
public struct OpenAlarmAppIntent: LiveActivityIntent {
    
    
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
        print("🛑 OpenAlarmAppIntent.perform() called with alarmID: \(alarmUUID)")

        // Stop the alarm using AlarmManager
        try AlarmManager.shared.stop(id: alarmUUID)
        print("   ✅ Successfully stopped alarm \(alarmUUID)")

        return .result()
    }
    
    public static var title: LocalizedStringResource = "Open App"
    public static var description = IntentDescription("Opens the Sample app")
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
