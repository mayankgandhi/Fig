//
//  TickerCollection.swift
//  TickerCore
//
//  Created by Claude Code
//  SwiftData model for ticker collections (e.g., Sleep Schedule with bedtime and wake-up alarms)
//

import Foundation
import SwiftData

// MARK: - TickerCollection Model

@Model
public final class TickerCollection {
    public var id: UUID
    public var label: String
    public var createdAt: Date
    public var isEnabled: Bool

    // Type of ticker collection
    public var collectionType: TickerCollectionType

    // Configuration - stored as JSON Data to support enum with associated values
    @Attribute(.externalStorage)
    private var configurationData: Data?

    public var configuration: TickerCollectionConfiguration? {
        get {
            guard let data = configurationData else { return nil }
            return try? JSONDecoder().decode(TickerCollectionConfiguration.self, from: data)
        }
        set {
            configurationData = try? JSONEncoder().encode(newValue)
        }
    }

    // Presentation (shared styling for collection and children)
    public var presentation: TickerPresentation

    // Template metadata
    public var tickerData: TickerData?

    // Child tickers (cascade delete when parent is deleted)
    @Relationship(deleteRule: .cascade, inverse: \Ticker.parentTickerCollection)
    public var childTickers: [Ticker]?

    // MARK: - Initializers

    public init(
        id: UUID = UUID(),
        label: String,
        collectionType: TickerCollectionType,
        configuration: TickerCollectionConfiguration? = nil,
        presentation: TickerPresentation = TickerPresentation(),
        tickerData: TickerData? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.collectionType = collectionType
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

extension TickerCollection {
    /// Get sleep schedule configuration if this is a sleep schedule collection
    public var sleepScheduleConfig: SleepScheduleConfiguration? {
        guard case .sleepSchedule(let config) = configuration else { return nil }
        return config
    }

    /// Update sleep schedule configuration
    public func updateSleepSchedule(bedtime: TimeOfDay, wakeTime: TimeOfDay) {
        let config = SleepScheduleConfiguration(
            bedtime: bedtime,
            wakeTime: wakeTime
        )
        self.configuration = .sleepSchedule(config)
    }
}
