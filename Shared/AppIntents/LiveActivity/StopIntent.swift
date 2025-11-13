//
//  StopIntent.swift
//  fig
//
//  AppIntent for stopping an alarm
//

import AlarmKit
import AppIntents
import SwiftData
import ActivityKit
import TickerCore

/// An intent that stops an active alarm
///
/// This intent is used in Live Activities and Dynamic Island presentations
/// to allow users to stop an alerting alarm.
struct StopIntent: LiveActivityIntent {
    
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
        
        // Dismiss any associated live activities
        Task {
            await dismissLiveActivities(for: alarmUUID)
        }
        
        return .result()
    }
    
    /// Dismisses live activities associated with the stopped alarm
    private func dismissLiveActivities(for alarmID: UUID) async {
        print("   🔄 Dismissing live activities for alarm \(alarmID)...")
        
        // Query all active alarm activities
        let activities = Activity<AlarmAttributes<TickerData>>.activities
        
        guard !activities.isEmpty else {
            print("   ℹ️ No active live activities found")
            return
        }
        
        print("   → Found \(activities.count) active live activity/ies")
        
        // Filter activities to only those matching the stopped alarm ID
        let matchingActivities = activities.filter { activity in
            activity.content.state.alarmID == alarmID
        }
        
        guard !matchingActivities.isEmpty else {
            print("   ℹ️ No live activities found matching alarm ID \(alarmID)")
            return
        }
        
        print("   → Found \(matchingActivities.count) matching live activity/ies for alarm \(alarmID)")
        
        // End all matching activities
        var activitiesEnded = 0
        for activity in matchingActivities {
            do {
                // Use the current activity state as the final state
                let currentState = activity.content.state
                // Create a final state indicating the alarm was stopped
                let finalState = AlarmPresentationState(
                    alarmID: currentState.alarmID,
                    mode: .alert(.init(time: .init(hour: 0, minute: 0)))
                )
                
                // End the activity with immediate dismissal
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
                activitiesEnded += 1
                print("   ✅ Ended live activity \(activity.id)")
            } catch {
                print("   ⚠️ Failed to end live activity \(activity.id): \(error)")
            }
        }
        
        if activitiesEnded > 0 {
            print("   ✅ Successfully dismissed \(activitiesEnded) live activity/ies")
        }
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
