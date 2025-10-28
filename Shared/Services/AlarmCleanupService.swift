//
//  AlarmCleanupService.swift
//  fig
//
//  Service for cleaning up stale alarms that have no future occurrences
//  Removes one-time alarms after they fire and recurring alarms with no future dates
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit

// MARK: - AlarmCleanupService Protocol

protocol AlarmCleanupServiceProtocol {
    func cleanupStaleAlarms(
        stateManager: AlarmStateManagerProtocol,
        context: ModelContext
    ) async -> Int
}

// MARK: - AlarmCleanupService Implementation

struct AlarmCleanupService: AlarmCleanupServiceProtocol {

    /// Removes alarms that have no future occurrences
    /// - Parameters:
    ///   - stateManager: State manager to update
    ///   - context: SwiftData context for persistence
    /// - Returns: Number of alarms cleaned up
    func cleanupStaleAlarms(
        stateManager: AlarmStateManagerProtocol,
        context: ModelContext
    ) async -> Int {
        print("🧹 Starting stale alarm cleanup...")

        let now = Date()
        let calendar = Calendar.current
        let expander = TickerScheduleExpander(calendar: calendar)

        // Fetch all alarms from SwiftData
        let descriptor = FetchDescriptor<Ticker>()
        guard let allAlarms = try? context.fetch(descriptor) else {
            print("❌ Failed to fetch alarms for cleanup")
            return 0
        }

        var alarmsToDelete: [Ticker] = []

        for alarm in allAlarms {
            // Skip if alarm doesn't have a schedule
            guard let schedule = alarm.schedule else {
                continue
            }

            // Check if alarm has any future occurrences within next 24 hours
            let timeWindow = now.addingTimeInterval(24 * 60 * 60)
            let window = DateInterval(start: now, end: timeWindow)
            let futureOccurrences = expander.expandSchedule(schedule, within: window)

            // If no future occurrences, mark for deletion
            if futureOccurrences.isEmpty {
                print("🗑️  Marking stale alarm for deletion: \(alarm.displayName) (ID: \(alarm.id))")
                alarmsToDelete.append(alarm)
            }
        }

        // Delete stale alarms
        let deleteCount = alarmsToDelete.count

        if deleteCount > 0 {
            print("🗑️  Deleting \(deleteCount) stale alarm(s)...")

            for alarm in alarmsToDelete {
                // Remove from state manager
                stateManager.removeState(id: alarm.id)

                // Remove from SwiftData
                context.delete(alarm)
            }

            // Save changes
            do {
                try context.save()
                print("✅ Successfully cleaned up \(deleteCount) stale alarm(s)")

                // Reload widgets to reflect cleanup
                await MainActor.run {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                print("🔄 Widgets refreshed after cleanup")

            } catch {
                print("❌ Failed to save cleanup changes: \(error)")
                return 0
            }
        } else {
            print("✨ No stale alarms found - all alarms are current")
        }

        return deleteCount
    }
}
