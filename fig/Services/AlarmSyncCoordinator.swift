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

        // 2. Clean up template alarms that shouldn't be scheduled
        // Fetch all Tickers to check which ones are disabled templates
        let allItemsDescriptor = FetchDescriptor<Ticker>()
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
            await stateManager.updateState(from: alarm, label: LocalizedStringResource(stringLiteral: label))

            print("✅ Loaded alarm: \(label)")
        }

        // 4. Ensure SwiftData entries exist for all AlarmKit alarms
        // (This handles orphaned alarms that exist in AlarmKit but not SwiftData)
        for alarm in alarmsToKeep {
            // If no SwiftData entry exists, create one
            if !allItems.contains(where: { $0.id == alarm.id }) {
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
