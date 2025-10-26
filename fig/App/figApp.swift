//
//  figApp.swift
//  fig
//
//  Created by Mayank Gandhi on 04/10/25.
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct figApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Ticker.self
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
    @State private var regenerationService = AlarmRegenerationService()

    // Background task identifier
    private let backgroundTaskIdentifier = "com.fig.alarm.regeneration"

    init() {
        // Register background task handler
        registerBackgroundTasks()

        // Register for time zone change notifications
        registerTimeZoneChangeObserver()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    // Main app
                    AppView()
                        .environment(tickerService)
                        .task {
                            let context = ModelContext(sharedModelContainer)

                            // Run migration if needed
                            let didMigrate = await AlarmMigrationV2.migrateIfNeeded(context: context)

                            // If migration just completed, force regenerate all tickers
                            if didMigrate {
                                await AlarmMigrationV2.forceRegenerateAllTickers(
                                    context: context,
                                    regenerationService: regenerationService
                                )
                            }

                            // Synchronize alarms on app launch
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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(newPhase: newPhase)
        }
    }

    // MARK: - App Lifecycle Management

    /// Handle scene phase changes (app foreground/background transitions)
    private func handleScenePhaseChange(newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App entered foreground - PRIMARY regeneration trigger
            print("🌅 App entered foreground - triggering alarm regeneration check")
            Task {
                await regenerateAllEnabledTickers()
            }

            // Schedule next background task
            scheduleBackgroundTask()

        case .background:
            // App entered background
            print("🌙 App entered background")

        case .inactive:
            // App is transitioning states
            break

        @unknown default:
            break
        }
    }

    /// Regenerate alarms for all enabled tickers
    private func regenerateAllEnabledTickers() async {
        let context = ModelContext(sharedModelContainer)
        let descriptor = FetchDescriptor<Ticker>(predicate: #Predicate<Ticker> { ticker in
            ticker.isEnabled == true
        })

        do {
            let tickers = try context.fetch(descriptor)
            print("🔄 Found \(tickers.count) enabled tickers to check")

            for ticker in tickers {
                // Check if regeneration is needed (non-blocking, respects rate limiting)
                do {
                    try await regenerationService.regenerateAlarmsIfNeeded(
                        ticker: ticker,
                        context: context,
                        force: false
                    )
                } catch {
                    print("⚠️ Failed to regenerate \(ticker.displayName): \(error)")
                    // Continue with other tickers even if one fails
                }
            }
        } catch {
            print("❌ Failed to fetch enabled tickers: \(error)")
        }
    }

    // MARK: - Background Tasks

    /// Register background task handlers
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
        print("✅ Registered background task: \(backgroundTaskIdentifier)")
    }

    /// Handle background task execution
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        print("⏰ Background task started")

        // Schedule next background task
        scheduleBackgroundTask()

        // Set task expiration handler
        task.expirationHandler = {
            print("⚠️ Background task expired")
        }

        // Perform alarm regeneration
        Task {
            await regenerateAllEnabledTickers()
            task.setTaskCompleted(success: true)
            print("✅ Background task completed")
        }
    }

    /// Schedule the next background task
    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)

        // Schedule for midnight (next day)
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let midnight = calendar.startOfDay(for: tomorrow)

        request.earliestBeginDate = midnight

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Scheduled background task for \(midnight)")
        } catch {
            print("❌ Failed to schedule background task: \(error)")
        }
    }

    // MARK: - Time Zone Change Observer

    /// Register observer for time zone changes
    private func registerTimeZoneChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { _ in
            print("🌍 Time zone changed - triggering alarm regeneration")
            Task {
                await self.regenerateAllEnabledTickers()
            }
        }
        print("✅ Registered time zone change observer")
    }
}
