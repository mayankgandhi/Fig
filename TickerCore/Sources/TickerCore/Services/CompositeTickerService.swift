//
//  CompositeTickerService.swift
//  TickerCore
//
//  Created by Claude Code
//  Service for managing composite tickers (e.g., Sleep Schedule)
//

import Foundation
import SwiftData
import WidgetKit
import Factory

// MARK: - Error Types

enum CompositeTickerServiceError: LocalizedError {
    case invalidConfiguration
    case childCreationFailed(underlying: Error)
    case swiftDataSaveFailed(underlying: Error)
    case compositeNotFound(UUID)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid composite ticker configuration"
        case .childCreationFailed(let error):
            return "Failed to create child tickers: \(error.localizedDescription)"
        case .swiftDataSaveFailed(let error):
            return "Failed to save composite ticker: \(error.localizedDescription)"
        case .compositeNotFound(let id):
            return "Composite ticker with ID \(id) not found"
        }
    }
}

// MARK: - CompositeTickerService

public final class CompositeTickerService {

    @Injected(\.tickerService) private var tickerService

    public init() {}

    // MARK: - Sleep Schedule Operations

    /// Create a new Sleep Schedule composite ticker with bedtime and wake-up alarms
    @MainActor
    public func createSleepSchedule(
        label: String = "Sleep Schedule",
        bedtime: TimeOfDay,
        wakeTime: TimeOfDay,
        presentation: TickerPresentation = TickerPresentation(),
        modelContext: ModelContext
    ) async throws -> CompositeTicker {
        print("🛏️ Creating Sleep Schedule composite ticker")
        print("   → Bedtime: \(bedtime)")
        print("   → Wake time: \(wakeTime)")

        // 1. Create the parent CompositeTicker
        let sleepConfig = SleepScheduleConfiguration(
            bedtime: bedtime,
            wakeTime: wakeTime
        )

        let compositeTicker = CompositeTicker(
            label: label,
            compositeType: .sleepSchedule,
            configuration: .sleepSchedule(sleepConfig),
            presentation: presentation,
            tickerData: TickerData(
                name: "Sleep Schedule",
                icon: "bed.double.fill",
                colorHex: presentation.tintColorHex
            ),
            isEnabled: true
        )

        print("   → Created parent CompositeTicker: \(compositeTicker.id)")

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
            bedtimeTicker.parentCompositeTicker = compositeTicker
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
            wakeUpTicker.parentCompositeTicker = compositeTicker
            print("   → Created wake-up ticker: \(wakeUpTicker.id)")

            // 3. Add children to parent
            compositeTicker.childTickers = [bedtimeTicker, wakeUpTicker]

            // 4. Insert into context (atomically)
            modelContext.insert(compositeTicker)
            modelContext.insert(bedtimeTicker)
            modelContext.insert(wakeUpTicker)

            print("   → Inserted all items into context")

            // 5. Save to SwiftData
            do {
                try modelContext.save()
                print("   ✅ SwiftData save successful")
            } catch {
                print("   ❌ SwiftData save failed: \(error)")
                throw CompositeTickerServiceError.swiftDataSaveFailed(underlying: error)
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

            return compositeTicker

        } catch {
            print("   ❌ Child creation failed, rolling back...")
            // Rollback: delete from context
            modelContext.delete(compositeTicker)
            try? modelContext.save()
            throw CompositeTickerServiceError.childCreationFailed(underlying: error)
        }
    }

    /// Update an existing Sleep Schedule composite ticker
    @MainActor
    public func updateSleepSchedule(
        _ composite: CompositeTicker,
        bedtime: TimeOfDay,
        wakeTime: TimeOfDay,
        modelContext: ModelContext
    ) async throws {
        print("🛏️ Updating Sleep Schedule: \(composite.id)")

        guard composite.compositeType == .sleepSchedule else {
            throw CompositeTickerServiceError.invalidConfiguration
        }

        // Update configuration
        composite.updateSleepSchedule(
            bedtime: bedtime,
            wakeTime: wakeTime
        )

        // Update child tickers
        if let children = composite.childTickers, children.count == 2 {
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

    /// Toggle the composite ticker (affects all children)
    @MainActor
    public func toggleCompositeTicker(
        _ composite: CompositeTicker,
        enabled: Bool,
        modelContext: ModelContext
    ) async throws {
        print("🔄 Toggling CompositeTicker: \(composite.id) to \(enabled)")

        composite.isEnabled = enabled

        // Toggle all children
        if let children = composite.childTickers {
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
        _ composite: CompositeTicker,
        childID: UUID,
        enabled: Bool,
        modelContext: ModelContext
    ) async throws {
        print("🔄 Toggling child ticker: \(childID) to \(enabled)")

        guard let child = composite.childTickers?.first(where: { $0.id == childID }) else {
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
        if let children = composite.childTickers {
            composite.isEnabled = children.contains { $0.isEnabled }
        }

        try modelContext.save()
        refreshWidgetTimelines()
        print("   ✅ Child toggle complete")
    }

    // MARK: - Custom Composite Operations

    /// Create a new custom composite ticker with provided child tickers
    @MainActor
    public func createCustomCompositeTicker(
        label: String,
        icon: String,
        colorHex: String,
        childTickers: [Ticker],
        modelContext: ModelContext
    ) async throws -> CompositeTicker {
        print("📦 Creating Custom Composite Ticker")
        print("   → Label: \(label)")
        print("   → Icon: \(icon)")
        print("   → Color: \(colorHex)")
        print("   → Child count: \(childTickers.count)")

        // 1. Create the parent CompositeTicker
        let presentation = TickerPresentation(
            tintColorHex: colorHex,
            secondaryButtonType: .none
        )

        let compositeTicker = CompositeTicker(
            label: label,
            compositeType: .custom,
            configuration: nil, // Custom composites don't have specific configuration
            presentation: presentation,
            tickerData: TickerData(
                name: label,
                icon: icon,
                colorHex: colorHex
            ),
            isEnabled: true
        )

        print("   → Created parent CompositeTicker: \(compositeTicker.id)")

        // 2. Set up child tickers
        do {
            // Set parent relationship on each child
            for child in childTickers {
                child.parentCompositeTicker = compositeTicker
                print("   → Prepared child ticker: \(child.id) - \(child.label)")
            }

            // 3. Add children to parent
            compositeTicker.childTickers = childTickers

            // 4. Insert into context (atomically)
            modelContext.insert(compositeTicker)
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
                throw CompositeTickerServiceError.swiftDataSaveFailed(underlying: error)
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

            return compositeTicker

        } catch {
            print("   ❌ Child creation failed, rolling back...")
            // Rollback: delete from context
            modelContext.delete(compositeTicker)
            for child in childTickers {
                modelContext.delete(child)
            }
            try? modelContext.save()
            throw CompositeTickerServiceError.childCreationFailed(underlying: error)
        }
    }

    /// Update an existing custom composite ticker
    @MainActor
    public func updateCustomCompositeTicker(
        _ composite: CompositeTicker,
        label: String,
        icon: String,
        colorHex: String,
        childTickers: [Ticker],
        modelContext: ModelContext
    ) async throws {
        print("📦 Updating Custom Composite Ticker: \(composite.id)")

        guard composite.compositeType == .custom else {
            throw CompositeTickerServiceError.invalidConfiguration
        }

        // 1. Cancel existing child alarms
        if let existingChildren = composite.childTickers {
            for child in existingChildren {
                try await tickerService.cancelAlarm(id: child.id, context: modelContext)
            }
            // Remove old children from context (they'll be replaced)
            for child in existingChildren {
                modelContext.delete(child)
            }
        }

        // 2. Update composite properties
        composite.label = label
        composite.presentation = TickerPresentation(
            tintColorHex: colorHex,
            secondaryButtonType: .none
        )
        composite.tickerData = TickerData(
            name: label,
            icon: icon,
            colorHex: colorHex
        )

        // 3. Set up new child tickers
        for child in childTickers {
            child.parentCompositeTicker = composite
            // Insert new children if they're not already in context
            // Note: If child is already in context (e.g., from AddTickerView), 
            // we just update the relationship, no need to insert again
            if child.modelContext == nil {
                modelContext.insert(child)
            }
        }

        // 4. Update children relationship
        composite.childTickers = childTickers

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

    /// Delete composite ticker (cascade deletes children via relationship)
    @MainActor
    public func deleteCompositeTicker(
        _ composite: CompositeTicker,
        modelContext: ModelContext
    ) async throws {
        print("🗑️ Deleting CompositeTicker: \(composite.id)")

        // Cancel all child alarms first
        if let children = composite.childTickers {
            for child in children {
                try await tickerService.cancelAlarm(id: composite.id, context: modelContext)
            }
        }

        // Delete from context (children will cascade delete)
        modelContext.delete(composite)
        try modelContext.save()

        refreshWidgetTimelines()
        print("   ✅ Composite ticker deleted")
    }

    // MARK: - Helper Methods

    private func refreshWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
