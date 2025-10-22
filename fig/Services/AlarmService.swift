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
    func cancelAlarm(id: UUID, context: ModelContext?) throws
    func pauseAlarm(id: UUID) throws
    func resumeAlarm(id: UUID) throws
    func stopAlarm(id: UUID) throws
    func repeatCountdown(id: UUID) throws
    func fetchAllAlarms() throws
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
        // 1. Request authorization
        let authStatus = try await requestAuthorization()
        guard authStatus == .authorized else {
            throw TickerServiceError.notAuthorized
        }

        // 2. Determine if this is a simple or composite schedule
        guard let schedule = alarmItem.schedule else {
            throw TickerServiceError.invalidConfiguration
        }

        let isSimpleSchedule = isSimple(schedule)

        if isSimpleSchedule {
            // Simple schedule: 1:1 AlarmKit mapping (backward compatible)
            try await scheduleSimpleAlarm(alarmItem, context: context)
        } else {
            // Composite schedule: Generate multiple AlarmKit alarms
            try await scheduleCompositeAlarm(alarmItem, context: context)
        }
    }

    // MARK: - Private Scheduling Methods

    @MainActor
    private func scheduleSimpleAlarm(_ alarmItem: Ticker, context: ModelContext) async throws {
        // Build AlarmKit configuration
        guard let configuration = configurationBuilder.buildConfiguration(from: alarmItem) else {
            throw TickerServiceError.invalidConfiguration
        }

        // Schedule with AlarmKit
        do {
            _ = try await alarmManager.schedule(id: alarmItem.id, configuration: configuration)

            // Update generatedAlarmKitIDs for tracking
            alarmItem.generatedAlarmKitIDs = [alarmItem.id]
            alarmItem.isEnabled = true

            // Save to SwiftData
            context.insert(alarmItem)
            try context.save()

            // Update local state
            await stateManager.updateState(ticker: alarmItem)

            // Refresh widget timelines
            refreshWidgetTimelines()

        } catch let error as TickerServiceError {
            throw error
        } catch {
            // Rollback: remove from SwiftData if scheduling failed
            context.delete(alarmItem)
            throw TickerServiceError.schedulingFailed(underlying: error)
        }
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
        default:
            expansionStartDate = now
        }
        
        let dates = scheduleExpander.expandSchedule(schedule, startingFrom: expansionStartDate, days: alarmItem.generationWindow)

        guard !dates.isEmpty else {
            throw TickerServiceError.invalidConfiguration
        }

        // 2. Generate alarm configurations for each date
        var scheduledIDs: [UUID] = []

        do {
            for date in dates {
                // Create a temporary one-time schedule for this occurrence
                let oneTimeSchedule = TickerSchedule.oneTime(date: date)
                let tempAlarmItem = createTemporaryAlarmItem(from: alarmItem, with: oneTimeSchedule)

                guard let configuration = configurationBuilder.buildConfiguration(from: tempAlarmItem) else {
                    continue
                }

                // Generate unique ID for this occurrence
                let occurrenceID = UUID()
                _ = try await alarmManager.schedule(id: occurrenceID, configuration: configuration)
                scheduledIDs.append(occurrenceID)
            }

            // 3. Update ticker with generated IDs
            alarmItem.generatedAlarmKitIDs = scheduledIDs
            alarmItem.isEnabled = true

            // 4. Save to SwiftData
            context.insert(alarmItem)
            try context.save()

            // 5. Update local state
            await stateManager.updateState(ticker: alarmItem)

            // 6. Refresh widget timelines
            refreshWidgetTimelines()

        } catch {
            // Rollback: cancel any scheduled alarms
            for id in scheduledIDs {
                try? alarmManager.cancel(id: id)
            }
            context.delete(alarmItem)
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
        // Cancel all existing alarms
        for id in alarmItem.generatedAlarmKitIDs {
            try? alarmManager.cancel(id: id)
        }

        // Save to SwiftData first
        do {
            try context.save()
        } catch {
            throw TickerServiceError.swiftDataSaveFailed(underlying: error)
        }

        // If alarm is enabled, reschedule with AlarmKit
        if alarmItem.isEnabled {
            let authStatus = try await requestAuthorization()
            guard authStatus == .authorized else {
                throw TickerServiceError.notAuthorized
            }

            guard let schedule = alarmItem.schedule else {
                throw TickerServiceError.invalidConfiguration
            }

            let isSimpleSchedule = isSimple(schedule)

            do {
                if isSimpleSchedule {
                    // Simple schedule
                    guard let configuration = configurationBuilder.buildConfiguration(from: alarmItem) else {
                        throw TickerServiceError.invalidConfiguration
                    }

                    _ = try await alarmManager.schedule(id: alarmItem.id, configuration: configuration)
                    alarmItem.generatedAlarmKitIDs = [alarmItem.id]
                } else {
                    // Composite schedule
                    let now = Date()
                    
                    // For hourly schedules, use the start time from the schedule if it's in the future
                    let expansionStartDate: Date
                    switch schedule {
                    case .hourly(_, let startTime, _):
                        // Use the start time if it's in the future, otherwise use now
                        expansionStartDate = startTime > now ? startTime : now
                    default:
                        expansionStartDate = now
                    }
                    
                    let dates = scheduleExpander.expandSchedule(schedule, startingFrom: expansionStartDate, days: alarmItem.generationWindow)

                    var scheduledIDs: [UUID] = []
                    for date in dates {
                        let oneTimeSchedule = TickerSchedule.oneTime(date: date)
                        let tempAlarmItem = createTemporaryAlarmItem(from: alarmItem, with: oneTimeSchedule)

                        guard let configuration = configurationBuilder.buildConfiguration(from: tempAlarmItem) else {
                            continue
                        }

                        let occurrenceID = UUID()
                        _ = try await alarmManager.schedule(id: occurrenceID, configuration: configuration)
                        scheduledIDs.append(occurrenceID)
                    }

                    alarmItem.generatedAlarmKitIDs = scheduledIDs
                }

                try context.save()
                await stateManager.updateState(ticker: alarmItem)
                
                // Refresh widget timelines
                refreshWidgetTimelines()
            } catch {
                throw TickerServiceError.schedulingFailed(underlying: error)
            }
        } else {
            // If disabled, just remove from local state
            await stateManager.removeState(id: alarmItem.id)
            
            // Refresh widget timelines
            refreshWidgetTimelines()
        }
    }

    func cancelAlarm(id: UUID, context: ModelContext?) throws {
        // Fetch the alarm to get all generated IDs
        if let context = context {
            Task { @MainActor in
                let descriptor = FetchDescriptor<Ticker>(predicate: #Predicate { $0.id == id })
                if let alarmItem = try? context.fetch(descriptor).first {
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
                    for generatedID in generatedIDs {
                        try? alarmManager.cancel(id: generatedID)
                    }

                    // Delete from SwiftData
                    context.delete(alarmItem)
                    try? context.save()
                }
            }
        } else {
            // Fallback: just try to cancel the main ID
            try? alarmManager.cancel(id: id)
        }

        // Remove from local state
        Task {
            await stateManager.removeState(id: id)
        }

        // Refresh widget timelines
        refreshWidgetTimelines()
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

    func fetchAllAlarms() throws {
        do {
            let remoteAlarms = try alarmManager.alarms
            stateManager.updateState(with: remoteAlarms)
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
