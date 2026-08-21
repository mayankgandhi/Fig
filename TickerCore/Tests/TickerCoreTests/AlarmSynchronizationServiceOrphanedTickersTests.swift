//
//  AlarmSynchronizationServiceOrphanedTickersTests.swift
//  TickerCoreTests
//
//  Tests for SwiftData cleanup scenarios (orphaned tickers)
//

import XCTest
import SwiftData
@testable import TickerCore
import AlarmKit

@available(iOS 26.0, *)
final class AlarmSynchronizationServiceOrphanedTickersTests: XCTestCase {
    
    var service: AlarmSynchronizationService!
    var mockStateManager: MockAlarmStateManager!
    var alarmManager: AlarmManager!
    
    override func setUp() {
        super.setUp()
        service = AlarmSynchronizationService()
        mockStateManager = MockAlarmStateManager()
        alarmManager = AlarmManager.shared
        mockStateManager.reset()
    }
    
    override func tearDown() {
        mockStateManager.reset()
        service = nil
        mockStateManager = nil
        alarmManager = nil
        super.tearDown()
    }
    
    // MARK: - Orphaned Tickers Tests
    
    func testSynchronize_RetainsOrphanedTicker_WhenNoAlarmsAreArmed() async throws {
        // Given: Ticker in SwiftData but no matching alarms in AlarmManager
        let ticker = Ticker.mockDailyMorning
        let tickerID = ticker.id

        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = [] // No alarms

        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )

        // Then: the row survives unconditionally. Reconciliation no longer calls
        // context.delete at all, so this is asserted flatly rather than
        // re-deriving the expected outcome from the same expander the service
        // uses — a test that computes its own expectation from production logic
        // passes whichever way the logic goes.
        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])

        // A daily ticker still has upcoming occurrences, so it stays enabled.
        let stored = try context.fetch(FetchDescriptor<Ticker>())
        XCTAssertTrue(
            try XCTUnwrap(stored.first { $0.id == tickerID }).isEnabled,
            "A ticker with upcoming occurrences must not be retired"
        )
    }
    
    func testSynchronize_KeepsTicker_WithUpcomingAlarms() async throws {
        // Given: Ticker with upcoming alarms (daily schedule)
        let ticker = Ticker.mockDailyMorning
        let tickerID = ticker.id
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = [] // No current alarms, but ticker has schedule
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Ticker should be kept (has upcoming alarms)
        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])
    }
    
    /// This test used to assert the opposite — that a fired one-time ticker is
    /// deleted. That behaviour was the "alarm rings once and then it's gone" bug:
    /// reconciliation silently destroyed user-created data. A spent alarm is now
    /// retired (switched off, kept in the list) the way the system Clock app
    /// switches off a one-time alarm after it rings.
    func testSynchronize_RetainsButDisablesTicker_WithPastOneTimeSchedule() async throws {
        // Given: One-time ticker with past date
        let ticker = Ticker.mockOneTimePast
        let tickerID = ticker.id

        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []

        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )

        // Then: the row survives...
        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])

        // ...and is switched off rather than deleted.
        let descriptor = FetchDescriptor<Ticker>()
        let stored = try XCTUnwrap(try? context.fetch(descriptor))
        let retired = try XCTUnwrap(stored.first { $0.id == tickerID })
        XCTAssertFalse(retired.isEnabled, "A spent one-time alarm should be retired, not deleted")
    }
    
    func testSynchronize_KeepsTicker_WithFutureOneTimeSchedule() async throws {
        // Given: One-time ticker with future date
        let ticker = Ticker.mockOneTimeFuture
        let tickerID = ticker.id
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Ticker should be kept (has upcoming alarm)
        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])
    }
    
    func testSynchronize_RetainsTicker_WithNoSchedule() async throws {
        // Given: Ticker with nil schedule
        let ticker = Ticker.mockNoSchedule
        let tickerID = ticker.id
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: retained, not deleted. Reconciliation must never destroy a
        // user-created row — a ticker with a broken or missing schedule is a bug
        // to surface, not data to throw away.
        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])
    }
    
    // MARK: - Regeneration Tests
    
    func testSynchronize_KeepsTicker_NeedsRegeneration() async throws {
        // Given: Ticker that needs regeneration (collection schedule)
        let ticker = AlarmSynchronizationServiceTestHelpers.createTickerNeedingRegeneration()
        let tickerID = ticker.id
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Ticker should be kept (needs regeneration)
        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])
    }
    
    func testSynchronize_KeepsTicker_NeedsRegenerationButNotEnabled() async throws {
        // Given: Disabled ticker that would need regeneration
        let ticker = AlarmSynchronizationServiceTestHelpers.createTickerNeedingRegeneration()
        ticker.isEnabled = false
        let tickerID = ticker.id
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Ticker should be kept (disabled tickers are handled separately)
        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])
    }
    
    // MARK: - Simple vs Composite Schedule Tests
    
    func testSynchronize_HandlesSimpleSchedule() async throws {
        // Given: Simple schedule (daily) - should have upcoming alarms
        let ticker = Ticker.mockDailyMorning
        let tickerID = ticker.id
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Simple schedule should be kept (has upcoming alarms)
        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])
    }
    
    func testSynchronize_HandlesCompositeSchedule() async throws {
        // Given: Composite schedule (hourly) - should have upcoming alarms
        let ticker = Ticker.mockHourly
        let tickerID = ticker.id
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Composite schedule should be kept (has upcoming alarms)
        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])
    }
    
    // MARK: - Multiple Orphaned Tickers
    
    func testSynchronize_RetiresMultipleSpentTickers() async throws {
        // Given: Multiple tickers with no matching alarms
        let pastTicker1 = Ticker.mockOneTimePast
        let pastTicker2 = Ticker(
            id: UUID(),
            label: "Another Past",
            schedule: .oneTime(date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date())
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([pastTicker1, pastTicker2])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: both survive and are switched off, rather than being deleted.
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)

        XCTAssertTrue(tickers.contains { $0.id == pastTicker1.id }, "Past ticker 1 should be retained")
        XCTAssertTrue(tickers.contains { $0.id == pastTicker2.id }, "Past ticker 2 should be retained")
        XCTAssertFalse(try XCTUnwrap(tickers.first { $0.id == pastTicker1.id }).isEnabled)
        XCTAssertFalse(try XCTUnwrap(tickers.first { $0.id == pastTicker2.id }).isEnabled)
    }
    
    func testSynchronize_MixedActiveAndSpentTickers() async throws {
        // Given: one ticker with upcoming alarms, one already spent
        let activeTicker = Ticker.mockDailyMorning // Has upcoming alarms
        let spentTicker = Ticker.mockOneTimePast   // Past date

        let context = try TestModelContextFactory.createContextWithTickers([activeTicker, spentTicker])
        mockStateManager.mockAlarms = []

        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )

        // Then: both rows survive; only their enabled state differs.
        XCTAssertTickersExist(in: context, tickerIDs: [activeTicker.id, spentTicker.id])

        let tickers = try context.fetch(FetchDescriptor<Ticker>())
        XCTAssertTrue(try XCTUnwrap(tickers.first { $0.id == activeTicker.id }).isEnabled)
        XCTAssertFalse(try XCTUnwrap(tickers.first { $0.id == spentTicker.id }).isEnabled)
    }
}

