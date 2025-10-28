//
//  AlarmSynchronizationService.swift
//  fig
//
//  Unified service for bidirectional synchronization between AlarmKit and SwiftData
//  Uses AlarmManager.alarms as the single source of truth
//
//  Design Principle:
//  - If a Ticker doesn't exist in SwiftData, its alarms shouldn't exist in AlarmKit
//  - If an alarm doesn't exist in AlarmKit, its Ticker shouldn't exist in SwiftData
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit
import AlarmKit

// MARK: - AlarmSynchronizationService Protocol

protocol AlarmSynchronizationServiceProtocol {
    func synchronize(
        alarmManager: AlarmManager,
        stateManager: AlarmStateManagerProtocol,
        context: ModelContext
    ) async
}

// MARK: - AlarmSynchronizationService Implementation

struct AlarmSynchronizationService: AlarmSynchronizationServiceProtocol {

    /// Performs full bidirectional synchronization between AlarmKit and SwiftData
    /// Uses AlarmManager.alarms as the single source of truth
    /// - Parameters:
    ///   - alarmManager: AlarmManager to query for active alarms
    ///   - stateManager: State manager to update
    ///   - context: SwiftData context for persistence
    func synchronize(
        alarmManager: AlarmManager,
        stateManager: AlarmStateManagerProtocol,
        context: ModelContext
    ) async {
        print("🔄 Starting unified alarm synchronization (AlarmKit ↔ SwiftData)...")

        // 1. Query AlarmManager.alarms (SOURCE OF TRUTH)
        let alarmKitAlarms: [Alarm]
        do {
            alarmKitAlarms = try stateManager.queryAlarmKit(alarmManager: alarmManager)
            print("⏰ Found \(alarmKitAlarms.count) alarms in AlarmManager")
        } catch {
            print("❌ Failed to fetch alarms from AlarmManager: \(error)")
            return
        }

        // 2. Fetch all Tickers from SwiftData
        let descriptor = FetchDescriptor<Ticker>()
        guard let allTickers = try? context.fetch(descriptor) else {
            print("❌ Failed to fetch Tickers from SwiftData")
            return
        }
        print("📋 Found \(allTickers.count) Tickers in SwiftData")

        // Build ID mappings
        let activeAlarmIDs = Set(alarmKitAlarms.map { $0.id })
        let disabledTickerIDs = Set(allTickers.filter { !$0.isEnabled }.map { $0.id })
        
        // Build map of AlarmKit IDs to Tickers (for composite schedules)
        var alarmKitIDsToTicker: [UUID: Ticker] = [:]
        for ticker in allTickers {
            for generatedID in ticker.generatedAlarmKitIDs {
                alarmKitIDsToTicker[generatedID] = ticker
            }
        }

        print("🔍 Active alarm IDs: \(activeAlarmIDs)")
        print("🚫 Disabled ticker IDs: \(disabledTickerIDs)")

        // CLEANUP ALARMKIT (AlarmManager → SwiftData)
        print("🧹 Cleaning up AlarmKit alarms...")
        var alarmsToKeep: [Alarm] = []
        var alarmsCancelled = 0

        for alarm in alarmKitAlarms {
            // Check if this alarm belongs to a disabled Ticker
            if disabledTickerIDs.contains(alarm.id) {
                print("🗑️ Canceling disabled ticker alarm: \(alarm.id)")
                do {
                    try alarmManager.cancel(id: alarm.id)
                    alarmsCancelled += 1
                } catch {
                    print("⚠️ Failed to cancel disabled alarm \(alarm.id): \(error)")
                }
                continue
            }

            // Check if this is an orphaned alarm (no Ticker exists)
            let hasTicker = alarmKitIDsToTicker[alarm.id] != nil || 
                           allTickers.contains { $0.id == alarm.id }
            
            if hasTicker {
                alarmsToKeep.append(alarm)
                print("✅ Keeping alarm \(alarm.id) (has valid Ticker)")
            } else {
                print("🗑️ Canceling orphaned alarm: \(alarm.id)")
                do {
                    try alarmManager.cancel(id: alarm.id)
                    alarmsCancelled += 1
                } catch {
                    print("⚠️ Failed to cancel orphaned alarm \(alarm.id): \(error)")
                }
            }
        }

        print("✅ Kept \(alarmsToKeep.count) valid alarms, cancelled \(alarmsCancelled) invalid alarms")

        // CLEANUP SWIFTDATA (SwiftData → AlarmManager)
        print("🧹 Cleaning up SwiftData Tickers...")
        var tickersToDelete: [Ticker] = []
        var tickersDeleted = 0

        for ticker in allTickers {
            // Check if this Ticker has ANY alarm in AlarmManager
            var hasActiveAlarm = false

            // Check main ticker ID
            if activeAlarmIDs.contains(ticker.id) {
                hasActiveAlarm = true
                print("✅ Ticker '\(ticker.displayName)' has main alarm \(ticker.id)")
            }

            // Check generated alarm IDs (for composite schedules)
            for generatedID in ticker.generatedAlarmKitIDs {
                if activeAlarmIDs.contains(generatedID) {
                    hasActiveAlarm = true
                    print("✅ Ticker '\(ticker.displayName)' has generated alarm \(generatedID)")
                    break
                }
            }

            // If no alarms found in AlarmManager, mark for deletion
            if !hasActiveAlarm {
                print("🗑️ Ticker '\(ticker.displayName)' (ID: \(ticker.id)) has NO alarms in AlarmManager - marking for deletion")
                print("    → Checked IDs: [\(ticker.id)] + generated: \(ticker.generatedAlarmKitIDs)")
                tickersToDelete.append(ticker)
            }
        }

        // Delete orphaned Tickers
        if !tickersToDelete.isEmpty {
            print("🗑️ Deleting \(tickersToDelete.count) orphaned Ticker(s)...")

            for ticker in tickersToDelete {
                // Remove from state manager
                stateManager.removeState(id: ticker.id)
                print("   → Removed '\(ticker.displayName)' from state manager")

                // Remove from SwiftData
                context.delete(ticker)
                print("   → Deleted '\(ticker.displayName)' from SwiftData")
                tickersDeleted += 1
            }
        }

        // FINALIZE
        print("💾 Finalizing synchronization...")

        // Update state manager with valid Tickers only
        for alarm in alarmsToKeep {
            // Look up the corresponding Ticker
            let ticker = alarmKitIDsToTicker[alarm.id] ?? allTickers.first { $0.id == alarm.id }
            
            if let ticker = ticker {
                await stateManager.updateState(ticker: ticker)
                print("✅ Updated state for Ticker: \(ticker.displayName)")
            }
        }

        // Save SwiftData changes
        do {
            try context.save()
            print("✅ SwiftData changes saved successfully")
        } catch {
            print("❌ Failed to save SwiftData changes: \(error)")
            return
        }

        // Refresh widgets
        await MainActor.run {
            WidgetCenter.shared.reloadAllTimelines()
        }
        print("🔄 Widgets refreshed")

        // Log summary
        print("✨ Synchronization complete:")
        print("   → Kept \(alarmsToKeep.count) valid alarms")
        print("   → Cancelled \(alarmsCancelled) invalid alarms")
        print("   → Deleted \(tickersDeleted) orphaned Tickers")
        print("   → Updated state manager with \(alarmsToKeep.count) Tickers")
    }
}
