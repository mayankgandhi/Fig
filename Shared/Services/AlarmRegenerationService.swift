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

// MARK: - RegenerationTrigger

enum RegenerationTrigger {
    case appForeground       // App entered foreground (PRIMARY - guaranteed)
    case backgroundTask      // Daily background task (best effort)
    case timeZoneChange      // System time zone changed
    case manualRefresh       // User-initiated refresh
    case lowAlarmCount       // Detected low alarm count
    case scheduled           // Scheduled regeneration time reached
}

// MARK: - AlarmRegenerationServiceProtocol

protocol AlarmRegenerationServiceProtocol {
    func regenerateAlarmsIfNeeded(
        ticker: Ticker,
        context: ModelContext,
        force: Bool
    ) async throws

    func shouldRegenerate(ticker: Ticker) -> Bool
    func calculateAlarmHealth(ticker: Ticker) async -> AlarmHealth
}

// MARK: - AlarmRegenerationService

@Observable
class AlarmRegenerationService: AlarmRegenerationServiceProtocol {
    // Dependencies
    private let alarmManager: AlarmManager
    private let scheduleExpander: TickerScheduleExpanderProtocol
    private let rateLimiter: RegenerationRateLimiter
    private let configurationBuilder: AlarmConfigurationBuilderProtocol
    private let stateManager: AlarmStateManagerProtocol

    // MARK: - Initialization

    init(
        alarmManager: AlarmManager = .shared,
        scheduleExpander: TickerScheduleExpanderProtocol = TickerScheduleExpander(),
        rateLimiter: RegenerationRateLimiter = .shared,
        configurationBuilder: AlarmConfigurationBuilderProtocol = AlarmConfigurationBuilder(),
        stateManager: AlarmStateManagerProtocol = AlarmStateManager()
    ) {
        self.alarmManager = alarmManager
        self.scheduleExpander = scheduleExpander
        self.rateLimiter = rateLimiter
        self.configurationBuilder = configurationBuilder
        self.stateManager = stateManager
    }

    // MARK: - Regeneration Logic

    /// Main entry point for alarm regeneration
    /// - Parameters:
    ///   - ticker: The ticker to regenerate alarms for
    ///   - context: SwiftData model context
    ///   - force: If true, bypass rate limiting and regeneration checks
    func regenerateAlarmsIfNeeded(
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
        guard force || rateLimiter.canRegenerate(ticker: ticker, force: force) else {
            let remaining = rateLimiter.timeUntilNextAllowedRegeneration(for: ticker)
            print("   ⏸ Rate limited (retry in \(Int(remaining))s)")
            return
        }

        print("   → Proceeding with regeneration...")

        do {
            try await regenerateAlarms(ticker: ticker, context: context)
            rateLimiter.recordRegeneration(for: ticker)
            print("   ✅ Regeneration successful")
        } catch {
            print("   ❌ Regeneration failed: \(error)")
            throw error
        }
    }

    /// Check if a ticker needs regeneration
    /// - Parameter ticker: The ticker to check
    /// - Returns: True if regeneration is needed
    func shouldRegenerate(ticker: Ticker) -> Bool {
        // Use ticker's built-in logic
        return ticker.needsRegeneration
    }

    /// Calculate the current alarm health for a ticker
    /// - Parameter ticker: The ticker to evaluate
    /// - Returns: AlarmHealth status
    func calculateAlarmHealth(ticker: Ticker) async -> AlarmHealth {
        // Query AlarmKit for actual alarm count
        let activeCount = await queryActiveAlarmCount(for: ticker)

        return AlarmHealth(
            lastRegenerationDate: ticker.lastRegenerationDate,
            lastRegenerationSuccess: ticker.lastRegenerationSuccess,
            activeAlarmCount: activeCount
        )
    }

    // MARK: - Private: Core Regeneration

    /// Perform diff-based atomic alarm regeneration
    private func regenerateAlarms(ticker: Ticker, context: ModelContext) async throws {
        guard let schedule = ticker.schedule else {
            throw TickerServiceError.invalidConfiguration
        }

        print("   → Querying current AlarmKit state...")
        let currentAlarms = try await queryCurrentAlarms(for: ticker)
        print("   → Current alarms: \(currentAlarms.count)")

        print("   → Calculating target alarm state...")
        let targetDates = calculateTargetDates(schedule: schedule, strategy: ticker.regenerationStrategy)
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

        // Update ticker state on success
        print("   → Updating ticker state...")
        await MainActor.run {
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
    }

    /// Query current alarms from AlarmKit
    private func queryCurrentAlarms(for ticker: Ticker) async throws -> [(id: UUID, date: Date)] {
        var result: [(UUID, Date)] = []

        // Get all alarms from AlarmKit via state manager
        let allAlarms = try stateManager.queryAlarmKit(alarmManager: alarmManager)

        // Filter to only this ticker's alarms
        let tickerAlarmIDs = Set(ticker.generatedAlarmKitIDs)

        for alarm in allAlarms {
            // Only include alarms that belong to this ticker
            if tickerAlarmIDs.contains(alarm.id) {
                // Extract date from alarm configuration
                if case .fixed(let date) = alarm.schedule {
                    result.append((alarm.id, date))
                }
            }
        }

        return result
    }

    /// Calculate target alarm dates based on schedule and strategy
    private func calculateTargetDates(schedule: TickerSchedule, strategy: AlarmGenerationStrategy) -> [Date] {
        let now = Date()
        return scheduleExpander.expandSchedule(schedule, from: now, strategy: strategy)
    }

    /// Compute diff between current and target alarm states
    private func computeDiff(
        currentAlarms: [(id: UUID, date: Date)],
        targetDates: [Date],
        ticker: Ticker
    ) -> (toDelete: [UUID], toAdd: [Date]) {
        let currentDates = Set(currentAlarms.map { $0.date })
        let targetDatesSet = Set(targetDates)

        // Find alarms to delete (in current but not in target)
        let toDelete = currentAlarms
            .filter { !targetDatesSet.contains($0.date) }
            .map { $0.id }

        // Find alarms to add (in target but not in current)
        let toAdd = targetDates.filter { !currentDates.contains($0) }

        return (toDelete, toAdd)
    }

    /// Execute alarm changes atomically
    private func executeAtomicTransaction(
        ticker: Ticker,
        toDelete: [UUID],
        toAdd: [Date]
    ) async throws -> [UUID] {
        var newIDs: [UUID] = []
        var rollbackIDs: [UUID] = []

        do {
            // Delete stale alarms
            for alarmID in toDelete {
                try await alarmManager.cancel(id: alarmID)
                print("     → Deleted alarm \(alarmID)")
            }

            // Add new alarms
            for date in toAdd {
                let alarmID = UUID()
                let oneTimeSchedule = TickerSchedule.oneTime(date: date)
                let tempTicker = createTemporaryTicker(from: ticker, with: oneTimeSchedule)

                guard let configuration = configurationBuilder.buildConfiguration(from: tempTicker, occurrenceAlarmID: alarmID) else {
                    throw TickerServiceError.invalidConfiguration
                }

                try await alarmManager.schedule(id: alarmID, configuration: configuration)
                newIDs.append(alarmID)
                rollbackIDs.append(alarmID)
                print("     → Added alarm \(alarmID) for \(date)")
            }

            // Keep existing valid alarms
            let currentIDs = ticker.generatedAlarmKitIDs
            let validIDs = currentIDs.filter { !toDelete.contains($0) }
            newIDs = validIDs + newIDs

            return newIDs

        } catch {
            // Rollback: delete any newly created alarms
            print("     ⚠️ Transaction failed, rolling back...")
            for alarmID in rollbackIDs {
                try? await alarmManager.cancel(id: alarmID)
            }
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Query the count of active alarms from AlarmKit
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
