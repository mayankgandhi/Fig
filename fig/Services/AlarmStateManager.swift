//
//  AlarmStateManager.swift
//  fig
//
//  Manages local alarm state synchronization and updates
//

import Foundation
import AlarmKit
import SwiftUI

// MARK: - AlarmStateManager Protocol

protocol AlarmStateManagerProtocol: Observable {
    var alarms: [UUID: AlarmState] { get }

    func updateState(with remoteAlarms: [Alarm])
    func updateState(from alarm: Alarm, label: LocalizedStringResource) async
    func removeState(id: UUID) async
    func getState(id: UUID) -> AlarmState?
}

// MARK: - AlarmStateManager Implementation

@Observable
final class AlarmStateManager: AlarmStateManagerProtocol {

    // Public state
    private(set) var alarms: [UUID: AlarmState] = [:]

    // MARK: - State Management

    func updateState(with remoteAlarms: [Alarm]) {
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
    func updateState(from alarm: Alarm, label: LocalizedStringResource) {
        alarms[alarm.id] = AlarmState(from: alarm, label: label)
    }

    @MainActor
    func removeState(id: UUID) {
        alarms[id] = nil
    }

    func getState(id: UUID) -> AlarmState? {
        alarms[id]
    }
}
