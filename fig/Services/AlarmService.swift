//
//  AlarmService.swift
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

// MARK: - AlarmService Error Types

enum AlarmServiceError: LocalizedError {
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



// MARK: - AlarmService Protocol

protocol AlarmServiceProtocol: Observable {
    var alarms: [UUID: AlarmState] { get }
    var authorizationStatus: AlarmAuthorizationStatus { get }

    func requestAuthorization() async throws -> AlarmAuthorizationStatus
    func scheduleAlarm(from alarmItem: AlarmItem, context: ModelContext) async throws
    func updateAlarm(_ alarmItem: AlarmItem, context: ModelContext) async throws
    func cancelAlarm(id: UUID, context: ModelContext?) throws
    func pauseAlarm(id: UUID) throws
    func resumeAlarm(id: UUID) throws
    func stopAlarm(id: UUID) throws
    func repeatCountdown(id: UUID) throws
    func fetchAllAlarms() throws
    func getAlarmState(id: UUID) -> AlarmState?
    func getAlarmsWithMetadata(context: ModelContext) -> [(state: AlarmState, metadata: AlarmItem?)]
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

// MARK: - AlarmService Implementation

@Observable
final class AlarmService: AlarmServiceProtocol {
    typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<TickerData>

    // Public state (delegated to state manager)
    var alarms: [UUID: AlarmState] {
        stateManager.alarms
    }

    var authorizationStatus: AlarmAuthorizationStatus {
        AlarmAuthorizationStatus(from: alarmManager.authorizationState)
    }

    // Private AlarmKit manager
    @ObservationIgnored
    private let alarmManager = AlarmManager.shared

    // Configuration builder
    @ObservationIgnored
    private let configurationBuilder: AlarmConfigurationBuilderProtocol

    // State manager
    @ObservationIgnored
    private let stateManager: AlarmStateManagerProtocol

    // Sync coordinator
    @ObservationIgnored
    private let syncCoordinator: AlarmSyncCoordinatorProtocol

    // MARK: - Initialization

    init(
        configurationBuilder: AlarmConfigurationBuilderProtocol = AlarmConfigurationBuilder(),
        stateManager: AlarmStateManagerProtocol = AlarmStateManager(),
        syncCoordinator: AlarmSyncCoordinatorProtocol = AlarmSyncCoordinator()
    ) {
        self.configurationBuilder = configurationBuilder
        self.stateManager = stateManager
        self.syncCoordinator = syncCoordinator
        observeAlarmUpdates()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> AlarmAuthorizationStatus {
        switch alarmManager.authorizationState {
        case .notDetermined:
            do {
                let state = try await alarmManager.requestAuthorization()
                return AlarmAuthorizationStatus(from: state)
            } catch {
                throw AlarmServiceError.schedulingFailed(underlying: error)
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

    func scheduleAlarm(from alarmItem: AlarmItem, context: ModelContext) async throws {
        // 1. Request authorization
        let authStatus = try await requestAuthorization()
        guard authStatus == .authorized else {
            throw AlarmServiceError.notAuthorized
        }

        // 2. Build AlarmKit configuration
        guard let configuration = configurationBuilder.buildConfiguration(from: alarmItem) else {
            throw AlarmServiceError.invalidConfiguration
        }

        // 3. Schedule with AlarmKit
        do {
            let alarm = try await alarmManager.schedule(id: alarmItem.id, configuration: configuration)

            // 4. Update alarmKitID for tracking
            alarmItem.alarmKitID = alarm.id
            alarmItem.isEnabled = true

            // 5. Save to SwiftData
            context.insert(alarmItem)
            try context.save()

            // 6. Update local state
            await stateManager.updateState(from: alarm, label: LocalizedStringResource(stringLiteral: alarmItem.label))

        } catch let error as AlarmServiceError {
            throw error
        } catch {
            // Rollback: remove from SwiftData if scheduling failed
            context.delete(alarmItem)
            throw AlarmServiceError.schedulingFailed(underlying: error)
        }
    }

    func updateAlarm(_ alarmItem: AlarmItem, context: ModelContext) async throws {
        // Cancel existing alarm
        if let alarmKitID = alarmItem.alarmKitID {
            try? alarmManager.cancel(id: alarmKitID)
        }

        // Save to SwiftData first
        do {
            try context.save()
        } catch {
            throw AlarmServiceError.swiftDataSaveFailed(underlying: error)
        }

        // If alarm is enabled, reschedule with AlarmKit
        if alarmItem.isEnabled {
            let authStatus = try await requestAuthorization()
            guard authStatus == .authorized else {
                throw AlarmServiceError.notAuthorized
            }

            guard let configuration = configurationBuilder.buildConfiguration(from: alarmItem) else {
                throw AlarmServiceError.invalidConfiguration
            }

            do {
                let alarm = try await alarmManager.schedule(id: alarmItem.id, configuration: configuration)
                alarmItem.alarmKitID = alarm.id
                try context.save()

                await stateManager.updateState(from: alarm, label: LocalizedStringResource(stringLiteral: alarmItem.label))
            } catch {
                throw AlarmServiceError.schedulingFailed(underlying: error)
            }
        } else {
            // If disabled, just remove from local state
            await stateManager.removeState(id: alarmItem.id)
        }
    }

    func cancelAlarm(id: UUID, context: ModelContext?) throws {
        // Cancel with AlarmKit
        try? alarmManager.cancel(id: id)

        // Remove from local state
        Task {
            await stateManager.removeState(id: id)
        }

        // Delete from SwiftData if context provided
        if let context = context {
            let descriptor = FetchDescriptor<AlarmItem>(predicate: #Predicate { $0.id == id })
            if let alarmItem = try? context.fetch(descriptor).first {
                context.delete(alarmItem)
                try? context.save()
            }
        }
    }

    // MARK: - Alarm Control
    
    
    // Pausing only works for alarm in countdown mode
    func pauseAlarm(id: UUID) throws {
        do {
            try alarmManager.pause(id: id)
        } catch {
            throw AlarmServiceError.schedulingFailed(underlying: error)
        }
    }

    func resumeAlarm(id: UUID) throws {
        do {
            try alarmManager.resume(id: id)
        } catch {
            throw AlarmServiceError.schedulingFailed(underlying: error)
        }
    }

    func stopAlarm(id: UUID) throws {
        do {
            try alarmManager.stop(id: id)
        } catch {
            throw AlarmServiceError.schedulingFailed(underlying: error)
        }
    }

    func repeatCountdown(id: UUID) throws {
        do {
            try alarmManager.countdown(id: id)
        } catch {
            throw AlarmServiceError.schedulingFailed(underlying: error)
        }
    }

    // MARK: - Queries

    func fetchAllAlarms() throws {
        do {
            let remoteAlarms = try alarmManager.alarms
            stateManager.updateState(with: remoteAlarms)
        } catch {
            throw AlarmServiceError.schedulingFailed(underlying: error)
        }
    }

    func getAlarmState(id: UUID) -> AlarmState? {
        stateManager.getState(id: id)
    }

    func getAlarmsWithMetadata(context: ModelContext) -> [(state: AlarmState, metadata: AlarmItem?)] {
        // Get all alarms from AlarmKit (source of truth)
        let alarmStates = Array(alarms.values)

        // Fetch all AlarmItems once
        let allItemsDescriptor = FetchDescriptor<AlarmItem>()
        let allItems = (try? context.fetch(allItemsDescriptor)) ?? []

        // Create a lookup dictionary for fast access
        let itemsById = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })

        // Map each alarm to its SwiftData metadata
        return alarmStates.map { alarmState in
            let metadata = itemsById[alarmState.id]
            return (state: alarmState, metadata: metadata)
        }
        .sorted { $0.metadata?.createdAt ?? Date.distantPast > $1.metadata?.createdAt ?? Date.distantPast }
    }

    // MARK: - Synchronization

    func synchronizeAlarmsOnLaunch(context: ModelContext) async {
        await syncCoordinator.synchronizeOnLaunch(
            alarmManager: alarmManager,
            stateManager: stateManager,
            context: context
        )
    }

    // MARK: - Private Helpers

    private func observeAlarmUpdates() {
        Task {
            for await incomingAlarms in alarmManager.alarmUpdates {
                stateManager.updateState(with: incomingAlarms)
            }
        }
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
