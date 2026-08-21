//
//  AlarmRegenerationService.swift
//  fig
//
//  Service for coordinating alarm regeneration with multiple triggers
//  Implements diff-based atomic regeneration with health monitoring
//

import Foundation
import SwiftData
import AlarmKit
import Factory

// MARK: - RegenerationTrigger

public enum RegenerationTrigger {
    case appForeground       // App entered foreground (PRIMARY - guaranteed)
    case backgroundTask      // Daily background task (best effort)
    case timeZoneChange      // System time zone changed
    case manualRefresh       // User-initiated refresh
    case lowAlarmCount       // Detected low alarm count
    case scheduled           // Scheduled regeneration time reached
}

// MARK: - AlarmRegenerationServiceProtocol

public protocol AlarmRegenerationServiceProtocol {
    /// `@MainActor` for the same reason as `AlarmSynchronizationService`: this
    /// reads and writes SwiftData models through a main-actor `ModelContext`.
    /// Splitting isolation mid-operation (reading `generatedAlarmKitIDs` off-main
    /// and writing it inside `MainActor.run`) was last-writer-wins against the
    /// launch sync running concurrently over a second context.
    @MainActor
    func regenerateAlarmsIfNeeded(
        ticker: Ticker,
        context: ModelContext,
        force: Bool
    ) async throws

    func shouldRegenerate(ticker: Ticker) -> Bool
}

// MARK: - AlarmRegenerationService

@Observable
public class AlarmRegenerationService: AlarmRegenerationServiceProtocol {
    // Dependencies
    @ObservationIgnored
    @Injected(\.alarmManager) private var alarmManager
    @ObservationIgnored
    @Injected(\.tickerScheduleExpander) private var scheduleExpander
    @ObservationIgnored
    @Injected(\.regenerationRateLimiter) private var rateLimiter
    @ObservationIgnored
    @Injected(\.alarmConfigurationBuilder) private var configurationBuilder
    @ObservationIgnored
    @Injected(\.alarmStateManager) private var stateManager

    // MARK: - Initialization

    public init() {
        // Dependencies auto-injected via @Injected
    }

    // MARK: - Regeneration Logic

    /// Main entry point for alarm regeneration
    /// - Parameters:
    ///   - ticker: The ticker to regenerate alarms for
    ///   - context: SwiftData model context
    ///   - force: If true, bypass rate limiting and regeneration checks
    @MainActor
    public func regenerateAlarmsIfNeeded(
        ticker: Ticker,
        context: ModelContext,
        force: Bool = false
    ) async throws {
        print("🔄 RegenerationService: Evaluating \(ticker.displayName)")

        // Check if regeneration is needed (unless forced)
        guard force || shouldRegenerate(ticker: ticker) else {
            print("   ✓ No regeneration needed")
            return
        }

        // Check rate limiting (unless forced)
        guard force || rateLimiter.canRegenerate(tickerID: ticker.id, force: force) else {
            let remaining = rateLimiter.timeUntilNextAllowedRegeneration(for: ticker.id)
            print("   ⏸ Rate limited (retry in \(Int(remaining))s)")
            return
        }

        print("   → Proceeding with regeneration...")

        do {
            try await regenerateAlarms(ticker: ticker, context: context)
            rateLimiter.recordRegeneration(for: ticker.id)
            print("   ✅ Regeneration successful")
        } catch {
            print("   ❌ Regeneration failed: \(error)")
            throw error
        }
    }

    /// Check if a ticker needs regeneration
    /// - Parameter ticker: The ticker to check
    /// - Returns: True if regeneration is needed
    public func shouldRegenerate(ticker: Ticker) -> Bool {
        // Use ticker's built-in logic
        return ticker.needsRegeneration
    }

    // MARK: - Private: Core Regeneration

    /// Perform diff-based atomic alarm regeneration
    @MainActor
    private func regenerateAlarms(ticker: Ticker, context: ModelContext) async throws {
        guard let schedule = ticker.schedule else {
            throw TickerServiceError.invalidConfiguration
        }

        print("   → Querying current AlarmKit state...")
        let currentAlarms = try await queryCurrentAlarms(for: ticker)
        print("   → Current alarms: \(currentAlarms.count)")

        print("   → Calculating target alarm state...")
        let targetDates = calculateTargetDates(schedule: schedule, strategy: ticker.regenerationStrategy, ticker: ticker)
        print("   → Target alarms: \(targetDates.count)")

        print("   → Computing diff...")
        let (toDelete, toAdd) = computeDiff(
            currentAlarms: currentAlarms,
            targetDates: targetDates,
            ticker: ticker
        )
        print("   → Diff: Delete \(toDelete.count), Add \(toAdd.count)")

        // Execute changes atomically
        print("   → Executing atomic transaction...")
        let newIDs = try await executeAtomicTransaction(
            ticker: ticker,
            toDelete: toDelete,
            toAdd: toAdd
        )

        // Update ticker state on success. Already on the main actor, so the
        // previous `MainActor.run` hop (which split this operation's isolation in
        // half) is gone.
        print("   → Updating ticker state...")
        ticker.generatedAlarmKitIDs = newIDs
        ticker.lastRegenerationDate = Date()
        ticker.lastRegenerationSuccess = true
        ticker.nextScheduledRegeneration = calculateNextRegenerationDate(for: ticker)

        do {
            try context.save()
            print("   → SwiftData saved")
        } catch {
            print("   ⚠️ Failed to save context: \(error)")
        }
    }

    /// Query current alarms from AlarmKit
    @MainActor
    private func queryCurrentAlarms(for ticker: Ticker) async throws -> [(id: UUID, date: Date)] {
        var result: [(UUID, Date)] = []

        // Get all alarms from AlarmKit via state manager
        let allAlarms = try stateManager.queryAlarmKit(alarmManager: alarmManager)

        // Filter to only this ticker's alarms
        let tickerAlarmIDs = Set(ticker.generatedAlarmKitIDs)

        // Alarms are scheduled with the pre-alert already subtracted, but the
        // expander produces un-shifted alert times. Add the offset back so both
        // sides of the diff are in the same units — otherwise the intersection is
        // always empty and every regeneration cancels and recreates every alarm.
        let preAlert = ticker.countdown?.preAlert?.interval ?? 0

        for alarm in allAlarms where tickerAlarmIDs.contains(alarm.id) {
            switch alarm.schedule {
            case .fixed(let date):
                result.append((alarm.id, date.addingTimeInterval(preAlert)))
            case .relative:
                // Natively recurring alarms are not produced by expansion and must
                // not be considered stale by the diff below.
                continue
            case .none:
                continue
            @unknown default:
                continue
            }
        }

        return result
    }

    /// Calculate target alarm dates based on schedule and strategy
    /// Uses lastRegenerationDate to prevent duplicate alarm creation
    private func calculateTargetDates(schedule: TickerSchedule, strategy: AlarmGenerationStrategy, ticker: Ticker) -> [Date] {
        // Always expand from now.
        //
        // This used to start from `ticker.lastRegenerationDate ?? Date()`. After
        // the first successful pass that value is by definition in the past, and
        // it was reused as the origin on every subsequent run — so the target
        // window never advanced with wall-clock time. Deduplication is
        // `computeDiff`'s job, not the origin's.
        scheduleExpander.expandSchedule(schedule, from: Date(), strategy: strategy)
    }

    /// Compute diff between current and target alarm states
    private func computeDiff(
        currentAlarms: [(id: UUID, date: Date)],
        targetDates: [Date],
        ticker: Ticker
    ) -> (toDelete: [UUID], toAdd: [Date]) {
        // Compare with a tolerance rather than by exact `Date` equality. These
        // dates make a round trip through AlarmKit and back, and sub-second drift
        // would make every alarm look stale.
        let tolerance: TimeInterval = 1

        func matches(_ lhs: Date, _ rhs: Date) -> Bool {
            abs(lhs.timeIntervalSince(rhs)) < tolerance
        }

        // Find alarms to delete (in current but not in target)
        let toDelete = currentAlarms
            .filter { current in !targetDates.contains { matches($0, current.date) } }
            .map { $0.id }

        // Find alarms to add (in target but not in current)
        let toAdd = targetDates.filter { target in
            !currentAlarms.contains { matches($0.date, target) }
        }

        return (toDelete, toAdd)
    }

    /// Execute alarm changes atomically
    @MainActor
    private func executeAtomicTransaction(
        ticker: Ticker,
        toDelete: [UUID],
        toAdd: [Date]
    ) async throws -> [UUID] {
        var addedIDs: [UUID] = []

        // Pre-flight budget check. Trimming here — with a log and a telemetry
        // event — is much better than letting AlarmKit throw
        // `maximumLimitReached` part-way through and silently arming nothing.
        var toAdd = toAdd
        let globalCount = (try? stateManager.queryAlarmKit(alarmManager: alarmManager).count) ?? 0
        let survivingTickerCount = ticker.generatedAlarmKitIDs.filter { !toDelete.contains($0) }.count
        let allowance = AlarmBudget.allowance(
            currentGlobalCount: globalCount - toDelete.count,
            currentTickerCount: survivingTickerCount
        )

        if toAdd.count > allowance {
            print("   ⚠️ Alarm budget: trimming \(toAdd.count) requested alarms to \(allowance)")
            print("      → \(globalCount) armed globally, limit \(AlarmBudget.maxScheduledAlarms)")
            AlarmTelemetry.record(
                .alarmBudgetExhausted(scheduled: globalCount, limit: AlarmBudget.maxScheduledAlarms)
            )
            toAdd = Array(toAdd.prefix(allowance))
        }

        do {
            // ADD FIRST, THEN DELETE.
            //
            // The previous order cancelled the stale alarms up front and the catch
            // block only undid the *newly created* ones — so a mid-transaction
            // failure (AlarmError.maximumLimitReached is the realistic case) left
            // the ticker with zero alarms and no way to get them back. Scheduling
            // first means a failure costs nothing: we cancel only our own work and
            // the user's existing alarms are still armed.
            for date in toAdd {
                let alarmID = UUID()
                let oneTimeSchedule = TickerSchedule.oneTime(date: date)
                let tempTicker = createTemporaryTicker(from: ticker, with: oneTimeSchedule)

                guard let configuration = configurationBuilder.buildConfiguration(from: tempTicker, occurrenceAlarmID: alarmID) else {
                    throw TickerServiceError.invalidConfiguration
                }

                let _ = try await alarmManager.schedule(id: alarmID, configuration: configuration)
                addedIDs.append(alarmID)
                // Record the occurrence so a fire can be inferred at next launch.
                AlarmOccurrenceLog.record(alarmID: alarmID, fireDate: date)
                print("     → Added alarm \(alarmID) for \(date)")
            }

            // Every add succeeded, so it is now safe to retire the stale alarms.
            // A cancel that fails is not fatal — the next sync reconciles it — and
            // must not roll back the adds we just committed.
            for alarmID in toDelete {
                do {
                    try alarmManager.cancel(id: alarmID)
                    print("     → Deleted alarm \(alarmID)")
                } catch {
                    print("     ⚠️ Could not cancel stale alarm \(alarmID): \(error)")
                }
            }

            let survivingIDs = ticker.generatedAlarmKitIDs.filter { !toDelete.contains($0) }
            return survivingIDs + addedIDs

        } catch {
            // Roll back only what this transaction created.
            print("     ⚠️ Transaction failed, rolling back \(addedIDs.count) new alarm(s)...")
            for alarmID in addedIDs {
                try? alarmManager.cancel(id: alarmID)
            }

            if let alarmError = error as? AlarmManager.AlarmError, alarmError == .maximumLimitReached {
                // Previously unhandled anywhere in the app. Name it explicitly so
                // the failure is attributable instead of looking like a generic
                // scheduling error.
                print("     ❌ AlarmKit reported maximumLimitReached")
                AlarmTelemetry.record(
                    .alarmBudgetExhausted(scheduled: globalCount, limit: AlarmBudget.maxScheduledAlarms)
                )
            } else {
                AlarmTelemetry.record(.alarmScheduleFailed(reason: "regeneration_transaction_failed"))
            }

            throw error
        }
    }

    // MARK: - Helper Methods

    /// Query the count of active alarms from AlarmKit
    @MainActor
    private func queryActiveAlarmCount(for ticker: Ticker) async -> Int {
        // Get all alarms from AlarmKit via state manager
        guard let allAlarms = try? stateManager.queryAlarmKit(alarmManager: alarmManager) else {
            // If we can't get alarms, return 0
            return 0
        }

        // Filter to only this ticker's alarms
        let tickerAlarmIDs = Set(ticker.generatedAlarmKitIDs)

        return allAlarms.filter { tickerAlarmIDs.contains($0.id) }.count
    }

    /// Calculate when the next regeneration should occur
    private func calculateNextRegenerationDate(for ticker: Ticker) -> Date {
        let strategy = ticker.regenerationStrategy

        // Schedule next regeneration at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let midnight = calendar.startOfDay(for: tomorrow)

        return midnight
    }

    /// Create a temporary ticker with a different schedule
    private func createTemporaryTicker(from ticker: Ticker, with schedule: TickerSchedule) -> Ticker {
        let temp = Ticker(
            id: ticker.id,
            label: ticker.label,
            isEnabled: ticker.isEnabled,
            schedule: schedule,
            countdown: ticker.countdown,
            presentation: ticker.presentation,
            tickerData: ticker.tickerData
        )
        return temp
    }
}
