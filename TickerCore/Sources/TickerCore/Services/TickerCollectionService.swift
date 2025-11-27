//
//  TickerCollectionService.swift
//  TickerCore
//
//  Created by Claude Code
//  Service for managing ticker collections (e.g., Sleep Schedule)
//

import Foundation
import SwiftData
import WidgetKit
import Factory

// MARK: - Error Types

enum TickerCollectionServiceError: LocalizedError {
    case invalidConfiguration
    case childCreationFailed(underlying: Error)
    case swiftDataSaveFailed(underlying: Error)
    case collectionNotFound(UUID)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid ticker collection configuration"
        case .childCreationFailed(let error):
            return "Failed to create child tickers: \(error.localizedDescription)"
        case .swiftDataSaveFailed(let error):
            return "Failed to save ticker collection: \(error.localizedDescription)"
        case .collectionNotFound(let id):
            return "Composite ticker with ID \(id) not found"
        }
    }
}

// MARK: - TickerCollectionService

public final class TickerCollectionService {

    @Injected(\.tickerService) private var tickerService

    public init() {}

    // MARK: - Sleep Schedule Operations

    /// Create a new Sleep Schedule ticker collection with bedtime and wake-up alarms
    @MainActor
    public func createSleepSchedule(
        label: String = "Sleep Schedule",
        bedtime: TimeOfDay,
        wakeTime: TimeOfDay,
        presentation: TickerPresentation = TickerPresentation(),
        modelContext: ModelContext
    ) async throws -> TickerCollection {
        print("🛏️ Creating Sleep Schedule ticker collection")
        print("   → Bedtime: \(bedtime)")
        print("   → Wake time: \(wakeTime)")

        // 1. Create the parent TickerCollection
        let sleepConfig = SleepScheduleConfiguration(
            bedtime: bedtime,
            wakeTime: wakeTime
        )

        let tickerCollection = TickerCollection(
            label: label,
            collectionType: .sleepSchedule,
            configuration: .sleepSchedule(sleepConfig),
            presentation: presentation,
            tickerData: TickerData(
                name: "Sleep Schedule",
                icon: "bed.double.fill",
                colorHex: presentation.tintColorHex
            ),
            isEnabled: true
        )

        print("   → Created parent TickerCollection: \(tickerCollection.id)")

        // 2. Create child tickers (bedtime and wake-up)
        do {
            // Bedtime alarm
            let bedtimeTicker = Ticker(
                label: "Bedtime",
                isEnabled: true,
                schedule: .daily(time: bedtime),
                countdown: nil,
                presentation: presentation,
                soundName: nil,
                tickerData: TickerData(
                    name: "Bedtime",
                    icon: "bed.double.fill",
                    colorHex: presentation.tintColorHex
                )
            )
            bedtimeTicker.parentTickerCollection = tickerCollection
            print("   → Created bedtime ticker: \(bedtimeTicker.id)")

            // Wake-up alarm
            let wakeUpTicker = Ticker(
                label: "Wake Up",
                isEnabled: true,
                schedule: .daily(time: wakeTime),
                countdown: nil,
                presentation: presentation,
                soundName: nil,
                tickerData: TickerData(
                    name: "Wake Up",
                    icon: "alarm.fill",
                    colorHex: presentation.tintColorHex
                )
            )
            wakeUpTicker.parentTickerCollection = tickerCollection
            print("   → Created wake-up ticker: \(wakeUpTicker.id)")

            // 3. Add children to parent
            tickerCollection.childTickers = [bedtimeTicker, wakeUpTicker]

            // 4. Insert into context (atomically)
            modelContext.insert(tickerCollection)
            modelContext.insert(bedtimeTicker)
            modelContext.insert(wakeUpTicker)

            print("   → Inserted all items into context")

            // 5. Save to SwiftData
            do {
                try modelContext.save()
                print("   ✅ SwiftData save successful")
            } catch {
                print("   ❌ SwiftData save failed: \(error)")
                throw TickerCollectionServiceError.swiftDataSaveFailed(underlying: error)
            }

            // 6. Schedule alarms for both children
            print("   → Scheduling child alarms...")
            try await tickerService.scheduleAlarm(from: bedtimeTicker, context: modelContext)
            print("   → Bedtime alarm scheduled")

            try await tickerService.scheduleAlarm(from: wakeUpTicker, context: modelContext)
            print("   → Wake-up alarm scheduled")

            // 7. Refresh widgets
            refreshWidgetTimelines()
            print("   ✅ Sleep Schedule created successfully")

            return tickerCollection

        } catch {
            print("   ❌ Child creation failed, rolling back...")
            // Rollback: delete from context
            modelContext.delete(tickerCollection)
            try? modelContext.save()
            throw TickerCollectionServiceError.childCreationFailed(underlying: error)
        }
    }

    /// Update an existing Sleep Schedule ticker collection
    @MainActor
    public func updateSleepSchedule(
        _ collection: TickerCollection,
        bedtime: TimeOfDay,
        wakeTime: TimeOfDay,
        modelContext: ModelContext
    ) async throws {
        print("🛏️ Updating Sleep Schedule: \(collection.id)")

        guard collection.collectionType == .sleepSchedule else {
            throw TickerCollectionServiceError.invalidConfiguration
        }

        // Update configuration
        collection.updateSleepSchedule(
            bedtime: bedtime,
            wakeTime: wakeTime
        )

        // Update child tickers
        if let children = collection.childTickers, children.count == 2 {
            // Update bedtime (first child)
            children[0].schedule = .daily(time: bedtime)
            try await tickerService.updateAlarm(children[0], context: modelContext)

            // Update wake-up (second child)
            children[1].schedule = .daily(time: wakeTime)
            try await tickerService.updateAlarm(children[1], context: modelContext)

            print("   ✅ Sleep Schedule updated")
        }

        try modelContext.save()
        refreshWidgetTimelines()
    }

    // MARK: - Enable/Disable Operations

    /// Toggle the ticker collection (affects all children)
    @MainActor
    public func toggleTickerCollection(
        _ collection: TickerCollection,
        enabled: Bool,
        modelContext: ModelContext
    ) async throws {
        print("🔄 Toggling TickerCollection: \(collection.id) to \(enabled)")

        collection.isEnabled = enabled

        // Toggle all children
        if let children = collection.childTickers {
            for child in children {
                child.isEnabled = enabled
                if enabled {
                    try await tickerService.scheduleAlarm(from: child, context: modelContext)
                } else {
                    try await tickerService.cancelAlarm(id: child.id, context: modelContext)
                }
            }
        }

        try modelContext.save()
        refreshWidgetTimelines()
        print("   ✅ Toggle complete")
    }

    /// Toggle individual child ticker (hybrid control)
    @MainActor
    public func toggleChildTicker(
        _ collection: TickerCollection,
        childID: UUID,
        enabled: Bool,
        modelContext: ModelContext
    ) async throws {
        print("🔄 Toggling child ticker: \(childID) to \(enabled)")

        guard let child = collection.childTickers?.first(where: { $0.id == childID }) else {
            print("   ❌ Child not found")
            return
        }

        child.isEnabled = enabled

        if enabled {
            try await tickerService.scheduleAlarm(from: child, context: modelContext)
        } else {
            try await tickerService.cancelAlarm(id: childID, context: modelContext)
        }

        // Update parent's enabled state based on children
        // Parent is enabled if ANY child is enabled
        if let children = collection.childTickers {
            collection.isEnabled = children.contains { $0.isEnabled }
        }

        try modelContext.save()
        refreshWidgetTimelines()
        print("   ✅ Child toggle complete")
    }

    // MARK: - Custom Composite Operations

    /// Create a new custom ticker collection with provided child tickers
    @MainActor
    public func createCustomTickerCollection(
        label: String,
        icon: String,
        colorHex: String,
        childTickers: [Ticker],
        modelContext: ModelContext
    ) async throws -> TickerCollection {
        print("📦 Creating Custom Composite Ticker")
        print("   → Label: \(label)")
        print("   → Icon: \(icon)")
        print("   → Color: \(colorHex)")
        print("   → Child count: \(childTickers.count)")

        // 1. Create the parent TickerCollection
        let presentation = TickerPresentation(
            tintColorHex: colorHex,
            secondaryButtonType: .none
        )

        let tickerCollection = TickerCollection(
            label: label,
            collectionType: .custom,
            configuration: nil, // Custom collections don't have specific configuration
            presentation: presentation,
            tickerData: TickerData(
                name: label,
                icon: icon,
                colorHex: colorHex
            ),
            isEnabled: true
        )

        print("   → Created parent TickerCollection: \(tickerCollection.id)")

        // 2. Set up child tickers
        do {
            // Set parent relationship on each child
            for child in childTickers {
                child.parentTickerCollection = tickerCollection
                print("   → Prepared child ticker: \(child.id) - \(child.label)")
            }

            // 3. Add children to parent
            tickerCollection.childTickers = childTickers

            // 4. Insert into context (atomically)
            modelContext.insert(tickerCollection)
            for child in childTickers {
                // Only insert if not already in context (e.g., if created via AddTickerView)
                if child.modelContext == nil {
                    modelContext.insert(child)
                }
            }

            print("   → Inserted all items into context")

            // 5. Save to SwiftData
            do {
                try modelContext.save()
                print("   ✅ SwiftData save successful")
            } catch {
                print("   ❌ SwiftData save failed: \(error)")
                throw TickerCollectionServiceError.swiftDataSaveFailed(underlying: error)
            }

            // 6. Schedule alarms for all children
            print("   → Scheduling child alarms...")
            for child in childTickers {
                try await tickerService.scheduleAlarm(from: child, context: modelContext)
                print("   → Child alarm scheduled: \(child.label)")
            }

            // 7. Refresh widgets
            refreshWidgetTimelines()
            print("   ✅ Custom Composite Ticker created successfully")

            return tickerCollection

        } catch {
            print("   ❌ Child creation failed, rolling back...")
            // Rollback: delete from context
            modelContext.delete(tickerCollection)
            for child in childTickers {
                modelContext.delete(child)
            }
            try? modelContext.save()
            throw TickerCollectionServiceError.childCreationFailed(underlying: error)
        }
    }

    /// Update an existing custom ticker collection
    @MainActor
    public func updateCustomTickerCollection(
        _ collection: TickerCollection,
        label: String,
        icon: String,
        colorHex: String,
        childTickers: [Ticker],
        modelContext: ModelContext
    ) async throws {
        print("📦 Updating Custom Composite Ticker: \(collection.id)")

        guard collection.collectionType == .custom else {
            throw TickerCollectionServiceError.invalidConfiguration
        }

        // 1. Cancel existing child alarms
        if let existingChildren = collection.childTickers {
            for child in existingChildren {
                try await tickerService.cancelAlarm(id: child.id, context: modelContext)
            }
            // Remove old children from context (they'll be replaced)
            for child in existingChildren {
                modelContext.delete(child)
            }
        }

        // 2. Update collection properties
        collection.label = label
        collection.presentation = TickerPresentation(
            tintColorHex: colorHex,
            secondaryButtonType: .none
        )
        collection.tickerData = TickerData(
            name: label,
            icon: icon,
            colorHex: colorHex
        )

        // 3. Set up new child tickers
        for child in childTickers {
            child.parentTickerCollection = collection
            // Insert new children if they're not already in context
            // Note: If child is already in context (e.g., from AddTickerView), 
            // we just update the relationship, no need to insert again
            if child.modelContext == nil {
                modelContext.insert(child)
            }
        }

        // 4. Update children relationship
        collection.childTickers = childTickers

        // 5. Save to SwiftData
        try modelContext.save()
        print("   ✅ SwiftData save successful")

        // 6. Schedule alarms for all new children
        print("   → Scheduling child alarms...")
        for child in childTickers {
            try await tickerService.scheduleAlarm(from: child, context: modelContext)
            print("   → Child alarm scheduled: \(child.label)")
        }

        // 7. Refresh widgets
        refreshWidgetTimelines()
        print("   ✅ Custom Composite Ticker updated successfully")
    }

    // MARK: - Delete Operations

    /// Delete ticker collection (cascade deletes children via relationship)
    @MainActor
    public func deleteTickerCollection(
        _ collection: TickerCollection,
        modelContext: ModelContext
    ) async throws {
        print("🗑️ Deleting TickerCollection: \(collection.id)")

        // Cancel all child alarms first
        if let children = collection.childTickers {
            for child in children {
                try await tickerService.cancelAlarm(id: collection.id, context: modelContext)
            }
        }

        // Delete from context (children will cascade delete)
        modelContext.delete(collection)
        try modelContext.save()

        refreshWidgetTimelines()
        print("   ✅ Composite ticker deleted")
    }

    // MARK: - Helper Methods

    private func refreshWidgetTimelines() {
        // Refresh widgets asynchronously to avoid blocking the main thread
        Task.detached(priority: .utility) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
