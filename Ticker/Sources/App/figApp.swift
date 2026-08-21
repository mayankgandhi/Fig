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
import Factory

@main
struct figApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var hasInitialized = false
    
    var sharedModelContainer: ModelContainer = {
        do {
            return try TickerSchema.makeSharedContainer()
        } catch {
            // Deliberately not fatalError. A failed migration used to become a
            // launch crash loop whose only remedy was deleting the app — which
            // takes every alarm the user ever created with it. Degrade to an
            // in-memory store so the app still launches and the failure is
            // reportable instead of terminal.
            print("❌ Could not open the shared Ticker store: \(error)")
            AlarmTelemetry.record(.alarmScheduleFailed(reason: "model_container_open_failed"))
            do {
                return try ModelContainer(
                    for: TickerSchema.current,
                    configurations: [ModelConfiguration(schema: TickerSchema.current, isStoredInMemoryOnly: true)]
                )
            } catch {
                fatalError("Could not create an in-memory ModelContainer: \(error)")
            }
        }
    }()
    
    // Services now resolved via Factory
    @Injected(\.tickerService) private var tickerService
    @Injected(\.alarmRegenerationService) private var regenerationService
    @Injected(\.modelContextObserver) private var modelContextObserver
    
    // Background task identifier
    private let backgroundTaskIdentifier = "com.fig.alarm.regeneration"
    
    init() {
        // Configure DesignKit with Ticker theme (must be done before any views)
        DesignKit.configure(.ticker)

        // Initialize Factory container
        Container.setupDependencies()

        // Give TickerCore somewhere to send alarm telemetry. Without this the
        // alarm pipeline is unmeasurable: the app had ~158 analytics events and
        // not one of them recorded an alarm firing.
        AlarmTelemetry.install(PostHogAlarmTelemetrySink())
        
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
        
        // Register background task handler, then submit the first request.
        //
        // `scheduleBackgroundTask()` used to be called only from inside
        // `handleBackgroundTask`, so nothing ever submitted the initial request:
        // the task never fired, and therefore never rescheduled itself. The
        // regeneration background task has never run in this app.
        registerBackgroundTasks()
        scheduleBackgroundTask()
        
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
                            
                            // Migrate schedules that AlarmKit can now express
                            // natively, then detect fires that happened while the
                            // app was not running. Both must run before sync, which
                            // reconciles against AlarmKit state.
                            await tickerService.runLaunchMaintenance(context: context)

                            // Synchronize alarms on app launch (main priority)
                            AnalyticsEvents.alarmSyncStarted.track()
                            let syncStartTime = Date()
                            await tickerService.synchronizeAlarmsOnLaunch(context: context)
                            let syncDuration = Int(Date().timeIntervalSince(syncStartTime) * 1000)

                            // Top up expansion-backed schedules.
                            await tickerService.regenerateEnabledTickers(context: context)
                            
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

                            // Foreground is the only trigger we actually control.
                            // This handler previously did nothing but fire an
                            // analytics event, while `RegenerationTrigger` in
                            // TickerCore documented `appForeground` as the
                            // "PRIMARY - guaranteed" path and nothing ever
                            // constructed it. Rate limiting lives inside the
                            // regeneration service, so this is cheap to repeat.
                            Task { @MainActor in
                                let context = ModelContext(sharedModelContainer)
                                await tickerService.runLaunchMaintenance(context: context)
                                await tickerService.synchronizeAlarms(context: context)
                                await tickerService.regenerateEnabledTickers(context: context)
                            }
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
    /// Regenerate alarms for all enabled tickers.
    ///
    /// `@MainActor` so this cannot interleave with launch synchronization. Both
    /// build a `ModelContext` over the same container and mutate the same rows;
    /// running them concurrently made `generatedAlarmKitIDs` last-writer-wins.
    @MainActor
    private func regenerateAllEnabledTickers() async {
        let context = ModelContext(sharedModelContainer)
        await tickerService.regenerateEnabledTickers(context: context)
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
