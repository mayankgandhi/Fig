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
    var alarms: [UUID: Ticker] { get }

    func updateState(with remoteAlarms: [Alarm])
    func updateState(from alarm: Alarm, ticker: Ticker) async
    func removeState(id: UUID) async
    func getState(id: UUID) -> Ticker?
}

// MARK: - AlarmStateManager Implementation

@Observable
final class AlarmStateManager: AlarmStateManagerProtocol {

    // Public state
    private(set) var alarms: [UUID: Ticker] = [:]

    // MARK: - State Management

    func updateState(with remoteAlarms: [Alarm]) {
        Task { @MainActor in
            // Update existing alarm states
            remoteAlarms.forEach { updated in
                if let existingTicker = alarms[updated.id] {
                    // Keep existing Ticker, just update its enabled state
                    existingTicker.isEnabled = true
                    alarms[updated.id] = existingTicker
                } else {
                    // New alarm from old session - create minimal Ticker
                    let ticker = Ticker(
                        id: updated.id,
                        label: "Alarm (Old Session)",
                        isEnabled: true
                    )
                    ticker.alarmKitID = updated.id
                    alarms[updated.id] = ticker
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
    func updateState(from alarm: Alarm, ticker: Ticker) {
        alarms[alarm.id] = ticker
    }

    @MainActor
    func removeState(id: UUID) {
        alarms[id] = nil
    }

    func getState(id: UUID) -> Ticker? {
        alarms[id]
    }
}
