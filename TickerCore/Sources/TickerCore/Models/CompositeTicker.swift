//
//  CompositeTicker.swift
//  TickerCore
//
//  Created by Claude Code
//  SwiftData model for composite tickers (e.g., Sleep Schedule with bedtime and wake-up alarms)
//

import Foundation
import SwiftData

// MARK: - CompositeTicker Model

@Model
public final class CompositeTicker {
    public var id: UUID
    public var label: String
    public var createdAt: Date
    public var isEnabled: Bool

    // Type of composite ticker
    public var compositeType: CompositeTickerType

    // Configuration - stored as JSON Data to support enum with associated values
    @Attribute(.externalStorage)
    private var configurationData: Data?

    public var configuration: CompositeConfiguration? {
        get {
            guard let data = configurationData else { return nil }
            return try? JSONDecoder().decode(CompositeConfiguration.self, from: data)
        }
        set {
            configurationData = try? JSONEncoder().encode(newValue)
        }
    }

    // Presentation (shared styling for composite and children)
    public var presentation: TickerPresentation

    // Template metadata
    public var tickerData: TickerData?

    // Child tickers (cascade delete when parent is deleted)
    @Relationship(deleteRule: .cascade, inverse: \Ticker.parentCompositeTicker)
    public var childTickers: [Ticker]?

    // MARK: - Initializers

    public init(
        id: UUID = UUID(),
        label: String,
        compositeType: CompositeTickerType,
        configuration: CompositeConfiguration? = nil,
        presentation: TickerPresentation = TickerPresentation(),
        tickerData: TickerData? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.compositeType = compositeType
        self.configurationData = try? JSONEncoder().encode(configuration)
        self.presentation = presentation
        self.tickerData = tickerData
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.childTickers = []
    }

    // MARK: - Computed Properties

    /// All AlarmKit IDs from all child tickers
    public var allGeneratedAlarmKitIDs: [UUID] {
        childTickers?.flatMap { $0.generatedAlarmKitIDs } ?? []
    }

    /// Count of child tickers
    public var childCount: Int {
        childTickers?.count ?? 0
    }

    /// Check if all children are enabled
    public var allChildrenEnabled: Bool {
        guard let children = childTickers, !children.isEmpty else { return false }
        return children.allSatisfy { $0.isEnabled }
    }

    /// Check if any children are enabled
    public var anyChildrenEnabled: Bool {
        guard let children = childTickers, !children.isEmpty else { return false }
        return children.contains { $0.isEnabled }
    }
}

// MARK: - Convenience Extensions

extension CompositeTicker {
    /// Get sleep schedule configuration if this is a sleep schedule composite
    public var sleepScheduleConfig: SleepScheduleConfiguration? {
        guard case .sleepSchedule(let config) = configuration else { return nil }
        return config
    }

    /// Update sleep schedule configuration
    public func updateSleepSchedule(bedtime: TimeOfDay, wakeTime: TimeOfDay, sleepGoalHours: Double = 8.0) {
        let config = SleepScheduleConfiguration(
            bedtime: bedtime,
            wakeTime: wakeTime,
            sleepGoalHours: sleepGoalHours
        )
        self.configuration = .sleepSchedule(config)
    }
}
