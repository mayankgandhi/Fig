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

public protocol AlarmSynchronizationServiceProtocol {
    /// `@MainActor` is load-bearing, not decoration. `ModelContext` is not
    /// thread-safe, and the context passed here is created on the main actor and
    /// read concurrently by `@Query` in SwiftUI views. This used to be a
    /// nonisolated `async` requirement awaited from a `@MainActor` caller, which
    /// meant the whole reconciliation — fetch, mutate, delete, save — ran off the
    /// main actor against a main-actor context. That is a data race.
    @MainActor
    func synchronize(
        alarmManager: any AlarmScheduling,
        stateManager: AlarmStateManagerProtocol,
        context: ModelContext
    ) async
}

// MARK: - AlarmSynchronizationService Implementation

public struct AlarmSynchronizationService: AlarmSynchronizationServiceProtocol {

    public init() {
    
    }

    /// Performs full bidirectional synchronization between AlarmKit and SwiftData
    /// Uses AlarmManager.alarms as the single source of truth
    /// - Parameters:
    ///   - alarmManager: Scheduler to query for active alarms
    ///   - stateManager: State manager to update
    ///   - context: SwiftData context for persistence
    @MainActor
    public func synchronize(
        alarmManager: any AlarmScheduling,
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
        
        // Build map of AlarmKit IDs to Tickers (for collection schedules)
        var alarmKitIDsToTicker: [UUID: Ticker] = [:]
        for ticker in allTickers {
            print("🔍 Ticker '\(ticker.label)' (ID: \(ticker.id)) has generatedAlarmKitIDs: \(ticker.generatedAlarmKitIDs)")
            print("   → Schedule: \(String(describing: ticker.schedule))")
            print("   → Enabled: \(ticker.isEnabled)")
            for generatedID in ticker.generatedAlarmKitIDs {
                alarmKitIDsToTicker[generatedID] = ticker
            }
        }

        print("🔍 Active alarm IDs: \(activeAlarmIDs)")
        print("🚫 Disabled ticker IDs: \(disabledTickerIDs)")
        print("🔍 alarmKitIDsToTicker mapping has \(alarmKitIDsToTicker.count) entries")

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
            let hasTickerInMapping = alarmKitIDsToTicker[alarm.id] != nil
            let hasTickerByMainID = allTickers.contains { $0.id == alarm.id }
            let hasTicker = hasTickerInMapping || hasTickerByMainID
            
            if hasTicker {
                alarmsToKeep.append(alarm)
                if hasTickerInMapping {
                    print(
                        "✅ Keeping alarm \(alarm.id) \(alarm.alertingTime) (found in generatedAlarmKitIDs mapping)"
                    )
                } else if hasTickerByMainID {
                    print("✅ Keeping alarm \(alarm.id) (matches main ticker ID)")
                }
            } else {
                print("🗑️ Canceling orphaned alarm: \(alarm.id) (no matching ticker found)")
                do {
                    try alarmManager.cancel(id: alarm.id)
                    alarmsCancelled += 1
                } catch {
                    print("⚠️ Failed to cancel orphaned alarm \(alarm.id): \(error)")
                }
            }
        }

        print("✅ Kept \(alarmsToKeep.count) valid alarms, cancelled \(alarmsCancelled) invalid alarms")

        // CLEANUP GENERATED ALARM IDs FROM TICKERS
        print("🧹 Cleaning up stopped alarm IDs from ticker generatedAlarmKitIDs...")
        let activeAlarmIDsSet = Set(alarmKitAlarms.map { $0.id })
        var tickersUpdated = 0
        
        for ticker in allTickers {
            let originalCount = ticker.generatedAlarmKitIDs.count
            ticker.generatedAlarmKitIDs = ticker.generatedAlarmKitIDs.filter { activeAlarmIDsSet.contains($0) }
            let newCount = ticker.generatedAlarmKitIDs.count
            
            if originalCount != newCount {
                print("🧹 Cleaned up \(originalCount - newCount) stopped alarm IDs from ticker '\(ticker.label)'")
                print("   → Remaining generatedAlarmKitIDs: \(ticker.generatedAlarmKitIDs)")
                tickersUpdated += 1
            }
        }
        
        if tickersUpdated > 0 {
            print("✅ Updated \(tickersUpdated) tickers with cleaned generatedAlarmKitIDs")
        }

        // RECONCILE SWIFTDATA (SwiftData → AlarmManager)
        //
        // Reconciliation NEVER deletes a user-created Ticker. A one-time alarm that
        // has already fired has no live AlarmKit alarm and no future occurrence,
        // which used to match the deletion predicate exactly — so the app silently
        // destroyed the user's alarm the first time it went off. Those tickers are
        // now retired (switched off, kept in the list) the way the system Clock app
        // switches off a one-time alarm after it rings.
        print("🧹 Reconciling SwiftData Tickers...")
        var tickersToRetire: [Ticker] = []
        var tickersRetired = 0

        for ticker in allTickers {
            // Check if this Ticker has ANY alarm in AlarmManager
            var hasActiveAlarm = false

            // Check main ticker ID
            if activeAlarmIDs.contains(ticker.id) {
                hasActiveAlarm = true
                print("✅ Ticker '\(ticker.displayName)' has main alarm \(ticker.id)")
            }

            // Check generated alarm IDs (for collection schedules)
            for generatedID in ticker.generatedAlarmKitIDs {
                if activeAlarmIDs.contains(generatedID) {
                    hasActiveAlarm = true
                    print("✅ Ticker '\(ticker.displayName)' has generated alarm \(generatedID)")
                    break
                }
            }

            // Preserve disabled tickers - they should remain in SwiftData even without active alarms
            // (their alarms are cancelled separately, but the ticker entity persists)
            if !ticker.isEnabled {
                print("✅ Ticker '\(ticker.displayName)' is disabled - preserving (alarm cancellation handled separately)")
                continue
            }

            // If no alarms found in AlarmManager, check if this ticker has upcoming alarms
            // or should be regenerated rather than deleted
            if !hasActiveAlarm {
                // Check if this Ticker has upcoming alarms scheduled
                var hasUpcomingAlarms = false
                if let schedule = ticker.schedule, ticker.isEnabled {
                    let expander = TickerScheduleExpander()
                    // Check for alarms in the next year (to catch annual alarms)
                    let oneYear: TimeInterval = 365 * 24 * 3600
                    let now = Date()
                    let upcomingDates = expander.expandSchedule(
                        schedule,
                        withinCustomWindow: now,
                        duration: oneYear,
                        maxAlarms: 1
                    )
                    hasUpcomingAlarms = !upcomingDates.isEmpty

                    if hasUpcomingAlarms {
                        let nextAlarm = upcomingDates[0]
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .short
                        print("📅 Ticker '\(ticker.displayName)' has next alarm at \(formatter.string(from: nextAlarm)) - keeping")
                    } else {
                        // Debug logging for schedules that have no upcoming alarms
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .short
                        let windowEnd = now.addingTimeInterval(oneYear)
                        
                        if case .oneTime(let date) = schedule {
                            print("⚠️ One-time ticker '\(ticker.displayName)' date \(formatter.string(from: date)) not in window (now: \(formatter.string(from: now)) to \(formatter.string(from: windowEnd)))")
                        } else if case .yearly(let month, let day, let time) = schedule {
                            print("⚠️ Yearly ticker '\(ticker.displayName)' (month: \(month), day: \(day), time: \(time.hour):\(String(format: "%02d", time.minute))) has no upcoming alarms in window")
                            print("   → Window: \(formatter.string(from: now)) to \(formatter.string(from: windowEnd))")
                            print("   → ExpandSchedule returned \(upcomingDates.count) dates")
                            // Log what expandSchedule actually found
                            let allDates = expander.expandSchedule(
                                schedule,
                                withinCustomWindow: now,
                                duration: oneYear,
                                maxAlarms: nil
                            )
                            print("   → ExpandSchedule (no max limit) found \(allDates.count) dates:")
                            for date in allDates {
                                print("      - \(formatter.string(from: date))")
                            }
                        }
                    }
                }

                let shouldRegenerate = ticker.isEnabled &&
                                     ticker.schedule != nil &&
                                     !ticker.usesNativeAlarmKitSchedule &&
                                     ticker.needsRegeneration

                if hasUpcomingAlarms {
                    // Future alarms are scheduled - leave it alone
                } else if shouldRegenerate {
                    print("🔄 Ticker '\(ticker.displayName)' has no active alarms but needs regeneration - keeping for regeneration")
                    // Let the regeneration service handle it
                } else {
                    print("🌙 Ticker '\(ticker.displayName)' (ID: \(ticker.id)) has no alarms left - retiring (switching off, NOT deleting)")
                    print("    → Checked IDs: [\(ticker.id)] + generated: \(ticker.generatedAlarmKitIDs)")
                    tickersToRetire.append(ticker)
                }
            }
        }

        // Retire spent Tickers. Deliberately NOT context.delete — user-created rows
        // are never destroyed by reconciliation. `Ticker.parentTickerCollection` is
        // the inverse of a `.cascade` relationship, so a single delete here could
        // also take out a whole collection.
        if !tickersToRetire.isEmpty {
            print("🌙 Retiring \(tickersToRetire.count) spent Ticker(s)...")

            for ticker in tickersToRetire {
                ticker.isEnabled = false
                ticker.generatedAlarmKitIDs = []
                print("   → Retired '\(ticker.displayName)' (kept in SwiftData)")

                tickersRetired += 1
            }
        }

        // FINALIZE
        print("💾 Finalizing synchronization...")

        // Save SwiftData changes
        do {
            try context.save()
            print("✅ SwiftData changes saved successfully")
        } catch {
            print("❌ Failed to save SwiftData changes: \(error)")
            return
        }

        // Refresh widgets asynchronously to avoid blocking
        Task.detached(priority: .utility) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        print("🔄 Widgets refresh initiated")

        // Log summary
        print("✨ Synchronization complete:")
        print("   → Kept \(alarmsToKeep.count) valid alarms")
        print("   → Cancelled \(alarmsCancelled) invalid alarms")
        print("   → Retired \(tickersRetired) spent Tickers (none deleted)")
        print("   → Tickers in SwiftData: \(allTickers.count)")
    }
    
}
