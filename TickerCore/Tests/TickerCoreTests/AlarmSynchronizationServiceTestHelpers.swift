//
//  AlarmSynchronizationServiceTestHelpers.swift
//  TickerCoreTests
//
//  Helper utilities and mocks for testing AlarmSynchronizationService
//

import Foundation
import XCTest
import SwiftData
@testable import TickerCore
import AlarmKit

// MARK: - Mock Alarm

/// Mock Alarm for testing - wraps minimal AlarmKit Alarm data
struct MockAlarm {
    let id: UUID
    let alertingTime: Date
    
    init(id: UUID = UUID(), alertingTime: Date = Date()) {
        self.id = id
        self.alertingTime = alertingTime
    }
}

// MARK: - Alarm Manager Protocol Wrapper
// Note: Since AlarmManager from AlarmKit is opaque and not easily mockable,
// we control alarm queries through MockAlarmStateManager.queryAlarmKit()
// and track cancellations through a cancellable wrapper

/// Tracks alarm cancellations for testing
/// Since we can't easily mock AlarmManager.cancel(), we'll track expected cancellations
/// and verify them through the state changes
@available(iOS 26.0, *)
class AlarmCancellationTracker {
    private(set) var cancelledAlarmIDs: Set<UUID> = []
    
    func trackCancellation(id: UUID) {
        cancelledAlarmIDs.insert(id)
    }
    
    func reset() {
        cancelledAlarmIDs = []
    }
}

// MARK: - Mock AlarmStateManager

/// Mock AlarmStateManager for testing
/// Note: AlarmStateManager has been simplified to only provide AlarmKit query functionality.
/// It no longer maintains in-memory cache - SwiftData is the single source of truth.
@available(iOS 26.0, *)
@Observable
class MockAlarmStateManager: AlarmStateManagerProtocol {

    // MARK: - Test Tracking Properties
    // These are for test verification only, not part of the protocol

    // Track query calls for test verification
    private(set) var queryCallCount = 0

    // Track update calls for test verification (simulates what would be tracked elsewhere)
    private(set) var updateCalls: [Ticker] = []

    // MARK: - Mock Configuration

    // Simulate query errors
    var shouldFailQuery = false
    var queryError: Error?

    // Mock alarms to return from queryAlarmKit
    var mockAlarms: [Alarm] = []

    // MARK: - AlarmStateManagerProtocol Implementation

    /// Centralized AlarmKit query method
    /// This is the only protocol method - matches the simplified AlarmStateManager
    func queryAlarmKit(alarmManager: AlarmManager) throws -> [Alarm] {
        queryCallCount += 1

        if shouldFailQuery {
            throw queryError ?? NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock query error"])
        }

        // Return mock alarms if set, otherwise use real alarm manager
        if !mockAlarms.isEmpty {
            return mockAlarms
        }

        // Otherwise use the real alarm manager
        return try alarmManager.alarms
    }

    // MARK: - Test Helper Methods
    // These methods are for test setup and verification only

    /// Simulate tracking an update call (for test verification)
    func trackUpdate(_ ticker: Ticker) {
        updateCalls.append(ticker)
    }

    /// Reset all tracking state
    func reset() {
        queryCallCount = 0
        updateCalls = []
        shouldFailQuery = false
        queryError = nil
        mockAlarms = []
    }
}

// MARK: - Test Model Context Factory

/// Factory for creating in-memory SwiftData ModelContext for testing
@available(iOS 26.0, *)
struct TestModelContextFactory {
    
    static func createInMemoryContext() throws -> ModelContext {
        let schema = Schema([Ticker.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
    
    static func createContextWithTickers(_ tickers: [Ticker]) throws -> ModelContext {
        let context = try createInMemoryContext()
        for ticker in tickers {
            context.insert(ticker)
        }
        try context.save()
        return context
    }
}

// MARK: - Test Alarm Creation Helpers
// Note: Since Alarm is opaque from AlarmKit, we cannot create Alarm instances directly.
// Instead, we'll use the real AlarmManager to create alarms for testing, or work with
// the alarms that are returned from AlarmManager.alarms.
// 
// For unit testing, we'll use MockAlarmStateManager.mockAlarms to inject test alarms.

// MARK: - Test Assertion Helpers

extension XCTestCase {
    
    /// Assert that a set of alarm IDs were cancelled
    @available(iOS 26.0, *)
    func XCTAssertCancelledAlarms(
        _ cancelledIDs: Set<UUID>,
        contains expectedIDs: Set<UUID>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let missing = expectedIDs.subtracting(cancelledIDs)
        if !missing.isEmpty {
            XCTFail("Expected alarms to be cancelled: \(missing), but they were not. Cancelled: \(cancelledIDs)", file: file, line: line)
        }
    }
    
    /// Assert that a set of alarm IDs were NOT cancelled
    @available(iOS 26.0, *)
    func XCTAssertNotCancelledAlarms(
        _ cancelledIDs: Set<UUID>,
        contains unexpectedIDs: Set<UUID>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let unexpected = unexpectedIDs.intersection(cancelledIDs)
        if !unexpected.isEmpty {
            XCTFail("Expected alarms NOT to be cancelled: \(unexpected), but they were. Cancelled: \(cancelledIDs)", file: file, line: line)
        }
    }
    
    /// Assert that tickers exist in context
    @available(iOS 26.0, *)
    func XCTAssertTickersExist(
        in context: ModelContext,
        tickerIDs: Set<UUID>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let descriptor = FetchDescriptor<Ticker>()
        guard let tickers = try? context.fetch(descriptor) else {
            XCTFail("Failed to fetch tickers from context", file: file, line: line)
            return
        }
        
        let existingIDs = Set(tickers.map { $0.id })
        let missing = tickerIDs.subtracting(existingIDs)
        if !missing.isEmpty {
            XCTFail("Expected tickers to exist: \(missing), but they don't. Existing: \(existingIDs)", file: file, line: line)
        }
    }
    
    /// Assert that tickers do NOT exist in context
    @available(iOS 26.0, *)
    func XCTAssertTickersNotExist(
        in context: ModelContext,
        tickerIDs: Set<UUID>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let descriptor = FetchDescriptor<Ticker>()
        guard let tickers = try? context.fetch(descriptor) else {
            XCTFail("Failed to fetch tickers from context", file: file, line: line)
            return
        }
        
        let existingIDs = Set(tickers.map { $0.id })
        let unexpected = tickerIDs.intersection(existingIDs)
        if !unexpected.isEmpty {
            XCTFail("Expected tickers NOT to exist: \(unexpected), but they do. Existing: \(existingIDs)", file: file, line: line)
        }
    }
}

// MARK: - Test Data Builders

/// Helper namespace for test data builders
@available(iOS 26.0, *)
enum AlarmSynchronizationServiceTestHelpers {
    
    /// Create a ticker with specific generated alarm IDs
    static func createTickerWithGeneratedIDs(
        id: UUID = UUID(),
        label: String = "Test Ticker",
        generatedIDs: [UUID],
        schedule: TickerSchedule? = .daily(time: .init(hour: 9, minute: 0))
    ) -> Ticker {
        let ticker = Ticker(
            id: id,
            label: label,
            isEnabled: true,
            schedule: schedule
        )
        ticker.generatedAlarmKitIDs = generatedIDs
        return ticker
    }
    
    /// Create a disabled ticker
    static func createDisabledTicker(
        id: UUID = UUID(),
        label: String = "Disabled Ticker",
        schedule: TickerSchedule? = .daily(time: .init(hour: 9, minute: 0))
    ) -> Ticker {
        return Ticker(
            id: id,
            label: label,
            isEnabled: false,
            schedule: schedule
        )
    }
    
    /// Create a ticker that needs regeneration
    /// Sets lastRegenerationDate to an old date so staleness threshold is exceeded
    static func createTickerNeedingRegeneration(
        id: UUID = UUID(),
        label: String = "Needs Regeneration",
        schedule: TickerSchedule = .hourly(interval: 2, time: .init(hour: 0, minute: 0))
    ) -> Ticker {
        let ticker = Ticker(
            id: id,
            label: label,
            isEnabled: true,
            schedule: schedule
        )
        // Set lastRegenerationDate to an old date (10 days ago) to exceed staleness threshold
        // This will make needsRegeneration return true
        ticker.lastRegenerationDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        ticker.lastRegenerationSuccess = true
        // Note: needsRegeneration is a computed property that checks staleness
        // By setting lastRegenerationDate to 10 days ago, it will exceed the threshold
        return ticker
    }
}

// MARK: - Widget Refresh Mock

/// Since WidgetCenter.shared.reloadAllTimelines() is called in the service,
/// we can't easily mock it, but we can verify the service completes without errors
/// which implies the widget refresh was attempted

