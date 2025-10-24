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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Ticker.self,
            AlarmType.self
        ])
        
        // Use App Groups for shared data access with widget extension
        let modelConfiguration: ModelConfiguration
        if let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.m.fig") {
            modelConfiguration = ModelConfiguration(schema: schema, url: sharedURL.appendingPathComponent("Ticker.sqlite"))
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var tickerService = TickerService()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    // Main app
                    AppView()
                        .environment(tickerService)
                        .task {
                            // Synchronize alarms on app launch
                            let context = ModelContext(sharedModelContainer)
                            await tickerService.synchronizeAlarmsOnLaunch(context: context)
                        }
                } else {
                    // Onboarding flow
                    OnboardingContainerView()
                        .environment(tickerService)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        }
        .modelContainer(sharedModelContainer)
    }
}
