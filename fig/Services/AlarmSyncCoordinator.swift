//
//  AlarmSyncCoordinator.swift
//  fig
//
//  Handles synchronization between AlarmKit and SwiftData on app launch
//

import Foundation
import SwiftUI
import SwiftData
import AlarmKit

// MARK: - AlarmSyncCoordinator Protocol

protocol AlarmSyncCoordinatorProtocol {
    func synchronizeOnLaunch(
        alarmManager: AlarmManager,
        stateManager: AlarmStateManagerProtocol,
        context: ModelContext
    ) async
}

// MARK: - AlarmSyncCoordinator Implementation

struct AlarmSyncCoordinator: AlarmSyncCoordinatorProtocol {

    func synchronizeOnLaunch(
        alarmManager: AlarmManager,
        stateManager: AlarmStateManagerProtocol,
        context: ModelContext
    ) async {
        print("🔄 Starting alarm synchronization (AlarmKit → SwiftData)...")

        // 1. Fetch all alarms from AlarmKit (source of truth)
        guard let alarmKitAlarms = try? alarmManager.alarms else {
            print("⚠️ Failed to fetch alarms from AlarmKit")
            return
        }

        print("⏰ Found \(alarmKitAlarms.count) alarms in AlarmKit")

        // 2. Fetch all Tickers from SwiftData
        let allItemsDescriptor = FetchDescriptor<Ticker>()
        let allItems = (try? context.fetch(allItemsDescriptor)) ?? []
        let disabledItemIds = Set(allItems.filter { !$0.isEnabled }.map { $0.id })

        // Build a map of all AlarmKit IDs (both single and composite generated)
        var alarmKitIDsToTicker: [UUID: Ticker] = [:]
        for ticker in allItems {
            if let alarmKitID = ticker.alarmKitID {
                alarmKitIDsToTicker[alarmKitID] = ticker
            }
            for generatedID in ticker.generatedAlarmKitIDs {
                alarmKitIDsToTicker[generatedID] = ticker
            }
        }

        // 3. Clean up disabled alarms and orphaned composite alarms
        var alarmsToKeep: [Alarm] = []
        for alarm in alarmKitAlarms {
            // Check if this alarm belongs to a disabled ticker
            if disabledItemIds.contains(alarm.id) {
                print("🗑️ Canceling disabled ticker alarm: \(alarm.id)")
                try? alarmManager.cancel(id: alarm.id)
                continue
            }

            // Check if this is an orphaned composite alarm (generated ID without parent ticker)
            if let parentTicker = alarmKitIDsToTicker[alarm.id] {
                // This alarm belongs to a known ticker
                alarmsToKeep.append(alarm)
            } else {
                // Check if this could be a legacy simple alarm
                if allItems.contains(where: { $0.id == alarm.id }) {
                    alarmsToKeep.append(alarm)
                } else {
                    print("🗑️ Canceling orphaned alarm: \(alarm.id)")
                    try? alarmManager.cancel(id: alarm.id)
                }
            }
        }

        print("✅ Kept \(alarmsToKeep.count) valid alarms")

        // 4. Update local TickerService state with valid alarms only
        for alarm in alarmsToKeep {
            // Look up metadata from SwiftData
            let ticker = alarmKitIDsToTicker[alarm.id] ?? allItems.first { $0.id == alarm.id }

            // If we have a ticker, use it; otherwise create a minimal one
            let tickerToUse: Ticker
            if let existingTicker = ticker {
                tickerToUse = existingTicker
            } else {
                tickerToUse = Ticker(
                    id: alarm.id,
                    label: "Alarm",
                    isEnabled: true
                )
                tickerToUse.alarmKitID = alarm.id
            }

            // Update local state
            await stateManager.updateState(ticker: tickerToUse)

            print("✅ Loaded alarm: \(tickerToUse.label)")
        }

        // 5. Ensure SwiftData entries exist for all AlarmKit alarms
        for alarm in alarmsToKeep {
            // If no SwiftData entry exists, create one
            if !allItems.contains(where: { $0.id == alarm.id || $0.generatedAlarmKitIDs.contains(alarm.id) }) {
                print("📝 Creating SwiftData entry for orphaned alarm: \(alarm.id)")

                let alarmItem = Ticker(
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
}
