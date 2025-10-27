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

        // 1. Fetch all alarms from AlarmKit (source of truth) via state manager
        let alarmKitAlarms: [Alarm]
        do {
            alarmKitAlarms = try stateManager.queryAlarmKit(alarmManager: alarmManager)
            print("⏰ Found \(alarmKitAlarms.count) alarms in AlarmKit")
        } catch {
            print("❌ Failed to fetch alarms from AlarmKit: \(error)")
            return
        }

        // 2. Fetch all Tickers from SwiftData
        let allItemsDescriptor = FetchDescriptor<Ticker>()
        let allItems = (try? context.fetch(allItemsDescriptor)) ?? []
        let disabledItemIds = Set(allItems.filter { !$0.isEnabled }.map { $0.id })

        // Build a map of all AlarmKit IDs (composite generated)
        var alarmKitIDsToTicker: [UUID: Ticker] = [:]
        for ticker in allItems {
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
                do {
                    try alarmManager.cancel(id: alarm.id)
                } catch {
                    print("⚠️ Failed to cancel disabled alarm \(alarm.id): \(error)")
                }
                continue
            }

            // Check if this is an orphaned alarm (generated ID without parent ticker)
            if let parentTicker = alarmKitIDsToTicker[alarm.id] {
                // This alarm belongs to a known ticker
                alarmsToKeep.append(alarm)
                print("✅ Keeping alarm \(alarm.id) (belongs to ticker: \(parentTicker.label))")
            } else {
                // Check if this could be a simple alarm (ticker ID matches alarm ID)
                if let simpleTicker = allItems.first(where: { $0.id == alarm.id }) {
                    alarmsToKeep.append(alarm)
                    print("✅ Keeping simple alarm \(alarm.id) (ticker: \(simpleTicker.label))")
                } else {
                    print("🗑️ Canceling orphaned alarm: \(alarm.id)")
                    do {
                        try alarmManager.cancel(id: alarm.id)
                    } catch {
                        print("⚠️ Failed to cancel orphaned alarm \(alarm.id): \(error)")
                    }
                }
            }
        }

        print("✅ Kept \(alarmsToKeep.count) valid Tickers")

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
                tickerToUse.generatedAlarmKitIDs = [alarm.id]
            }

            // Update local state
            await stateManager.updateState(ticker: tickerToUse)

            print("✅ Loaded alarm: \(tickerToUse.label)")
        }

        // 5. Ensure SwiftData entries exist for all AlarmKit alarms
        var newEntriesCreated = 0
        for alarm in alarmsToKeep {
            // If no SwiftData entry exists, create one
            if !allItems.contains(where: { $0.id == alarm.id || $0.generatedAlarmKitIDs.contains(alarm.id) }) {
                print("📝 Creating SwiftData entry for orphaned alarm: \(alarm.id)")

                let alarmItem = Ticker(
                    id: alarm.id,
                    label: "Alarm",
                    isEnabled: true
                )
                alarmItem.generatedAlarmKitIDs = [alarm.id]
                context.insert(alarmItem)
                newEntriesCreated += 1
            }
        }

        // Save any new entries
        if newEntriesCreated > 0 {
            do {
                try context.save()
                print("💾 Saved \(newEntriesCreated) new SwiftData entries")
            } catch {
                print("❌ Failed to save SwiftData entries: \(error)")
            }
        }

        print("✨ Alarm synchronization complete (\(alarmsToKeep.count) active alarms)")
    }
}
