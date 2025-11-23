//
//  figApp.swift
//  fig
//
//  Created by Mayank Gandhi on 04/10/25.
//

import SwiftUI
import SwiftData
import BackgroundTasks
import TickerCore
import Gate
import UIKit
import DesignKit

@main
struct figApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var hasInitialized = false
    
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
    
    private let tickerService = TickerService()
    private let regenerationService = AlarmRegenerationService()
    private let modelContextObserver = ModelContextObserver()
    
    // Background task identifier
    private let backgroundTaskIdentifier = "com.fig.alarm.regeneration"
    
    init() {
        // Configure DesignKit with Ticker theme (must be done before any views)
        DesignKit.configure(.ticker)
        
        // Configure UserService with Ticker-specific settings and migration
        let sharedDefaults = UserDefaults(suiteName: "group.m.fig") ?? .standard
        UserService.shared.configure(
            userDefaultsKey: "revenueCatUserID",
            userDefaults: sharedDefaults,
            migrationKey: "revenueCatUserID"  // Migrate from existing key if needed
        )
        
        // Configure Gate SubscriptionService with Ticker-specific settings
        SubscriptionService.shared.configure(
            configuration: .ticker,
            userIDProvider: { UserService.shared.getCurrentUserID() }
        )
        
        // Keep widget extensions in sync with the latest subscription state.
        SubscriptionStatusObserver.shared.start()
        
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
                        .environmentObject(modelContextObserver)
                        .task {
                            // Prevent double execution
                            guard !hasInitialized else { return }
                            hasInitialized = true
                            
                            // Initialize UserService and Gate SubscriptionService in background (non-blocking)
                            Task.detached(priority: .background) {
                                try? await UserService.shared.initialize()
                                try? await SubscriptionService.shared.initialize()
                            }
                            
                            let context = ModelContext(sharedModelContainer)
                            
                            // Track app launch with alarm counts
                            let descriptor = FetchDescriptor<Ticker>()
                            if let tickers = try? context.fetch(descriptor) {
                                let enabledCount = tickers.filter { $0.isEnabled }.count
                                AnalyticsEvents.appLaunched(
                                    alarmCount: tickers.count,
                                    enabledAlarmCount: enabledCount
                                ).track()
                            }
                            
                            // Synchronize alarms on app launch (main priority)
                            AnalyticsEvents.alarmSyncStarted.track()
                            let syncStartTime = Date()
                            await tickerService.synchronizeAlarmsOnLaunch(context: context)
                            let syncDuration = Int(Date().timeIntervalSince(syncStartTime) * 1000)
                            
                            // Track sync completed
                            let syncedDescriptor = FetchDescriptor<Ticker>()
                            if let syncedTickers = try? context.fetch(syncedDescriptor) {
                                AnalyticsEvents.alarmSyncCompleted(
                                    syncedCount: syncedTickers.count,
                                    orphanedCount: 0,
                                    durationMs: syncDuration
                                ).track()
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                            AnalyticsEvents.appForegrounded.track()
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
    
    // MARK: - App Lifecycle Management
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
            let newTimezone = TimeZone.current.identifier
            AnalyticsEvents.timezoneChanged(newTimezone: newTimezone).track()
            Task {
                await self.regenerateAllEnabledTickers()
            }
        }
        print("✅ Registered time zone change observer")
    }
}
