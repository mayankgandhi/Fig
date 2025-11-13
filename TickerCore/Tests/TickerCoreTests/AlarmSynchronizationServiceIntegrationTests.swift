//
//  AlarmSynchronizationServiceIntegrationTests.swift
//  TickerCoreTests
//
//  Complex integration scenarios for AlarmSynchronizationService
//

import XCTest
import SwiftData
@testable import TickerCore
import AlarmKit

@available(iOS 26.0, *)
final class AlarmSynchronizationServiceIntegrationTests: XCTestCase {
    
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
    
    // MARK: - Multiple Tickers with Different Schedule Types
    
    func testSynchronize_MultipleTickers_DifferentScheduleTypes() async throws {
        // Given: Multiple tickers with different schedule types
        let tickers = [
            Ticker.mockDailyMorning,
            Ticker.mockHourly,
            Ticker.mockWeekdays,
            Ticker.mockBiweekly,
            Ticker.mockMonthlyFixed,
            Ticker.mockYearly,
            Ticker.mockEveryFiveMinutes
        ]
        
        let context = try TestModelContextFactory.createContextWithTickers(tickers)
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: All tickers with upcoming alarms should be kept
        let descriptor = FetchDescriptor<Ticker>()
        let remainingTickers = try context.fetch(descriptor)
        
        // All these schedules should have upcoming alarms
        for ticker in tickers {
            XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
        }
    }
    
    // MARK: - Mixed Enabled/Disabled Tickers
    
    func testSynchronize_MixedEnabledAndDisabledTickers() async throws {
        // Given: Mix of enabled and disabled tickers
        let enabledTicker = Ticker.mockDailyMorning
        let disabledTicker = AlarmSynchronizationServiceTestHelpers.createDisabledTicker(
            id: UUID(),
            label: "Disabled Ticker"
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([enabledTicker, disabledTicker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Both should remain (disabled ticker's alarm would be cancelled if it existed)
        XCTAssertTickersExist(in: context, tickerIDs: [enabledTicker.id])
        XCTAssertTickersExist(in: context, tickerIDs: [disabledTicker.id])
        XCTAssertFalse(try context.fetch(FetchDescriptor<Ticker>()).first { $0.id == disabledTicker.id }?.isEnabled ?? true)
    }
    
    // MARK: - Tickers Transitioning States
    
    func testSynchronize_TickerTransitioning_EnabledToDisabled() async throws {
        // Given: Ticker that was enabled, now disabled
        let ticker = Ticker.mockDailyMorning
        ticker.isEnabled = false
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Disabled ticker should remain, but its alarm would be cancelled
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
        XCTAssertFalse(try context.fetch(FetchDescriptor<Ticker>()).first { $0.id == ticker.id }?.isEnabled ?? true)
    }
    
    // MARK: - Future One-Time Ticker Bug Fix
    
    func testSynchronize_PreservesFutureOneTimeTicker_NoActiveAlarms() async throws {
        // Given: Future one-time ticker with no active alarms (bug scenario)
        // This tests the fix for the bug where future one-time tickers were incorrectly deleted
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let futureTicker = Ticker(
            id: UUID(),
            label: "Future One-Time Event",
            isEnabled: true,
            schedule: .oneTime(date: futureDate)
        )
        let futureTickerID = futureTicker.id
        
        let context = try TestModelContextFactory.createContextWithTickers([futureTicker])
        mockStateManager.mockAlarms = [] // No active alarms - this is the bug scenario
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Future one-time ticker should be preserved (has upcoming alarm within 1-year window)
        XCTAssertTickersExist(in: context, tickerIDs: [futureTickerID])
        
        // Verify the ticker still has its schedule
        let descriptor = FetchDescriptor<Ticker>()
        let remainingTickers = try context.fetch(descriptor)
        let preservedTicker = remainingTickers.first { $0.id == futureTickerID }
        XCTAssertNotNil(preservedTicker, "Future one-time ticker should exist")
        XCTAssertEqual(preservedTicker?.schedule, .oneTime(date: futureDate), "Future one-time ticker should preserve its schedule")
    }
    
    func testSynchronize_PreservesFutureOneTimeTicker_VariousFutureDates() async throws {
        // Given: Multiple future one-time tickers with different future dates
        let nearFuture = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let midFuture = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        let farFuture = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        
        let tickers = [
            Ticker(id: UUID(), label: "Near Future", isEnabled: true, schedule: .oneTime(date: nearFuture)),
            Ticker(id: UUID(), label: "Mid Future", isEnabled: true, schedule: .oneTime(date: midFuture)),
            Ticker(id: UUID(), label: "Far Future", isEnabled: true, schedule: .oneTime(date: farFuture))
        ]
        
        let context = try TestModelContextFactory.createContextWithTickers(tickers)
        mockStateManager.mockAlarms = [] // No active alarms
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: All future one-time tickers should be preserved
        for ticker in tickers {
            XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
        }
    }
    
    func testSynchronize_PreservesFutureOneTimeTicker_ExactlyOneYearFromNow() async throws {
        // Given: Future one-time ticker with date exactly 1 year from now (boundary condition)
        // This tests the boundary of the 1-year window used in synchronization
        let oneYear: TimeInterval = 365 * 24 * 3600 // 1 year in seconds
        guard let exactlyOneYearFromNow = Calendar.current.date(byAdding: .second, value: Int(oneYear), to: Date()) else {
            XCTFail("Failed to create date exactly 1 year from now")
            return
        }
        
        let boundaryTicker = Ticker(
            id: UUID(),
            label: "Exactly One Year From Now",
            isEnabled: true,
            schedule: .oneTime(date: exactlyOneYearFromNow)
        )
        let boundaryTickerID = boundaryTicker.id
        
        let context = try TestModelContextFactory.createContextWithTickers([boundaryTicker])
        mockStateManager.mockAlarms = [] // No active alarms
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: The ticker at exactly 1 year should be preserved (boundary is inclusive)
        XCTAssertTickersExist(in: context, tickerIDs: [boundaryTickerID])
        
        // Verify the ticker still has its schedule with the correct date
        let descriptor = FetchDescriptor<Ticker>()
        let remainingTickers = try context.fetch(descriptor)
        let preservedTicker = remainingTickers.first { $0.id == boundaryTickerID }
        XCTAssertNotNil(preservedTicker, "Future one-time ticker at exactly 1 year should exist")
        
        // Verify the schedule date is approximately 1 year from now (within 1 second tolerance)
        if case .oneTime(let preservedDate) = preservedTicker?.schedule {
            let timeDifference = abs(preservedDate.timeIntervalSince(exactlyOneYearFromNow))
            XCTAssertLessThan(timeDifference, 1.0, "Preserved date should be within 1 second of the original date")
        } else {
            XCTFail("Preserved ticker should have a oneTime schedule")
        }
    }
    
    // MARK: - Large Scale Synchronization
    
    func testSynchronize_LargeScale_ManyTickers() async throws {
        // Given: Many tickers (stress test)
        var tickers: [Ticker] = []
        for i in 0..<50 {
            let ticker = Ticker(
                id: UUID(),
                label: "Ticker \(i)",
                schedule: .daily(time: .init(hour: i % 24, minute: 0))
            )
            tickers.append(ticker)
        }
        
        let context = try TestModelContextFactory.createContextWithTickers(tickers)
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Should handle large scale without errors
        let descriptor = FetchDescriptor<Ticker>()
        let remainingTickers = try context.fetch(descriptor)
        
        // All daily schedules should have upcoming alarms and be kept
        XCTAssertEqual(remainingTickers.count, tickers.count, "All tickers with upcoming alarms should be kept")
    }
    
    func testSynchronize_LargeScale_MixedScenarios() async throws {
        // Given: Large mix of different scenarios
        var tickers: [Ticker] = []
        
        // Add various types - capture IDs since some mocks are computed properties
        let dailyMorning = Ticker.mockDailyMorning
        let hourly = Ticker.mockHourly
        let weekdays = Ticker.mockWeekdays
        let disabledTicker = AlarmSynchronizationServiceTestHelpers.createDisabledTicker()
        let oneTimePast = Ticker.mockOneTimePast
        let oneTimeFuture = Ticker.mockOneTimeFuture
        
        tickers.append(dailyMorning)
        tickers.append(hourly)
        tickers.append(weekdays)
        tickers.append(disabledTicker)
        tickers.append(oneTimePast)
        tickers.append(oneTimeFuture)
        
        // Capture IDs for later comparison
        let oneTimePastID = oneTimePast.id
        let oneTimeFutureID = oneTimeFuture.id
        
        // Add many with generated IDs
        for _ in 0..<20 {
            let ticker = AlarmSynchronizationServiceTestHelpers.createTickerWithGeneratedIDs(
                id: UUID(),
                label: "Generated ID Ticker",
                generatedIDs: [UUID(), UUID(), UUID()]
            )
            tickers.append(ticker)
        }
        
        let context = try TestModelContextFactory.createContextWithTickers(tickers)
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Should handle complex mix
        let descriptor = FetchDescriptor<Ticker>()
        let remainingTickers = try context.fetch(descriptor)
        
        // Past one-time should be deleted, others kept
        XCTAssertFalse(remainingTickers.contains { $0.id == oneTimePastID }, "Past ticker should be deleted")
        XCTAssertTrue(remainingTickers.contains { $0.id == oneTimeFutureID }, "Future ticker should be kept")
    }
    
    // MARK: - Complex Real-World Scenarios
    
    func testSynchronize_RealWorldScenario_MorningRoutine() async throws {
        // Given: Real-world morning routine scenario
        let wakeUp = Ticker.mockDailyMorning
        let exercise = Ticker(
            id: UUID(),
            label: "Exercise",
            schedule: .weekdays(time: .init(hour: 7, minute: 0), days: [.monday, .wednesday, .friday])
        )
        let medication = Ticker(
            id: UUID(),
            label: "Medication",
            schedule: .daily(time: .init(hour: 8, minute: 0))
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([wakeUp, exercise, medication])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: All should be kept (have upcoming alarms)
        XCTAssertTickersExist(in: context, tickerIDs: [wakeUp.id, exercise.id, medication.id])
    }
    
    func testSynchronize_RealWorldScenario_WorkSchedule() async throws {
        // Given: Work schedule scenario
        let workDays = Ticker(
            id: UUID(),
            label: "Work Days",
            schedule: .weekdays(time: .init(hour: 9, minute: 0), days: [.monday, .tuesday, .wednesday, .thursday, .friday])
        )
        let lunch = Ticker(
            id: UUID(),
            label: "Lunch Break",
            schedule: .weekdays(time: .init(hour: 12, minute: 30), days: [.monday, .tuesday, .wednesday, .thursday, .friday])
        )
        let endOfDay = Ticker(
            id: UUID(),
            label: "End of Day",
            schedule: .weekdays(time: .init(hour: 17, minute: 0), days: [.monday, .tuesday, .wednesday, .thursday, .friday])
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([workDays, lunch, endOfDay])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: All should be kept
        XCTAssertTickersExist(in: context, tickerIDs: [workDays.id, lunch.id, endOfDay.id])
    }
    
    // MARK: - Edge Case Combinations
    
    func testSynchronize_EdgeCaseCombinations() async throws {
        // Given: Various edge cases combined
        let tickers = [
            Ticker.mockEmptyLabel, // Empty label
            Ticker.mockLongLabel, // Long label
            Ticker.mockSpecialCharactersLabel, // Special characters
            AlarmSynchronizationServiceTestHelpers.createTickerWithGeneratedIDs(
                id: UUID(),
                label: "Many IDs",
                generatedIDs: Array(repeating: UUID(), count: 100)
            ),
            Ticker.mockLeapYear, // Leap year
            Ticker.mockMonthlyDay31 // Day 31 edge case
        ]
        
        let context = try TestModelContextFactory.createContextWithTickers(tickers)
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Should handle all edge cases
        let descriptor = FetchDescriptor<Ticker>()
        let remainingTickers = try context.fetch(descriptor)
        
        // All should be kept (have upcoming alarms)
        for ticker in tickers {
            XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
        }
    }
}

