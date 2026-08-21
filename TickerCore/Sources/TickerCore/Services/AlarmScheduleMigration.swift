//
//  AlarmScheduleMigration.swift
//  TickerCore
//
//  One-shot upgrade path for tickers that were expanded into one-time alarms
//  before their schedule could be expressed natively.
//
//  Why this is not optional: once `.weekdays` maps to
//  `Alarm.Schedule.Relative.Recurrence.weekly`, `usesNativeAlarmKitSchedule`
//  returns true for those tickers, which makes `shouldRegenerate` false in
//  AlarmSynchronizationService. Existing users still hold a finite set of
//  expansion-generated `.fixed` alarms, and nothing would ever reschedule them —
//  `scheduleAlarm` is only reached from the create and edit flows. Their Mon-Fri
//  alarm would keep working until the old expansion ran out (at most seven days
//  for `.lowFrequency`) and then stop forever, silently.
//
//  Order matters: cancel first, verify, then schedule. Scheduling before
//  cancelling — or trusting a swallowed `try?` cancel — leaves the leftover
//  `.fixed` occurrence armed alongside the new recurrence, and the user gets two
//  alerts the same morning.
//

import Foundation
import SwiftData
import AlarmKit

public enum AlarmScheduleMigration {

    private static let versionKey = "alarmScheduleMigrationVersion"
    private static let currentVersion = 1

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: TickerSchema.appGroupIdentifier)
    }

    /// Migrates any ticker whose schedule is now natively expressible but which
    /// still holds expansion-generated one-time alarms.
    @MainActor
    public static func runIfNeeded(
        alarmManager: any AlarmScheduling,
        stateManager: AlarmStateManagerProtocol,
        configurationBuilder: AlarmConfigurationBuilderProtocol,
        context: ModelContext
    ) async {
        let completedVersion = defaults?.integer(forKey: versionKey) ?? 0
        guard completedVersion < currentVersion else { return }

        print("🔀 AlarmScheduleMigration: running v\(currentVersion)")

        guard let armed = try? stateManager.queryAlarmKit(alarmManager: alarmManager) else {
            print("   ⚠️ Could not read AlarmKit state - deferring migration")
            return
        }
        let armedByID = Dictionary(uniqueKeysWithValues: armed.map { ($0.id, $0) })

        let descriptor = FetchDescriptor<Ticker>()
        guard let tickers = try? context.fetch(descriptor) else {
            print("   ⚠️ Could not read tickers - deferring migration")
            return
        }

        var migrated = 0

        for ticker in tickers where ticker.isEnabled {
            guard ticker.usesNativeAlarmKitSchedule else { continue }

            // Only tickers still backed by expansion-generated `.fixed` alarms.
            let legacyIDs = ticker.generatedAlarmKitIDs.filter { id in
                if case .fixed = armedByID[id]?.schedule { return true }
                return false
            }
            guard !legacyIDs.isEmpty else { continue }

            print("   → Migrating '\(ticker.displayName)' (\(legacyIDs.count) expanded alarm(s))")

            // 1. Cancel every alarm this ticker owns.
            for id in ticker.generatedAlarmKitIDs {
                do {
                    try alarmManager.cancel(id: id)
                } catch {
                    print("     ⚠️ Failed to cancel \(id): \(error)")
                }
            }

            // 2. Verify they are actually gone before arming the replacement.
            //    A silently-failed cancel plus a new recurrence means two alerts.
            guard let remaining = try? stateManager.queryAlarmKit(alarmManager: alarmManager) else {
                print("     ⚠️ Could not re-read AlarmKit - skipping '\(ticker.displayName)'")
                continue
            }
            let stillArmed = Set(remaining.map(\.id)).intersection(ticker.generatedAlarmKitIDs)
            guard stillArmed.isEmpty else {
                print("     ⚠️ \(stillArmed.count) alarm(s) refused to cancel - skipping to avoid a double alert")
                continue
            }

            AlarmOccurrenceLog.remove(alarmIDs: ticker.generatedAlarmKitIDs)

            // 3. Arm one native recurring alarm.
            let newID = UUID()
            guard let configuration = configurationBuilder.buildConfiguration(
                from: ticker,
                occurrenceAlarmID: newID
            ) else {
                print("     ❌ Could not build a native configuration for '\(ticker.displayName)'")
                ticker.generatedAlarmKitIDs = []
                continue
            }

            do {
                _ = try await alarmManager.schedule(id: newID, configuration: configuration)
                ticker.generatedAlarmKitIDs = [newID]
                ticker.lastRegenerationDate = Date()
                ticker.lastRegenerationSuccess = true
                migrated += 1
                print("     ✅ Now using native recurrence (\(newID))")
            } catch {
                // The old alarms are already cancelled, so leave the ticker in a
                // state the regeneration path can pick up rather than pretending
                // it succeeded.
                print("     ❌ Failed to schedule native recurrence: \(error)")
                ticker.generatedAlarmKitIDs = []
                ticker.lastRegenerationSuccess = false
                AlarmTelemetry.record(.alarmScheduleFailed(reason: "weekday_migration_failed"))
            }
        }

        do {
            try context.save()
            // Only record completion once the writes are durable, so a crash
            // mid-migration means it runs again rather than being skipped.
            defaults?.set(currentVersion, forKey: versionKey)
            print("🔀 AlarmScheduleMigration complete: \(migrated) ticker(s) migrated")
        } catch {
            print("   ❌ Failed to save migration results: \(error)")
        }
    }
}
