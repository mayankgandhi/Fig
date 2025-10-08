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

    // Public state
    private(set) var alarms: [UUID: AlarmState] = [:]

    var authorizationStatus: AlarmAuthorizationStatus {
        AlarmAuthorizationStatus(from: alarmManager.authorizationState)
    }

    // Private AlarmKit manager
    @ObservationIgnored
    private let alarmManager = AlarmManager.shared

    // MARK: - Initialization

    init() {
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
        guard let configuration = buildAlarmKitConfiguration(from: alarmItem) else {
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
            await updateLocalAlarmState(from: alarm, label: LocalizedStringResource(stringLiteral: alarmItem.label))

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

            guard let configuration = buildAlarmKitConfiguration(from: alarmItem) else {
                throw AlarmServiceError.invalidConfiguration
            }

            do {
                let alarm = try await alarmManager.schedule(id: alarmItem.id, configuration: configuration)
                alarmItem.alarmKitID = alarm.id
                try context.save()

                await updateLocalAlarmState(from: alarm, label: LocalizedStringResource(stringLiteral: alarmItem.label))
            } catch {
                throw AlarmServiceError.schedulingFailed(underlying: error)
            }
        } else {
            // If disabled, just remove from local state
            await removeLocalAlarmState(id: alarmItem.id)
        }
    }

    func cancelAlarm(id: UUID, context: ModelContext?) throws {
        // Cancel with AlarmKit
        try? alarmManager.cancel(id: id)

        // Remove from local state
        Task {
            await removeLocalAlarmState(id: id)
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
            updateAlarmState(with: remoteAlarms)
        } catch {
            throw AlarmServiceError.schedulingFailed(underlying: error)
        }
    }

    func getAlarmState(id: UUID) -> AlarmState? {
        alarms[id]
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
        print("🔄 Starting alarm synchronization (AlarmKit → SwiftData)...")

        // 1. Fetch all alarms from AlarmKit (source of truth)
        guard let alarmKitAlarms = try? alarmManager.alarms else {
            print("⚠️ Failed to fetch alarms from AlarmKit")
            return
        }

        print("⏰ Found \(alarmKitAlarms.count) alarms in AlarmKit")

        // 2. Clean up template alarms that shouldn't be scheduled
        // Fetch all AlarmItems to check which ones are disabled templates
        let allItemsDescriptor = FetchDescriptor<AlarmItem>()
        let allItems = (try? context.fetch(allItemsDescriptor)) ?? []
        let disabledItemIds = Set(allItems.filter { !$0.isEnabled }.map { $0.id })

        var alarmsToKeep: [Alarm] = []
        for alarm in alarmKitAlarms {
            // If this alarm corresponds to a disabled template, cancel it
            if disabledItemIds.contains(alarm.id) {
                print("🗑️ Canceling template alarm: \(alarm.id)")
                try? alarmManager.cancel(id: alarm.id)
            } else {
                alarmsToKeep.append(alarm)
            }
        }

        print("✅ Kept \(alarmsToKeep.count) valid alarms")

        // 3. Update local AlarmService state with valid alarms only
        for alarm in alarmsToKeep {
            // Look up metadata from SwiftData
            let metadata = allItems.first { $0.id == alarm.id }
            let label = metadata?.label ?? "Alarm"

            // Update local state
            await updateLocalAlarmState(from: alarm, label: LocalizedStringResource(stringLiteral: label))

            print("✅ Loaded alarm: \(label)")
        }

        // 4. Ensure SwiftData entries exist for all AlarmKit alarms
        // (This handles orphaned alarms that exist in AlarmKit but not SwiftData)
        for alarm in alarmsToKeep {
            // If no SwiftData entry exists, create one
            if !allItems.contains(where: { $0.id == alarm.id }) {
                print("📝 Creating SwiftData entry for orphaned alarm: \(alarm.id)")

                let alarmItem = AlarmItem(
                    id: alarm.id,
                    label: "Alarm",
                    isEnabled: true
                )
                alarmItem.alarmKitID = alarm.id
                context.insert(alarmItem)
            }
        }

        // Save any new entries
        try? context.save()

        print("✨ Alarm synchronization complete")
    }

    // MARK: - Private Helpers

    private func observeAlarmUpdates() {
        Task {
            for await incomingAlarms in alarmManager.alarmUpdates {
                updateAlarmState(with: incomingAlarms)
            }
        }
    }

    private func updateAlarmState(with remoteAlarms: [Alarm]) {
        Task { @MainActor in
            // Update existing alarm states
            remoteAlarms.forEach { updated in
                if let existingState = alarms[updated.id] {
                    alarms[updated.id] = AlarmState(from: updated, label: existingState.label)
                } else {
                    // New alarm from old session
                    alarms[updated.id] = AlarmState(from: updated, label: "Alarm (Old Session)")
                }
            }

            let knownAlarmIDs = Set(alarms.keys)
            let incomingAlarmIDs = Set(remoteAlarms.map(\.id))

            // Clean up removed alarms
            let removedAlarmIDs = knownAlarmIDs.subtracting(incomingAlarmIDs)
            removedAlarmIDs.forEach {
                alarms[$0] = nil
            }
        }
    }

    @MainActor
    private func updateLocalAlarmState(from alarm: Alarm, label: LocalizedStringResource) {
        alarms[alarm.id] = AlarmState(from: alarm, label: label)
    }

    @MainActor
    private func removeLocalAlarmState(id: UUID) {
        alarms[id] = nil
    }

    private func buildAlarmKitConfiguration(from alarmItem: AlarmItem) -> AlarmConfiguration? {
        // Build attributes
        let attributes = AlarmAttributes(
            presentation: buildAlarmPresentation(from: alarmItem),
            metadata: alarmItem.tickerData ?? TickerData(),
            tintColor: Color.accentColor
        )

        // Build configuration
        let configuration = AlarmConfiguration(
            countdownDuration: alarmItem.alarmKitCountdownDuration,
            schedule: alarmItem.alarmKitSchedule,
            attributes: attributes,
            stopIntent: StopIntent(alarmID: alarmItem.id.uuidString),
            secondaryIntent: buildSecondaryIntent(for: alarmItem)
        )

        return configuration
    }

    private func buildAlarmPresentation(from alarmItem: AlarmItem) -> AlarmPresentation {
        let secondaryButtonBehavior = alarmItem.alarmKitSecondaryButtonBehavior
        let secondaryButton: AlarmButton? = switch secondaryButtonBehavior {
            case .countdown: .repeatButton
            case .custom: .openAppButton
            default: nil
        }

        let alertContent = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: alarmItem.label),
            stopButton: .stopButton,
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: secondaryButtonBehavior
        )

        guard alarmItem.countdown != nil else {
            // An alarm without a countdown only specifies an alert state
            return AlarmPresentation(alert: alertContent)
        }

        // With countdown enabled, a presentation appears for both countdown and paused state
        let countdownContent = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: alarmItem.label),
            pauseButton: .pauseButton
        )

        let pausedContent = AlarmPresentation.Paused(
            title: "Paused",
            resumeButton: .resumeButton
        )

        return AlarmPresentation(alert: alertContent, countdown: countdownContent, paused: pausedContent)
    }

    private func buildSecondaryIntent(for alarmItem: AlarmItem) -> (any LiveActivityIntent)? {
        switch alarmItem.presentation.secondaryButtonType {
        case .none:
            return nil
        case .countdown:
            return RepeatIntent(alarmID: alarmItem.id.uuidString)
        case .openApp:
            return OpenAlarmAppIntent(alarmID: alarmItem.id.uuidString)
        }
    }
}

// MARK: - AlarmButton Extensions

extension AlarmButton {
    static var openAppButton: Self {
        AlarmButton(text: "Open", textColor: .black, systemImageName: "swift")
    }

    static var pauseButton: Self {
        AlarmButton(text: "Pause", textColor: .black, systemImageName: "pause.fill")
    }

    static var resumeButton: Self {
        AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
    }

    static var repeatButton: Self {
        AlarmButton(text: "Repeat", textColor: .black, systemImageName: "repeat.circle")
    }

    static var stopButton: Self {
        AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle")
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
