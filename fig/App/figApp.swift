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
            Ticker.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
                            await tickerService.synchronizeAlarmsOnLaunch(context: sharedModelContainer.mainContext)
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
