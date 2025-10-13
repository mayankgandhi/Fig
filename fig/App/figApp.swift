//
//  figApp.swift
//  fig
//
//  Created by Mayank Gandhi on 04/10/25.
//

import SwiftUI
import SwiftData

@main
struct figApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Ticker.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var alarmService = AlarmService()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(alarmService)
                .task {
                    // Synchronize alarms on app launch
                    await alarmService.synchronizeAlarmsOnLaunch(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
