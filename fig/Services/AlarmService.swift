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



// MARK: - TickerService Protocol

protocol TickerServiceProtocol: Observable {
    var alarms: [UUID: Ticker] { get }
    var authorizationStatus: AlarmAuthorizationStatus { get }

    func requestAuthorization() async throws -> AlarmAuthorizationStatus
    func scheduleAlarm(from alarmItem: Ticker, context: ModelContext) async throws
    func updateAlarm(_ alarmItem: Ticker, context: ModelContext) async throws
    func cancelAlarm(id: UUID, context: ModelContext?) async throws
    func pauseAlarm(id: UUID) throws
    func resumeAlarm(id: UUID) throws
    func stopAlarm(id: UUID) throws
    func repeatCountdown(id: UUID) throws
    func fetchAllAlarms() async throws
    func getTicker(id: UUID) -> Ticker?
    func getAlarmsWithMetadata(context: ModelContext) -> [Ticker]
    func synchronizeAlarmsOnLaunch(context: ModelContext) async
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
final class TickerService: TickerServiceProtocol {
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

    // MARK: - Initialization

    init(
        alarmManager: AlarmManager = AlarmManager.shared,
        configurationBuilder: AlarmConfigurationBuilderProtocol = AlarmConfigurationBuilder(),
        stateManager: AlarmStateManagerProtocol = AlarmStateManager(),
        syncCoordinator: AlarmSyncCoordinatorProtocol = AlarmSyncCoordinator(),
        scheduleExpander: TickerScheduleExpanderProtocol = TickerScheduleExpander()
    ) {
        self.alarmManager = alarmManager
        self.configurationBuilder = configurationBuilder
        self.stateManager = stateManager
        self.syncCoordinator = syncCoordinator
        self.scheduleExpander = scheduleExpander
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

    @MainActor
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

    @MainActor
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

            // Save to SwiftData
            print("   → Saving to SwiftData...")
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
            try context.save()
            print("   → SwiftData save successful")

            // Update local state
            print("   → Updating local state...")
            await stateManager.updateState(ticker: alarmItem)
            print("   → Local state updated")

            // Refresh widget timelines
            print("   → Refreshing widget timelines...")
            refreshWidgetTimelines()
            print("   → Widget timelines refreshed")

        } catch let error as TickerServiceError {
            print("   ❌ TickerServiceError: \(error)")
            throw error
        } catch {
            print("   ❌ General error: \(error)")
            print("   → Rolling back SwiftData changes...")
            // Rollback: remove from SwiftData if scheduling failed
            // Only delete if we just inserted it
            let descriptor = FetchDescriptor<Ticker>(predicate: #Predicate<Ticker> { ticker in
                ticker.id == alarmItem.id
            })
            if let existingItem = try? context.fetch(descriptor).first {
                context.delete(existingItem)
                try? context.save()
            }
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
        print("   ✅ scheduleSimpleAlarm() completed successfully")
    }

    @MainActor
    private func scheduleCompositeAlarm(_ alarmItem: Ticker, context: ModelContext) async throws {
        guard let schedule = alarmItem.schedule else {
            throw TickerServiceError.invalidConfiguration
        }

        // 1. Expand schedule into concrete dates
        let now = Date()
        
        // Use the start date from the schedule for expansion
        let expansionStartDate: Date
        switch schedule {
        case .hourly(_, let startTime, _):
            // Use the start time if it's in the future, otherwise use now
            expansionStartDate = startTime > now ? startTime : now
        case .daily(_, let startDate):
            expansionStartDate = max(startDate, now)
        case .weekdays(_, _, let startDate):
            expansionStartDate = max(startDate, now)
        case .monthly(_, _, let startDate):
            expansionStartDate = max(startDate, now)
        case .yearly(_, _, _, let startDate):
            expansionStartDate = max(startDate, now)
        case .every(_, _, let startTime, _):
            // Use the start time if it's in the future, otherwise use now
            expansionStartDate = startTime > now ? startTime : now
        default:
            expansionStartDate = now
        }
        
        let dates = scheduleExpander.expandSchedule(schedule, startingFrom: expansionStartDate, days: alarmItem.generationWindow)
        print("   → Expanded dates: \(dates)")
        print("   → Number of dates: \(dates.count)")

        guard !dates.isEmpty else {
            print("   ❌ No dates generated from expansion")
            throw TickerServiceError.invalidConfiguration
        }

        // 2. Generate alarm configurations for each date
        var scheduledIDs: [UUID] = []

        do {
            for (index, date) in dates.enumerated() {
                print("   → Processing date \(index + 1)/\(dates.count): \(date)")
                
                // Create a temporary one-time schedule for this occurrence
                let oneTimeSchedule = TickerSchedule.oneTime(date: date)
                let tempAlarmItem = createTemporaryAlarmItem(from: alarmItem, with: oneTimeSchedule)
                print("   → Created temp alarm item with schedule: \(tempAlarmItem.schedule)")

                guard let configuration = configurationBuilder.buildConfiguration(from: tempAlarmItem) else {
                    print("   ❌ Failed to build configuration for date: \(date)")
                    continue
                }
                print("   → Configuration built successfully")

                // Generate unique ID for this occurrence
                let occurrenceID = UUID()
                print("   → Scheduling alarm with ID: \(occurrenceID)")
                _ = try await alarmManager.schedule(id: occurrenceID, configuration: configuration)
                print("   → Alarm scheduled successfully")
                scheduledIDs.append(occurrenceID)
            }

            // 3. Update ticker with generated IDs
            alarmItem.generatedAlarmKitIDs = scheduledIDs
            alarmItem.isEnabled = true

            // 4. Save to SwiftData
            print("   → Saving to SwiftData...")
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
            try context.save()
            print("   → SwiftData save successful")

            // 5. Update local state
            print("   → Updating local state...")
            await stateManager.updateState(ticker: alarmItem)
            print("   → Local state updated")

            // 6. Refresh widget timelines
            print("   → Refreshing widget timelines...")
            refreshWidgetTimelines()
            print("   → Widget timelines refreshed")

        } catch {
            print("   ❌ Composite alarm scheduling failed: \(error)")
            print("   → Rolling back \(scheduledIDs.count) scheduled alarms...")
            // Rollback: cancel any scheduled alarms
            for id in scheduledIDs {
                do {
                    try alarmManager.cancel(id: id)
                    print("   → Cancelled alarm: \(id)")
                } catch {
                    print("   ⚠️ Failed to cancel alarm \(id): \(error)")
                }
            }

            // Reset generated IDs to ensure clean state
            alarmItem.generatedAlarmKitIDs = []

            // Only delete if we just inserted it
            let descriptor = FetchDescriptor<Ticker>(predicate: #Predicate<Ticker> { ticker in
                ticker.id == alarmItem.id
            })
            if let existingItem = try? context.fetch(descriptor).first {
                context.delete(existingItem)
                try? context.save()
                print("   → Deleted alarm from SwiftData")
            }

            print("   → Rollback complete")
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

    @MainActor
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
                    print("   → Using composite schedule rescheduling")
                    // Composite schedule
                    let now = Date()
                    print("   → Current time: \(now)")
                    
                    // For hourly schedules, use the start time from the schedule if it's in the future
                    let expansionStartDate: Date
                    switch schedule {
                    case .hourly(_, let startTime, _):
                        // Use the start time if it's in the future, otherwise use now
                        expansionStartDate = startTime > now ? startTime : now
                        print("   → Hourly schedule, startTime: \(startTime)")
                    default:
                        expansionStartDate = now
                        print("   → Non-hourly schedule, using current time")
                    }
                    print("   → Expansion start date: \(expansionStartDate)")
                    
                    print("   → Expanding schedule...")
                    let dates = scheduleExpander.expandSchedule(schedule, startingFrom: expansionStartDate, days: alarmItem.generationWindow)
                    print("   → Generated \(dates.count) dates")

                    var scheduledIDs: [UUID] = []
                    for date in dates {
                        print("   → Processing date: \(date)")
                        let oneTimeSchedule = TickerSchedule.oneTime(date: date)
                        let tempAlarmItem = createTemporaryAlarmItem(from: alarmItem, with: oneTimeSchedule)

                        guard let configuration = configurationBuilder.buildConfiguration(from: tempAlarmItem) else {
                            print("   ❌ Failed to build configuration for date: \(date)")
                            continue
                        }

                        let occurrenceID = UUID()
                        print("   → Scheduling occurrence ID: \(occurrenceID) for date: \(date)")
                        _ = try await alarmManager.schedule(id: occurrenceID, configuration: configuration)
                        scheduledIDs.append(occurrenceID)
                    }

                    alarmItem.generatedAlarmKitIDs = scheduledIDs
                    print("   → Composite schedule rescheduled with \(scheduledIDs.count) occurrences")
                }

                print("   → Final SwiftData save...")
                try context.save()
                print("   → Updating local state...")
                await stateManager.updateState(ticker: alarmItem)
                print("   → Refreshing widget timelines...")
                // Refresh widget timelines
                refreshWidgetTimelines()
                print("   → Composite schedule rescheduled successfully")
            } catch {
                print("   ❌ Scheduling failed: \(error)")
                throw TickerServiceError.schedulingFailed(underlying: error)
            }
        } else {
            print("   → Alarm is disabled, removing from local state")
            // If disabled, just remove from local state
            await stateManager.removeState(id: alarmItem.id)
            print("   → Removed from local state")
            
            // Refresh widget timelines
            print("   → Refreshing widget timelines...")
            refreshWidgetTimelines()
            print("   → Widget timelines refreshed")
        }
        print("   ✅ updateAlarm() completed successfully")
    }

    @MainActor
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

        // Remove from local state
        print("   → Removing from local state...")
        await stateManager.removeState(id: id)
        print("   → Removed from local state")

        // Refresh widget timelines
        print("   → Refreshing widget timelines...")
        refreshWidgetTimelines()
        print("   ✅ cancelAlarm() completed")
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

    @MainActor
    func getAlarmsWithMetadata(context: ModelContext) -> [Ticker] {
        // Get all tickers from state manager (main thread access to Observable state)
        // Note: This is fast - just copying references from a dictionary
        return Array(alarms.values).sorted { $0.createdAt > $1.createdAt }
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

// MARK: - Alarm Extensions

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
