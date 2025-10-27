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

// MARK: - TickerService Error Types

enum TickerServiceError: LocalizedError {
    case notAuthorized
    case schedulingFailed(underlying: Error)
    case alarmNotFound(UUID)
    case invalidConfiguration
    case swiftDataSaveFailed(underlying: Error)
    
    var errorDescription: String? {
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

enum AlarmAuthorizationStatus {
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
final class TickerService {
    typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<TickerData>
    
    // Public state (delegated to state manager)
    var alarms: [UUID: Ticker] {
        stateManager.alarms
    }
    
    var authorizationStatus: AlarmAuthorizationStatus {
        AlarmAuthorizationStatus(from: alarmManager.authorizationState)
    }
    
    // Private AlarmKit manager
    @ObservationIgnored
    private let alarmManager: AlarmManager
    
    // Configuration builder
    @ObservationIgnored
    private let configurationBuilder: AlarmConfigurationBuilderProtocol
    
    // State manager
    @ObservationIgnored
    private let stateManager: AlarmStateManagerProtocol
    
    // Sync coordinator
    @ObservationIgnored
    private let syncCoordinator: AlarmSyncCoordinatorProtocol
    
    // Schedule expander
    @ObservationIgnored
    private let scheduleExpander: TickerScheduleExpanderProtocol
    
    // Regeneration service
    @ObservationIgnored
    private let regenerationService: AlarmRegenerationServiceProtocol
    
    // MARK: - Initialization
    
    init(
        alarmManager: AlarmManager = AlarmManager.shared,
        configurationBuilder: AlarmConfigurationBuilderProtocol = AlarmConfigurationBuilder(),
        stateManager: AlarmStateManagerProtocol = AlarmStateManager(),
        syncCoordinator: AlarmSyncCoordinatorProtocol = AlarmSyncCoordinator(),
        scheduleExpander: TickerScheduleExpanderProtocol = TickerScheduleExpander(),
        regenerationService: AlarmRegenerationServiceProtocol = AlarmRegenerationService()
    ) {
        self.alarmManager = alarmManager
        self.configurationBuilder = configurationBuilder
        self.stateManager = stateManager
        self.syncCoordinator = syncCoordinator
        self.scheduleExpander = scheduleExpander
        self.regenerationService = regenerationService
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws -> AlarmAuthorizationStatus {
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
    
    func scheduleAlarm(from alarmItem: Ticker, context: ModelContext) async throws {
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
        
        // 2. Determine if this is a simple or composite schedule
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
            print("   → Using composite alarm scheduling")
            // Composite schedule: Generate multiple AlarmKit alarms
            try await scheduleCompositeAlarm(alarmItem, context: context)
        }
        print("   ✅ scheduleAlarm() completed successfully")
    }
    
    // MARK: - Private Scheduling Methods
    
    private func scheduleSimpleAlarm(_ alarmItem: Ticker, context: ModelContext) async throws {
        print("   🔧 scheduleSimpleAlarm() started")
        print("   → alarmItem ID: \(alarmItem.id)")
        
        // Build AlarmKit configuration
        print("   → Building AlarmKit configuration...")
        guard let configuration = configurationBuilder.buildConfiguration(from: alarmItem) else {
            print("   ❌ Failed to build configuration")
            throw TickerServiceError.invalidConfiguration
        }
        print("   → Configuration built successfully")
        
        // Schedule with AlarmKit
        do {
            print("   → Scheduling with AlarmKit...")
            _ = try await alarmManager.schedule(id: alarmItem.id, configuration: configuration)
            print("   → AlarmKit scheduling successful")
            
            // Update generatedAlarmKitIDs for tracking
            alarmItem.generatedAlarmKitIDs = [alarmItem.id]
            alarmItem.isEnabled = true
            print("   → Updated alarmItem properties")
            
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
            
            // Update local state on main thread
            print("   → Updating local state...")
            stateManager.updateState(ticker: alarmItem)
            
            // Refresh widget timelines on main thread
            print("   → Refreshing widget timelines...")
            await MainActor.run {
                refreshWidgetTimelines()
            }
            print("   → Widget timelines refreshed")
            
            // Update widget cache
            await WidgetDataSharingService.updateSharedCache(context: context)
            
        } catch let error as TickerServiceError {
            print("   ❌ TickerServiceError: \(error)")
            throw error
        } catch {
            print("   ❌ General error: \(error)")
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
    
    private func scheduleCompositeAlarm(_ alarmItem: Ticker, context: ModelContext) async throws {
        print("   🔧 scheduleCompositeAlarm() using regeneration service")
        
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
            
            // Update local state on main thread
            print("   → Updating local state...")
            await MainActor.run {
                stateManager.updateState(ticker: alarmItem)
            }
            // Refresh widget timelines on main thread
            print("   → Refreshing widget timelines...")
            await MainActor.run {
                refreshWidgetTimelines()
            }
            print("   → Widget timelines refreshed")
            
            // Update widget cache
            await WidgetDataSharingService.updateSharedCache(context: context)
            
        } catch {
            print("   ❌ Composite alarm scheduling failed: \(error)")
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
    
    func updateAlarm(_ alarmItem: Ticker, context: ModelContext) async throws {
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
                    // Simple schedule
                    print("   → Building configuration...")
                    guard let configuration = configurationBuilder.buildConfiguration(from: alarmItem) else {
                        print("   ❌ Failed to build configuration")
                        throw TickerServiceError.invalidConfiguration
                    }
                    
                    print("   → Scheduling with AlarmKit...")
                    _ = try await alarmManager.schedule(id: alarmItem.id, configuration: configuration)
                    alarmItem.generatedAlarmKitIDs = [alarmItem.id]
                    print("   → Simple schedule rescheduled successfully")
                } else {
                    print("   → Using composite schedule rescheduling via regeneration service")
                    // Use regeneration service for composite schedules
                    try await regenerationService.regenerateAlarmsIfNeeded(
                        ticker: alarmItem,
                        context: context,
                        force: true
                    )
                    print("   → Composite schedule regenerated successfully")
                }
                
                print("   → Final SwiftData save...")
                try context.save()
                print("   → Updating local state...")
                stateManager.updateState(ticker: alarmItem)
                print("   → Refreshing widget timelines...")
                // Refresh widget timelines on main thread
                await MainActor.run {
                    refreshWidgetTimelines()
                }
                print("   → Composite schedule rescheduled successfully")
                
                // Update widget cache
                await WidgetDataSharingService.updateSharedCache(context: context)
            } catch {
                print("   ❌ Scheduling failed: \(error)")
                throw TickerServiceError.schedulingFailed(underlying: error)
            }
        } else {
            print("   → Alarm is disabled, removing from local state")
            // If disabled, just remove from local state
            stateManager.removeState(id: alarmItem.id)
            print("   → Removed from local state")
            
            // Refresh widget timelines on main thread
            print("   → Refreshing widget timelines...")
            await MainActor.run {
                refreshWidgetTimelines()
            }
            print("   → Widget timelines refreshed")
            
            // Update widget cache
            await WidgetDataSharingService.updateSharedCache(context: context)
        }
    }
    
    func cancelAlarm(id: UUID, context: ModelContext?) async throws {
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
        
        // Remove from local state on main thread
        print("   → Removing from local state...")
        await MainActor.run {
            stateManager.removeState(id: id)
        }
        print("   → Removed from local state")
        
        // Refresh widget timelines on main thread
        print("   → Refreshing widget timelines...")
        await MainActor.run {
            refreshWidgetTimelines()
        }
        print("   ✅ cancelAlarm() completed")
        
        // Update widget cache
        if let context = context {
            await WidgetDataSharingService.updateSharedCache(context: context)
        }
    }
    
    // MARK: - Alarm Control
    
    
    // Pausing only works for alarm in countdown mode
    func pauseAlarm(id: UUID) throws {
        do {
            try alarmManager.pause(id: id)
            // Refresh widget timelines to show updated alarm state
            refreshWidgetTimelines()
        } catch {
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    func resumeAlarm(id: UUID) throws {
        do {
            try alarmManager.resume(id: id)
            // Refresh widget timelines to show updated alarm state
            refreshWidgetTimelines()
        } catch {
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    func stopAlarm(id: UUID) throws {
        do {
            try alarmManager.stop(id: id)
            // Refresh widget timelines to show updated alarm state
            refreshWidgetTimelines()
        } catch {
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    func repeatCountdown(id: UUID) throws {
        do {
            try alarmManager.countdown(id: id)
            // Refresh widget timelines to show updated alarm state
            refreshWidgetTimelines()
        } catch {
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    // MARK: - Queries
    
    func fetchAllAlarms() async throws {
        do {
            let remoteAlarms = try alarmManager.alarms
            await stateManager.updateState(with: remoteAlarms)
        } catch {
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
    }
    
    func getTicker(id: UUID) -> Ticker? {
        stateManager.getState(id: id)
    }
    
    func getAlarmsWithMetadata(context: ModelContext) -> [Ticker] {
        // Get all tickers from SwiftData (source of truth for persistence)
        // This ensures all saved tickers are visible, even if they don't have active AlarmKit alarms
        let descriptor = FetchDescriptor<Ticker>()
        let allTickers = (try? context.fetch(descriptor)) ?? []
        
        // Merge with state manager to get any runtime updates
        var tickerMap: [UUID: Ticker] = [:]
        
        // Start with all SwiftData tickers
        for ticker in allTickers {
            tickerMap[ticker.id] = ticker
        }
        
        // Override with state manager data for active alarms (preserves runtime state)
        for (id, stateTicker) in alarms {
            tickerMap[id] = stateTicker
        }
        
        return Array(tickerMap.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Widget Refresh
    
    private func refreshWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Synchronization
    
    @MainActor
    func synchronizeAlarmsOnLaunch(context: ModelContext) async {
        await syncCoordinator.synchronizeOnLaunch(
            alarmManager: alarmManager,
            stateManager: stateManager,
            context: context
        )
    }
}

extension Alarm {
    var alertingTime: Date? {
        guard let schedule else { return nil }
        
        switch schedule {
            case .fixed(let date):
                return date
            case .relative(let relative):
                var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
                components.hour = relative.time.hour
                components.minute = relative.time.minute
                return Calendar.current.date(from: components)
            @unknown default:
                return nil
        }
    }
}
