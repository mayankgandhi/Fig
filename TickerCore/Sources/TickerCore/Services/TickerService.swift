//
//  TickerService.swift
//  fig
//
//  Service layer that encapsulates all AlarmKit operations
//  and bridges SwiftData (persistent storage) with AlarmKit (runtime scheduler)
//

import Foundation
import SwiftUI
import SwiftData
import AlarmKit
import AppIntents
import WidgetKit
import Factory

// MARK: - TickerService Error Types

public enum TickerServiceError: LocalizedError {
    case notAuthorized
    case schedulingFailed(underlying: Error)
    case alarmNotFound(UUID)
    case invalidConfiguration
    case swiftDataSaveFailed(underlying: Error)
    
    public var errorDescription: String? {
        switch self {
            case .notAuthorized:
                return "Permission to schedule alarms has not been granted"
            case .schedulingFailed(let error):
                return "Failed to schedule alarm: \(error.localizedDescription)"
            case .alarmNotFound(let id):
                return "Alarm with ID \(id) not found"
            case .invalidConfiguration:
                return "Invalid alarm configuration"
            case .swiftDataSaveFailed(let error):
                return "Failed to save alarm data: \(error.localizedDescription)"
        }
    }
}

public enum AlarmAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    
    init(from alarmKitStatus: AlarmManager.AuthorizationState) {
        switch alarmKitStatus {
            case .notDetermined:
                self = .notDetermined
            case .denied:
                self = .denied
            case .authorized:
                self = .authorized
            @unknown default:
                self = .notDetermined
        }
    }
}

// MARK: - TickerService Implementation

@Observable
public final class TickerService {

    typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<TickerData>

    public var authorizationStatus: AlarmAuthorizationStatus {
        AlarmAuthorizationStatus(from: alarmManager.authorizationState)
    }

    // State manager access (for AlarmKit queries only)
    public var stateManager: AlarmStateManagerProtocol {
        _stateManager
    }

    // Private AlarmKit manager
    @ObservationIgnored
    @Injected(\.alarmManager) private var alarmManager

    // Configuration builder
    @ObservationIgnored
    @Injected(\.alarmConfigurationBuilder) private var configurationBuilder

    // State manager (private backing, public via computed property)
    @ObservationIgnored
    @Injected(\.alarmStateManager) private var _stateManager

    // Synchronization service
    @ObservationIgnored
    @Injected(\.alarmSynchronizationService) private var synchronizationService

    // Regeneration service
    @ObservationIgnored
    @Injected(\.alarmRegenerationService) private var regenerationService

    // MARK: - Initialization

    public init() {
        // Dependencies auto-injected via @Injected
    }
    
    // MARK: - Authorization
    
    public func requestAuthorization() async throws -> AlarmAuthorizationStatus {
        switch alarmManager.authorizationState {
            case .notDetermined:
                do {
                    let state = try await alarmManager.requestAuthorization()
                    return AlarmAuthorizationStatus(from: state)
                } catch {
                    throw TickerServiceError.schedulingFailed(underlying: error)
                }
            case .denied:
                return .denied
            case .authorized:
                return .authorized
            @unknown default:
                return .notDetermined
        }
    }
    
    // MARK: - Schedule Management
    
    public func scheduleAlarm(from alarmItem: Ticker, context: ModelContext) async throws {
        print("🔔 TickerService.scheduleAlarm() started")
        print("   → alarmItem ID: \(alarmItem.id)")
        print("   → alarmItem label: '\(alarmItem.label)'")
        print("   → alarmItem schedule: \(String(describing: alarmItem.schedule))")
        print("   → alarmItem isEnabled: \(alarmItem.isEnabled)")
        
        // 1. Request authorization
        print("   → Checking authorization...")
        let authStatus = try await requestAuthorization()
        print("   → Authorization status: \(authStatus)")
        guard authStatus == .authorized else {
            print("   ❌ Not authorized")
            throw TickerServiceError.notAuthorized
        }
        
        // 2. Determine if this is a simple or collection schedule
        guard let schedule = alarmItem.schedule else {
            print("   ❌ No schedule found")
            throw TickerServiceError.invalidConfiguration
        }

        let isSimpleSchedule = isSimple(schedule)
        print("   → isSimpleSchedule: \(isSimpleSchedule)")

        if isSimpleSchedule {
            print("   → Using simple alarm scheduling")
            // Simple schedule: 1:1 AlarmKit mapping (backward compatible)
            try await scheduleSimpleAlarm(alarmItem, context: context)
        } else {
            print("   → Using collection alarm scheduling")
            // Collection schedule: Generate multiple AlarmKit alarms
            try await scheduleCollectionAlarm(alarmItem, context: context)
        }
        print("   ✅ scheduleAlarm() completed successfully")
    }
    
    // MARK: - Private Scheduling Methods
    
    private func scheduleSimpleAlarm(_ alarmItem: Ticker, context: ModelContext) async throws {
        print("   🔧 scheduleSimpleAlarm() started")
        print("   → alarmItem ID: \(alarmItem.id)")
        
        // Generate a unique ID for this alarm instance to prevent stopping all future alarms
        let uniqueAlarmID = UUID()
        print("   → Generated unique alarm ID: \(uniqueAlarmID)")
        print("   → Main ticker ID: \(alarmItem.id)")
        print("   → This unique ID will be used for StopIntent to prevent stopping all future alarms")
        
        // Build AlarmKit configuration with the unique ID
        print("   → Building AlarmKit configuration...")
        guard let configuration = configurationBuilder.buildConfiguration(from: alarmItem, occurrenceAlarmID: uniqueAlarmID) else {
            print("   ❌ Failed to build configuration")
            throw TickerServiceError.invalidConfiguration
        }
        print("   → Configuration built successfully")
        
        // Schedule with AlarmKit using the unique ID
        do {
            print("   → Scheduling with AlarmKit...")
            _ = try await alarmManager.schedule(id: uniqueAlarmID, configuration: configuration)
            print("   → AlarmKit scheduling successful")
            
            // Store the generated ID in the ticker's generatedAlarmKitIDs array
            alarmItem.generatedAlarmKitIDs = [uniqueAlarmID]
            alarmItem.isEnabled = true
            print("   → Updated alarmItem properties with unique alarm ID: \(uniqueAlarmID)")
            
            // Save to SwiftData on main thread
            print("   → Saving to SwiftData...")
            await MainActor.run {
                // Check if item is already in context before inserting
                let allItemsDescriptor = FetchDescriptor<Ticker>()
                let allItems = try? context.fetch(allItemsDescriptor)
                let existingItems = allItems?.filter { $0.id == alarmItem.id }
                if existingItems?.isEmpty ?? true {
                    context.insert(alarmItem)
                    print("   → Inserted new alarm into context")
                } else {
                    print("   → Alarm already exists in context, updating in place")
                }
                try? context.save()
            }
            print("   → SwiftData save successful")

            // Refresh widget timelines on main thread
            print("   → Refreshing widget timelines...")
            await MainActor.run {
                refreshWidgetTimelines()
            }
            print("   → Widget timelines refreshed")

        } catch let error as TickerServiceError {
            print("   ❌ TickerServiceError: \(error)")
            throw error
        } catch {
            print("   ❌ General error")
            dump(error)
            print("   → Rolling back SwiftData changes...")
            // Rollback: remove from SwiftData if scheduling failed
            // Only delete if we just inserted it
            let alarmID = alarmItem.id
            let descriptor = FetchDescriptor<Ticker>(predicate: #Predicate<Ticker> { ticker in
                ticker.id == alarmID
            })
            if let existingItem = try? context.fetch(descriptor).first {
                context.delete(existingItem)
                try? context.save()
            }
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
        print("   ✅ scheduleSimpleAlarm() completed successfully")
    }
    
    private func scheduleCollectionAlarm(_ alarmItem: Ticker, context: ModelContext) async throws {
        print("   🔧 scheduleCollectionAlarm() using regeneration service")
        
        // Use the regeneration service to handle alarm generation with the new 48-hour window approach
        do {
            // Force regeneration since this is a new alarm
            try await regenerationService.regenerateAlarmsIfNeeded(
                ticker: alarmItem,
                context: context,
                force: true
            )
            
            // Enable the alarm
            alarmItem.isEnabled = true
            
            // Save to SwiftData on main thread
            print("   → Saving to SwiftData...")
            await MainActor.run {
                // Check if item is already in context before inserting
                let allItemsDescriptor = FetchDescriptor<Ticker>()
                let allItems = try? context.fetch(allItemsDescriptor)
                let existingItems = allItems?.filter { $0.id == alarmItem.id }
                if existingItems?.isEmpty ?? true {
                    context.insert(alarmItem)
                    print("   → Inserted new alarm into context")
                } else {
                    print("   → Alarm already exists in context, updating in place")
                }
                try? context.save()
            }
            print("   → SwiftData save successful")

            // Refresh widget timelines on main thread
            print("   → Refreshing widget timelines...")
            await MainActor.run {
                refreshWidgetTimelines()
            }
            print("   → Widget timelines refreshed")

        } catch {
            print("   ❌ Collection alarm scheduling failed: \(error)")
            // Regeneration service handles its own alarm rollback
            // Just clean up SwiftData record
            let alarmID = alarmItem.id
            let descriptor = FetchDescriptor<Ticker>(predicate: #Predicate<Ticker> { ticker in
                ticker.id == alarmID
            })
            if let existingItem = try? context.fetch(descriptor).first {
                context.delete(existingItem)
                try? context.save()
                print("   → Removed alarm from SwiftData")
            }
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    private func isSimple(_ schedule: TickerSchedule) -> Bool {
        switch schedule {
            case .oneTime, .daily:
                return true
            case .hourly, .weekdays, .biweekly, .monthly, .yearly, .every:
                return false
        }
    }
    
    private func createTemporaryAlarmItem(from original: Ticker, with schedule: TickerSchedule) -> Ticker {
        let temp = Ticker(
            id: original.id,
            label: original.label,
            isEnabled: true,
            schedule: schedule,
            countdown: original.countdown,
            presentation: original.presentation,
            tickerData: original.tickerData
        )
        return temp
    }
    
    public func updateAlarm(_ alarmItem: Ticker, context: ModelContext) async throws {
        print("🔄 TickerService.updateAlarm() started")
        print("   → alarmItem ID: \(alarmItem.id)")
        print("   → alarmItem label: '\(alarmItem.label)'")
        print("   → alarmItem isEnabled: \(alarmItem.isEnabled)")
        print("   → generatedAlarmKitIDs: \(alarmItem.generatedAlarmKitIDs)")
        
        // Cancel all existing alarms
        print("   → Canceling existing alarms...")
        for id in alarmItem.generatedAlarmKitIDs {
            print("   → Canceling alarm ID: \(id)")
            try? alarmManager.cancel(id: id)
        }
        
        // Save to SwiftData first
        print("   → Saving to SwiftData...")
        do {
            try context.save()
            print("   → SwiftData save successful")
        } catch {
            print("   ❌ SwiftData save failed: \(error)")
            throw TickerServiceError.swiftDataSaveFailed(underlying: error)
        }
        
        // If alarm is enabled, reschedule with AlarmKit
        if alarmItem.isEnabled {
            print("   → Alarm is enabled, rescheduling...")
            print("   → Checking authorization...")
            let authStatus = try await requestAuthorization()
            print("   → Authorization status: \(authStatus)")
            guard authStatus == .authorized else {
                print("   ❌ Not authorized")
                throw TickerServiceError.notAuthorized
            }
            
            guard let schedule = alarmItem.schedule else {
                print("   ❌ No schedule found")
                throw TickerServiceError.invalidConfiguration
            }
            
            let isSimpleSchedule = isSimple(schedule)
            print("   → isSimpleSchedule: \(isSimpleSchedule)")
            
            do {
                if isSimpleSchedule {
                    print("   → Using simple schedule rescheduling")
                    // Generate a unique ID for this alarm instance
                    let uniqueAlarmID = UUID()
                    print("   → Generated unique alarm ID for reschedule: \(uniqueAlarmID)")
                    
                    // Simple schedule
                    print("   → Building configuration...")
                    guard let configuration = configurationBuilder.buildConfiguration(from: alarmItem, occurrenceAlarmID: uniqueAlarmID) else {
                        print("   ❌ Failed to build configuration")
                        throw TickerServiceError.invalidConfiguration
                    }
                    
                    print("   → Scheduling with AlarmKit...")
                    _ = try await alarmManager.schedule(id: uniqueAlarmID, configuration: configuration)
                    alarmItem.generatedAlarmKitIDs = [uniqueAlarmID]
                    print("   → Simple schedule rescheduled successfully with unique ID: \(uniqueAlarmID)")
                } else {
                    print("   → Using collection schedule rescheduling via regeneration service")
                    // Use regeneration service for collection schedules
                    try await regenerationService.regenerateAlarmsIfNeeded(
                        ticker: alarmItem,
                        context: context,
                        force: true
                    )
                    print("   → Collection schedule regenerated successfully")
                }

                print("   → Final SwiftData save...")
                try context.save()
                print("   → Refreshing widget timelines...")
                // Refresh widget timelines on main thread
                await MainActor.run {
                    refreshWidgetTimelines()
                }
                print("   → Rescheduling completed successfully")
            } catch {
                print("   ❌ Scheduling failed: \(error)")
                throw TickerServiceError.schedulingFailed(underlying: error)
            }
        } else {
            print("   → Alarm is disabled")

            // Refresh widget timelines on main thread
            print("   → Refreshing widget timelines...")
            await MainActor.run {
                refreshWidgetTimelines()
            }
            print("   → Widget timelines refreshed")
        }
    }
    
    public func cancelAlarm(id: UUID, context: ModelContext?) async throws {
        print("🗑️ TickerService.cancelAlarm() started")
        print("   → id: \(id)")
        
        // Fetch the alarm to get all generated IDs
        if let context = context {
            let allItemsDescriptor = FetchDescriptor<Ticker>()
            let allItems = try? context.fetch(allItemsDescriptor)
            if let alarmItem = allItems?.first(where: { $0.id == id }) {
                print("   → Found alarm in SwiftData: '\(alarmItem.label)'")
                print("   → Generated IDs: \(alarmItem.generatedAlarmKitIDs)")
                
                // IMPORTANT: Access all properties BEFORE deletion to resolve SwiftData faults
                // This prevents "backing data was detached" errors
                let generatedIDs = alarmItem.generatedAlarmKitIDs
                
                // Force-resolve all lazy-loaded properties to prevent fault resolution after deletion
                _ = alarmItem.schedule // Accesses scheduleData which has @Attribute(.externalStorage)
                _ = alarmItem.tickerData
                _ = alarmItem.label
                _ = alarmItem.countdown
                _ = alarmItem.presentation
                
                // Cancel all generated alarms
                print("   → Canceling \(generatedIDs.count) AlarmKit alarm(s)...")
                for generatedID in generatedIDs {
                    do {
                        try alarmManager.cancel(id: generatedID)
                        print("   → Cancelled AlarmKit alarm: \(generatedID)")
                    } catch {
                        print("   ⚠️ Failed to cancel AlarmKit alarm \(generatedID): \(error)")
                    }
                }
                
                // Delete from SwiftData
                print("   → Deleting from SwiftData...")
                context.delete(alarmItem)
                do {
                    try context.save()
                    print("   → SwiftData deletion saved")
                } catch {
                    print("   ❌ Failed to save SwiftData deletion: \(error)")
                    throw TickerServiceError.swiftDataSaveFailed(underlying: error)
                }
            } else {
                print("   ⚠️ Alarm not found in SwiftData, attempting direct cancellation")
            }
        } else {
            print("   ⚠️ No context provided, performing fallback cancellation")
        }
        
        // Fallback: always try to cancel the main ID
        do {
            try alarmManager.cancel(id: id)
            print("   → Cancelled main alarm ID: \(id)")
        } catch {
            print("   ⚠️ Failed to cancel main alarm ID \(id): \(error)")
            // Don't throw here as the alarm might not exist
        }

        // Refresh widget timelines on main thread
        print("   → Refreshing widget timelines...")
        await MainActor.run {
            refreshWidgetTimelines()
        }
        print("   ✅ cancelAlarm() completed")
    }

    /// Cancel a specific alarm instance by ID
    /// For recurring alarms, regeneration will automatically detect the missing alarm and recreate it.
    /// - Parameter id: The alarm ID to cancel
    public func cancelAlarmInstance(id: UUID) throws {
        print("⏭️ TickerService.cancelAlarmInstance() started")
        print("   → alarm ID: \(id)")
        
        do {
            try alarmManager.cancel(id: id)
            print("   ✅ Cancelled alarm instance")
            
            // Refresh widget timelines
            refreshWidgetTimelines()
        } catch {
            print("   ❌ Failed to cancel alarm instance: \(error)")
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }

    // MARK: - Alarm Control
    
    
    // Pausing only works for alarm in countdown mode
    public func pauseAlarm(id: UUID) throws {
        do {
            try alarmManager.pause(id: id)
            // Refresh widget timelines to show updated alarm state
            refreshWidgetTimelines()
        } catch {
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    public func resumeAlarm(id: UUID) throws {
        do {
            try alarmManager.resume(id: id)
            // Refresh widget timelines to show updated alarm state
            refreshWidgetTimelines()
        } catch {
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    public func stopAlarm(id: UUID) throws {
        do {
            try alarmManager.stop(id: id)
            print("✅ Successfully stopped alarm \(id)")

            // Note: Synchronization service will handle cleanup of stopped alarm IDs
            // when the app comes to foreground or during the next sync

            // Refresh widget timelines to show updated alarm state
            refreshWidgetTimelines()
        } catch {
            print("❌ Failed to stop alarm \(id): \(error)")
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    public func repeatCountdown(id: UUID) throws {
        do {
            try alarmManager.countdown(id: id)
            // Refresh widget timelines to show updated alarm state
            refreshWidgetTimelines()
        } catch {
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    // MARK: - Widget Refresh

    private func refreshWidgetTimelines() {
        // Refresh widgets asynchronously to avoid blocking the main thread
        Task.detached(priority: .utility) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Alarm State Query

    /// Check if an alarm with the given ticker ID is currently active in AlarmKit
    /// This checks both the main ticker ID and any generated alarm IDs
    public func isAlarmActive(tickerID: UUID) -> Bool {
        guard let alarms = try? stateManager.queryAlarmKit(alarmManager: alarmManager) else {
            return false
        }

        // Check if any alarm in AlarmKit matches this ticker ID
        // This could be the main ID or any of the generated IDs
        return alarms.contains { alarm in
            alarm.id == tickerID
        }
    }

    /// Get the active alarm from AlarmKit for a given ticker ID
    /// Returns nil if no active alarm is found
    public func getActiveAlarm(tickerID: UUID) -> Alarm? {
        guard let alarms = try? stateManager.queryAlarmKit(alarmManager: alarmManager) else {
            return nil
        }

        // Find the alarm matching this ticker ID
        return alarms.first { alarm in
            alarm.id == tickerID
        }
    }
    
    // MARK: - Synchronization

    @MainActor
    public func synchronizeAlarmsOnLaunch(context: ModelContext) async {
        await synchronizationService.synchronize(
            alarmManager: alarmManager,
            stateManager: stateManager,
            context: context
        )
    }

    /// Manually trigger synchronization
    /// Uses AlarmManager.alarms as source of truth
    /// Call this when app comes to foreground or after stopping an alarm
    @MainActor
    public func synchronizeAlarms(context: ModelContext) async {
        await synchronizationService.synchronize(
            alarmManager: alarmManager,
            stateManager: stateManager,
            context: context
        )
    }
}

extension Alarm {
    public var alertingTime: Date? {
        guard let schedule else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        switch schedule {
            case .fixed(let date):
                return date
            case .relative(let relative):
                // Get today's date with the specified hour/minute
                var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
                components.hour = relative.time.hour
                components.minute = relative.time.minute
                components.second = 0
                
                guard var alarmDate = calendar.date(from: components) else {
                    return nil
                }
                
                // If the alarm time has passed today, move to tomorrow
                if alarmDate <= now {
                    guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: alarmDate) else {
                        return alarmDate // Fallback to today if tomorrow calculation fails
                    }
                    alarmDate = tomorrow
                }
                
                return alarmDate
            @unknown default:
                return nil
        }
    }
}
