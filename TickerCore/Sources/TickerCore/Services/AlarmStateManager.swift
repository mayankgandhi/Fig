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

public protocol AlarmStateManagerProtocol: Observable {
    func updateState(with remoteAlarms: [Alarm])
    func updateState(ticker: Ticker)
    func removeState(id: UUID)
    func getState(id: UUID) -> Ticker?
    func getAllTickers() -> [Ticker]
    func queryAlarmKit(alarmManager: AlarmManager) throws -> [Alarm]
}

// MARK: - AlarmStateManager Implementation

@Observable
public final class AlarmStateManager: AlarmStateManagerProtocol {

    // Public state
    private(set) var alarms: [UUID: Ticker]

    // MARK: - State Management
    
    public init() {
        self.alarms = [:]
    }

    public func updateState(with remoteAlarms: [Alarm]) {
        print("   → Updating state with \(remoteAlarms.count) remote Tickers")

        // Update existing alarm states
        remoteAlarms.forEach { updated in
            if let existingTicker = alarms[updated.id] {
                // Keep existing Ticker, just update its enabled state
                existingTicker.isEnabled = true
                alarms[updated.id] = existingTicker
                print("   → Updated existing ticker: \(existingTicker.label)")
            } else {
                // New alarm from old session - create minimal Ticker
                let ticker = Ticker(
                    id: updated.id,
                    label: "Alarm (Old Session)",
                    isEnabled: true
                )
                ticker.generatedAlarmKitIDs = [updated.id]
                alarms[updated.id] = ticker
                print("   → Created new ticker from old session: \(ticker.label)")
            }
        }

        let knownAlarmIDs = Set(alarms.keys)
        let incomingAlarmIDs = Set(remoteAlarms.map(\.id))

        // Clean up removed alarms
        let removedAlarmIDs = knownAlarmIDs.subtracting(incomingAlarmIDs)
        if !removedAlarmIDs.isEmpty {
            print("   → Removing \(removedAlarmIDs.count) alarms from state")
            removedAlarmIDs.forEach {
                alarms[$0] = nil
            }
        }

        print("   → State update complete. Total alarms: \(alarms.count)")
    }

    public func updateState(ticker: Ticker) {
        alarms[ticker.id] = ticker
    }

    public func removeState(id: UUID) {
        alarms[id] = nil
    }

    public func getState(id: UUID) -> Ticker? {
        alarms[id]
    }

    /// Returns all cached tickers as an array sorted by creation date
    /// This provides efficient access without querying SwiftData
    public func getAllTickers() -> [Ticker] {
        return Array(alarms.values).sorted { $0.createdAt > $1.createdAt }
    }

    /// Centralized AlarmKit query method
    /// All code should use this instead of directly accessing alarmManager.alarms
    /// - Parameter alarmManager: The AlarmManager instance to query
    /// - Returns: Array of Alarm objects from AlarmKit
    /// - Throws: AlarmKit errors if query fails
    public func queryAlarmKit(alarmManager: AlarmManager) throws -> [Alarm] {
        return try alarmManager.alarms
    }
}
