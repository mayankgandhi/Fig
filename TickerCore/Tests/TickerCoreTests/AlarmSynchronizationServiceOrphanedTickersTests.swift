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
    
    func testSynchronize_DeletesOrphanedTicker_NoMatchingAlarms() async throws {
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
        
        // Then: Ticker should be deleted if it has no upcoming alarms
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)
        
        // Check if ticker has upcoming alarms
        if let schedule = ticker.schedule {
            let expander = TickerScheduleExpander()
            let oneYear: TimeInterval = 365 * 24 * 3600
            let upcomingDates = expander.expandSchedule(
                schedule,
                withinCustomWindow: Date(),
                duration: oneYear,
                maxAlarms: 1
            )
            
            if upcomingDates.isEmpty {
                // No upcoming alarms - should be deleted
                XCTAssertTickersNotExist(in: context, tickerIDs: [tickerID])
            } else {
                // Has upcoming alarms - should be kept
                XCTAssertTickersExist(in: context, tickerIDs: [tickerID])
            }
        }
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
    
    func testSynchronize_DeletesTicker_WithPastOneTimeSchedule() async throws {
        // Given: One-time ticker with past date
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
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
        
        // Then: Ticker should be deleted (past date, no upcoming alarms)
        XCTAssertTickersNotExist(in: context, tickerIDs: [tickerID])
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
    
    func testSynchronize_DeletesTicker_WithNoSchedule() async throws {
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
        
        // Then: Ticker should be deleted (no schedule, no upcoming alarms)
        XCTAssertTickersNotExist(in: context, tickerIDs: [tickerID])
    }
    
    // MARK: - Regeneration Tests
    
    func testSynchronize_KeepsTicker_NeedsRegeneration() async throws {
        // Given: Ticker that needs regeneration (composite schedule)
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
    
    func testSynchronize_DeletesMultipleOrphanedTickers() async throws {
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
        
        // Then: Both tickers should be deleted
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)
        
        XCTAssertFalse(tickers.contains { $0.id == pastTicker1.id }, "Past ticker 1 should be deleted")
        XCTAssertFalse(tickers.contains { $0.id == pastTicker2.id }, "Past ticker 2 should be deleted")
    }
    
    func testSynchronize_MixedKeepAndDeleteTickers() async throws {
        // Given: Mix of tickers - some should be kept, some deleted
        let keepTicker = Ticker.mockDailyMorning // Has upcoming alarms
        let deleteTicker = Ticker.mockOneTimePast // Past date
        
        let context = try TestModelContextFactory.createContextWithTickers([keepTicker, deleteTicker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Keep ticker should remain, delete ticker should be removed
        XCTAssertTickersExist(in: context, tickerIDs: [keepTicker.id])
        XCTAssertTickersNotExist(in: context, tickerIDs: [deleteTicker.id])
    }
}

