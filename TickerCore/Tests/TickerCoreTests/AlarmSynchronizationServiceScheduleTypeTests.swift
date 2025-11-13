//
//  AlarmSynchronizationServiceScheduleTypeTests.swift
//  TickerCoreTests
//
//  Tests for each schedule type in synchronization
//

import XCTest
import SwiftData
@testable import TickerCore
import AlarmKit

@available(iOS 26.0, *)
final class AlarmSynchronizationServiceScheduleTypeTests: XCTestCase {
    
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
    
    // MARK: - OneTime Schedule Tests
    
    func testSynchronize_OneTimeSchedule_FutureDate() async throws {
        let ticker = Ticker.mockOneTimeFuture
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_OneTimeSchedule_PastDate() async throws {
        let ticker = Ticker.mockOneTimePast
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersNotExist(in: context, tickerIDs: [ticker.id])
    }
    
    // MARK: - Daily Schedule Tests
    
    func testSynchronize_DailySchedule_VariousTimes() async throws {
        let tickers = [
            Ticker.mockDailyMorning,
            Ticker.mockDailyMidnight,
            Ticker.mockDailyEndOfDay,
            Ticker.mockNoon
        ]
        
        let context = try TestModelContextFactory.createContextWithTickers(tickers)
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // All daily schedules should be kept (have upcoming alarms)
        for ticker in tickers {
            XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
        }
    }
    
    // MARK: - Hourly Schedule Tests
    
    func testSynchronize_HourlySchedule_EveryHour() async throws {
        let ticker = Ticker.mockHourly
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_HourlySchedule_EveryThreeHours() async throws {
        let ticker = Ticker.mockEveryThreeHours
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    // MARK: - Weekdays Schedule Tests
    
    func testSynchronize_WeekdaysSchedule_MultipleDays() async throws {
        let ticker = Ticker.mockWeekdays
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_WeekdaysSchedule_SingleDay() async throws {
        let ticker = Ticker.mockSingleWeekday
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_WeekdaysSchedule_AllDays() async throws {
        let ticker = Ticker.mockAllWeekdays
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    // MARK: - Biweekly Schedule Tests
    
    func testSynchronize_BiweeklySchedule() async throws {
        let ticker = Ticker.mockBiweekly
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    // MARK: - Monthly Schedule Tests
    
    func testSynchronize_MonthlySchedule_FixedDay() async throws {
        let ticker = Ticker.mockMonthlyFixed
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_MonthlySchedule_FirstWeekday() async throws {
        let ticker = Ticker.mockMonthlyFirstWeekday
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_MonthlySchedule_LastDay() async throws {
        let ticker = Ticker.mockMonthlyLastDay
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_MonthlySchedule_Day31() async throws {
        let ticker = Ticker.mockMonthlyDay31
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    // MARK: - Yearly Schedule Tests
    
    func testSynchronize_YearlySchedule() async throws {
        let ticker = Ticker.mockYearly
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_YearlySchedule_LeapYear() async throws {
        let ticker = Ticker.mockLeapYear
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    // MARK: - Every Schedule Tests
    
    func testSynchronize_EverySchedule_Minutes() async throws {
        let ticker = Ticker.mockEveryFiveMinutes
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_EverySchedule_EveryMinute() async throws {
        let ticker = Ticker.mockEveryMinute
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_EverySchedule_ThirtyMinutes() async throws {
        let ticker = Ticker.mockEveryThirtyMinutes
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_EverySchedule_Days() async throws {
        let ticker = Ticker.mockEveryThreeDays
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
    
    func testSynchronize_EverySchedule_Weeks() async throws {
        let ticker = Ticker.mockEveryTwoWeeks
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }
}

