//
//  AlarmMigrationV2.swift
//  fig
//
//  Handles migration from generationWindow to new regeneration system
//  Safe migration that preserves existing alarms and triggers gradual regeneration
//

import Foundation
import SwiftData

// MARK: - AlarmMigrationV2

class AlarmMigrationV2 {
    private static let migrationKey = "hasCompletedAlarmMigrationV2"

    // MARK: - Migration Status

    /// Check if migration has already been completed
    static var hasMigrated: Bool {
        UserDefaults.standard.bool(forKey: migrationKey)
    }

    /// Mark migration as completed
    static func markMigrationCompleted() {
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("✅ Migration V2 marked as completed")
    }

    // MARK: - Migration Execution

    /// Perform migration if needed
    /// - Parameter context: SwiftData model context
    /// - Returns: True if migration was performed, false if already completed
    @discardableResult
    static func migrateIfNeeded(context: ModelContext) async -> Bool {
        // Check if migration already completed
        if hasMigrated {
            print("ℹ️ Migration V2 already completed, skipping")
            return false
        }

        print("🚀 Starting Migration V2...")

        do {
            // Fetch all tickers
            let descriptor = FetchDescriptor<Ticker>()
            let allTickers = try context.fetch(descriptor)

            print("   → Found \(allTickers.count) tickers to migrate")

            // Migrate each ticker
            for ticker in allTickers {
                await migrateTicker(ticker: ticker)
            }

            // Save changes
            try context.save()
            print("   → SwiftData changes saved")

            // Mark migration as completed
            markMigrationCompleted()

            print("✅ Migration V2 completed successfully")
            return true

        } catch {
            print("❌ Migration V2 failed: \(error)")
            return false
        }
    }

    // MARK: - Private Migration Logic

    /// Migrate a single ticker from old to new system
    private static func migrateTicker(ticker: Ticker) async {
        print("   → Migrating ticker: \(ticker.displayName)")

        // Keep existing generatedAlarmKitIDs - DO NOT delete active alarms!
        // These alarms are already scheduled in AlarmKit and should continue working
        print("     • Preserving \(ticker.generatedAlarmKitIDs.count) existing alarm(s)")

        // Set lastRegenerationDate to nil to trigger health check
        // This will show the ticker as needing attention in the UI
        ticker.lastRegenerationDate = nil
        ticker.lastRegenerationSuccess = false
        ticker.nextScheduledRegeneration = nil
        print("     • Reset regeneration tracking")

        // Determine appropriate regeneration strategy based on schedule
        if let schedule = ticker.schedule {
            let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)
            ticker.regenerationStrategy = strategy
            print("     • Set regeneration strategy: \(strategy.displayName)")
        }

        // The ticker will be regenerated on next app foreground
        // This happens automatically via the app lifecycle triggers
        print("     • Ticker will regenerate on next app launch")
    }

    // MARK: - Force Regeneration After Migration

    /// Force regeneration of all tickers after migration
    /// Call this from the app lifecycle after migration completes
    static func forceRegenerateAllTickers(
        context: ModelContext,
        regenerationService: AlarmRegenerationService
    ) async {
        print("🔄 Force regenerating all tickers after migration...")

        do {
            let descriptor = FetchDescriptor<Ticker>(predicate: #Predicate<Ticker> { ticker in
                ticker.isEnabled == true
            })
            let enabledTickers = try context.fetch(descriptor)

            print("   → Found \(enabledTickers.count) enabled tickers")

            for ticker in enabledTickers {
                do {
                    // Force regeneration (bypass rate limiting)
                    try await regenerationService.regenerateAlarmsIfNeeded(
                        ticker: ticker,
                        context: context,
                        force: true
                    )
                    print("     ✓ Regenerated: \(ticker.displayName)")
                } catch {
                    print("     ✗ Failed to regenerate \(ticker.displayName): \(error)")
                }
            }

            print("✅ Post-migration regeneration completed")
        } catch {
            print("❌ Post-migration regeneration failed: \(error)")
        }
    }

    // MARK: - Reset Migration (For Testing)

    /// Reset migration flag (useful for testing)
    /// WARNING: Only use during development/testing
    static func resetMigration() {
        UserDefaults.standard.removeObject(forKey: migrationKey)
        print("⚠️ Migration V2 flag reset")
    }
}
