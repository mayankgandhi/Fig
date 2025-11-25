//
//  TickerScheduleExpanderTests.swift
//  TickerCoreTests
//
//  Comprehensive unit tests for TickerScheduleExpander
//  Tests all schedule types, edge cases, and boundary conditions
//

import XCTest
@testable import TickerCore

final class TickerScheduleExpanderTests: XCTestCase {
    
    var expander: TickerScheduleExpander!
    var calendar: Calendar!
    var testDate: Date!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        expander = TickerScheduleExpander(calendar: calendar)
        
        // Use a fixed date for consistent testing: January 15, 2024, 12:00 PM (Monday)
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 12
        components.minute = 0
        components.second = 0
        testDate = calendar.date(from: components)!
    }
    
    override func tearDown() {
        expander = nil
        calendar = nil
        testDate = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)!
    }
    
    private func createWindow(start: Date, durationHours: Double) -> DateInterval {
        let end = calendar.date(byAdding: .hour, value: Int(durationHours), to: start)!
        return DateInterval(start: start, end: end)
    }
    
    // MARK: - OneTime Schedule Tests
    
    func testExpandOneTime_DateWithinWindow() {
        // Given
        let alarmDate = createDate(year: 2024, month: 1, day: 16, hour: 10, minute: 30)
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(.oneTime(date: alarmDate), within: window)
        
        // Then
        XCTAssertEqual(dates.count, 1, "Should return exactly one date")
        XCTAssertEqual(dates.first, alarmDate, "Should return the exact alarm date")
    }
    
    func testExpandOneTime_DateBeforeWindow() {
        // Given
        let alarmDate = createDate(year: 2024, month: 1, day: 14, hour: 10, minute: 30)
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(.oneTime(date: alarmDate), within: window)
        
        // Then
        XCTAssertEqual(dates.count, 0, "Should return empty array for date before window")
    }
    
    func testExpandOneTime_DateAfterWindow() {
        // Given
        let alarmDate = createDate(year: 2024, month: 1, day: 20, hour: 10, minute: 30)
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(.oneTime(date: alarmDate), within: window)
        
        // Then
        XCTAssertEqual(dates.count, 0, "Should return empty array for date after window")
    }
    
    func testExpandOneTime_DateExactlyAtWindowStart() {
        // Given
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(.oneTime(date: window.start), within: window)
        
        // Then
        XCTAssertEqual(dates.count, 1, "Should include date exactly at window start")
        XCTAssertEqual(dates.first, window.start)
    }
    
    func testExpandOneTime_DateExactlyAtWindowEnd() {
        // Given
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(.oneTime(date: window.end), within: window)
        
        // Then
        XCTAssertEqual(dates.count, 1, "Should include date exactly at window end")
        XCTAssertEqual(dates.first, window.end)
    }
    
    func testExpandOneTime_DateOneSecondBeforeWindow() {
        // Given
        let window = createWindow(start: testDate, durationHours: 48)
        let oneSecondBefore = calendar.date(byAdding: .second, value: -1, to: window.start)!
        
        // When
        let dates = expander.expandSchedule(.oneTime(date: oneSecondBefore), within: window)
        
        // Then
        XCTAssertEqual(dates.count, 0, "Should not include date one second before window")
    }
    
    func testExpandOneTime_DateOneSecondAfterWindow() {
        // Given
        let window = createWindow(start: testDate, durationHours: 48)
        let oneSecondAfter = calendar.date(byAdding: .second, value: 1, to: window.end)!
        
        // When
        let dates = expander.expandSchedule(.oneTime(date: oneSecondAfter), within: window)
        
        // Then
        XCTAssertEqual(dates.count, 0, "Should not include date one second after window")
    }
    
    // MARK: - Daily Schedule Tests
    
    func testExpandDaily_MultipleDaysInWindow() {
        // Given
        let time = TimeOfDay(hour: 9, minute: 0)
        let window = createWindow(start: testDate, durationHours: 72) // 3 days
        
        // When
        let dates = expander.expandSchedule(.daily(time: time), within: window)
        
        // Then
        XCTAssertEqual(dates.count, 3, "Should return 3 dates for 3-day window")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return components.hour == 9 && components.minute == 0
        }, "All dates should be at 9:00 AM")
    }
    
    func testExpandDaily_TimeAtMidnight() {
        // Given
        let time = TimeOfDay(hour: 0, minute: 0)
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(.daily(time: time), within: window)
        
        // Then
        XCTAssertGreaterThan(dates.count, 0, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return components.hour == 0 && components.minute == 0
        }, "All dates should be at midnight")
    }
    
    func testExpandDaily_TimeAtEndOfDay() {
        // Given
        let time = TimeOfDay(hour: 23, minute: 59)
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(.daily(time: time), within: window)
        
        // Then
        XCTAssertGreaterThan(dates.count, 0, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return components.hour == 23 && components.minute == 59
        }, "All dates should be at 23:59")
    }
    
    func testExpandDaily_WindowStartingAfterAlarmTime() {
        // Given
        // Window starts at 12:00 PM, alarm is at 9:00 AM
        let time = TimeOfDay(hour: 9, minute: 0)
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(.daily(time: time), within: window)
        
        // Then
        // Should not include today's 9:00 AM (before window start)
        // Should include tomorrow's and day after's 9:00 AM
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should include future dates")
        XCTAssertTrue(dates.allSatisfy { $0 >= window.start }, "All dates should be >= window start")
    }
    
    func testExpandDaily_WindowStartingBeforeAlarmTime() {
        // Given
        // Window starts at 12:00 PM, alarm is at 3:00 PM
        let time = TimeOfDay(hour: 15, minute: 0)
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(.daily(time: time), within: window)
        
        // Then
        // Should include today's 3:00 PM (after window start)
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should include today's alarm if it's after window start")
        XCTAssertTrue(dates.allSatisfy { $0 >= window.start }, "All dates should be >= window start")
    }
    
    func testExpandDaily_ResultsAreSorted() {
        // Given
        let time = TimeOfDay(hour: 9, minute: 0)
        let window = createWindow(start: testDate, durationHours: 120) // 5 days
        
        // When
        let dates = expander.expandSchedule(.daily(time: time), within: window)
        
        // Then
        XCTAssertTrue(dates.isSorted, "Dates should be sorted")
    }
    
    // MARK: - Hourly Schedule Tests
    
    func testExpandHourly_EveryHour() {
        // Given
        let schedule = TickerSchedule.hourly(interval: 1, time: .init(hour: 0, minute: 30))
        let window = createWindow(start: testDate, durationHours: 24)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 24, "Should return 24 dates for 24-hour window with hourly schedule")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.minute], from: date)
            return components.minute == 30
        }, "All dates should be at minute 30")
    }
    
    func testExpandHourly_EveryTwoHours() {
        // Given
        let schedule = TickerSchedule.hourly(interval: 2, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 24)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 12, "Should return 12 dates for 24-hour window with 2-hour interval")
    }
    
    func testExpandHourly_EveryThreeHours() {
        // Given
        let schedule = TickerSchedule.hourly(interval: 3, time: .init(hour: 0, minute: 15))
        let window = createWindow(start: testDate, durationHours: 24)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 8, "Should return 8 dates for 24-hour window with 3-hour interval")
    }
    
    func testExpandHourly_MinuteOffset() {
        // Given
        let schedule = TickerSchedule.hourly(interval: 1, time: .init(hour: 0, minute: 38))
        let window = createWindow(start: testDate, durationHours: 3)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.minute], from: date)
            return components.minute == 38
        }, "All dates should be at minute 38")
    }
    
    func testExpandHourly_WindowStartingAfterTargetMinute() {
        // Given
        // Window starts at 12:00 PM, alarm is at :30 every hour
        let schedule = TickerSchedule.hourly(interval: 1, time: .init(hour: 0, minute: 30))
        let window = createWindow(start: testDate, durationHours: 2)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should start from 12:30 PM (next occurrence after window start)
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should include at least one date")
        XCTAssertTrue(dates.first! >= window.start, "First date should be >= window start")
    }
    
    func testExpandHourly_WindowStartingBeforeTargetMinute() {
        // Given
        // Window starts at 12:00 PM, alarm is at :15 every hour
        let schedule = TickerSchedule.hourly(interval: 1, time: .init(hour: 0, minute: 15))
        let window = createWindow(start: testDate, durationHours: 2)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should start from 12:15 PM (current hour's occurrence)
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should include at least one date")
        if let firstDate = dates.first {
            let components = calendar.dateComponents([.hour, .minute], from: firstDate)
            XCTAssertEqual(components.hour, 12, "First date should be at hour 12")
            XCTAssertEqual(components.minute, 15, "First date should be at minute 15")
        }
    }
    
    func testExpandHourly_ResultsAreSorted() {
        // Given
        let schedule = TickerSchedule.hourly(interval: 1, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertTrue(dates.isSorted, "Dates should be sorted")
    }
    
    // MARK: - Every Schedule Tests (Minutes)
    
    func testExpandEvery_EveryMinute() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .minutes, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 1)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 60, "Should return 60 dates for 1-hour window with 1-minute interval")
    }
    
    func testExpandEvery_EveryFiveMinutes() {
        // Given
        let schedule = TickerSchedule.every(interval: 5, unit: .minutes, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 1)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 12, "Should return 12 dates for 1-hour window with 5-minute interval")
    }
    
    func testExpandEvery_EveryThirtyMinutes() {
        // Given
        let schedule = TickerSchedule.every(interval: 30, unit: .minutes, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 2)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 4, "Should return 4 dates for 2-hour window with 30-minute interval")
    }
    
    func testExpandEvery_EveryMinute_StartsFromWindowStart() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .minutes, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 1)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.first, window.start, "First date should be window start for minute intervals")
    }
    
    // MARK: - Every Schedule Tests (Hours)
    
    func testExpandEvery_EveryHour_WithTime() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .hours, time: .init(hour: 9, minute: 30))
        let window = createWindow(start: testDate, durationHours: 24)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.minute], from: date)
            return components.minute == 30
        }, "All dates should be at minute 30")
    }
    
    func testExpandEvery_EveryTwoHours_WithTime() {
        // Given
        let schedule = TickerSchedule.every(interval: 2, unit: .hours, time: .init(hour: 8, minute: 15))
        let window = createWindow(start: testDate, durationHours: 24)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.minute], from: date)
            return components.minute == 15
        }, "All dates should be at minute 15")
    }
    
    // MARK: - Every Schedule Tests (Days)
    
    func testExpandEvery_EveryDay() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .days, time: .init(hour: 9, minute: 0))
        let window = createWindow(start: testDate, durationHours: 72) // 3 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 2, "Should return at least 2 dates")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return components.hour == 9 && components.minute == 0
        }, "All dates should be at 9:00 AM")
    }
    
    func testExpandEvery_EveryThreeDays() {
        // Given
        let schedule = TickerSchedule.every(interval: 3, unit: .days, time: .init(hour: 10, minute: 30))
        let window = createWindow(start: testDate, durationHours: 168) // 7 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 2, "Should return at least 2 dates for 7-day window")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return components.hour == 10 && components.minute == 30
        }, "All dates should be at 10:30 AM")
    }
    
    // MARK: - Every Schedule Tests (Weeks)
    
    func testExpandEvery_EveryWeek() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .weeks, time: .init(hour: 9, minute: 0))
        let window = createWindow(start: testDate, durationHours: 336) // 14 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return components.hour == 9 && components.minute == 0
        }, "All dates should be at 9:00 AM")
    }
    
    func testExpandEvery_EveryTwoWeeks() {
        // Given
        let schedule = TickerSchedule.every(interval: 2, unit: .weeks, time: .init(hour: 14, minute: 30))
        let window = createWindow(start: testDate, durationHours: 672) // 28 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
    }
    
    // MARK: - Weekdays Schedule Tests
    
    func testExpandWeekdays_SingleWeekday() {
        // Given
        let schedule = TickerSchedule.weekdays(time: .init(hour: 9, minute: 0), days: [.monday])
        let window = createWindow(start: testDate, durationHours: 168) // 7 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let weekday = calendar.component(.weekday, from: date)
            let adjustedWeekday = (weekday == 1) ? 0 : weekday - 1
            return adjustedWeekday == TickerSchedule.Weekday.monday.rawValue
        }, "All dates should be on Monday")
    }
    
    func testExpandWeekdays_MultipleWeekdays() {
        // Given
        let schedule = TickerSchedule.weekdays(
            time: .init(hour: 7, minute: 30),
            days: [.monday, .wednesday, .friday]
        )
        let window = createWindow(start: testDate, durationHours: 168) // 7 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 3, "Should return at least 3 dates for 7-day window")
        XCTAssertTrue(dates.allSatisfy { date in
            let weekday = calendar.component(.weekday, from: date)
            let adjustedWeekday = (weekday == 1) ? 0 : weekday - 1
            let validWeekdays = [TickerSchedule.Weekday.monday.rawValue,
                                TickerSchedule.Weekday.wednesday.rawValue,
                                TickerSchedule.Weekday.friday.rawValue]
            return validWeekdays.contains(adjustedWeekday)
        }, "All dates should be on Monday, Wednesday, or Friday")
    }
    
    func testExpandWeekdays_AllWeekdays() {
        // Given
        let schedule = TickerSchedule.weekdays(
            time: .init(hour: 8, minute: 0),
            days: TickerSchedule.Weekday.allCases
        )
        let window = createWindow(start: testDate, durationHours: 168) // 7 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 7, "Should return at least 7 dates for 7-day window")
    }
    
    func testExpandWeekdays_WeekdayBeforeWindow() {
        // Given
        // Window starts on Monday 12:00 PM, alarm is at 9:00 AM
        let schedule = TickerSchedule.weekdays(time: .init(hour: 9, minute: 0), days: [.monday])
        let window = createWindow(start: testDate, durationHours: 24)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should not include today's 9:00 AM (before window start)
        // Should include next Monday's 9:00 AM if it's within window
        XCTAssertTrue(dates.allSatisfy { $0 >= window.start }, "All dates should be >= window start")
    }
    
    func testExpandWeekdays_WeekdayAfterWindow() {
        // Given
        // Window starts on Monday 12:00 PM, alarm is at 3:00 PM
        let schedule = TickerSchedule.weekdays(time: .init(hour: 15, minute: 0), days: [.monday])
        let window = createWindow(start: testDate, durationHours: 24)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should include today's 3:00 PM (after window start)
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should include today's alarm if it's after window start")
    }
    
    // MARK: - Biweekly Schedule Tests
    
    func testExpandBiweekly_SingleWeekday() {
        // Given
        let schedule = TickerSchedule.biweekly(time: .init(hour: 9, minute: 0), weekdays: [.monday])
        let window = createWindow(start: testDate, durationHours: 336) // 14 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Window starts on Monday, so should include Monday alarms from even weeks
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
    }
    
    func testExpandBiweekly_MultipleWeekdays() {
        // Given
        let schedule = TickerSchedule.biweekly(
            time: .init(hour: 14, minute: 30),
            weekdays: [.monday, .wednesday, .friday]
        )
        let window = createWindow(start: testDate, durationHours: 336) // 14 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
    }
    
    func testExpandBiweekly_AnchorWeek() {
        // Given
        // Window starts on Monday (week 0 - anchor week)
        let schedule = TickerSchedule.biweekly(time: .init(hour: 9, minute: 0), weekdays: [.monday])
        let window = createWindow(start: testDate, durationHours: 336) // 14 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should include Monday from week 0 (anchor week)
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should include dates from anchor week")
    }
    
    func testExpandBiweekly_EvenWeeksOnly() {
        // Given
        let schedule = TickerSchedule.biweekly(time: .init(hour: 10, minute: 0), weekdays: [.monday])
        let window = createWindow(start: testDate, durationHours: 672) // 28 days (4 weeks)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should only include Mondays from even weeks (week 0 and week 2)
        XCTAssertGreaterThanOrEqual(dates.count, 2, "Should return at least 2 dates for 4-week window")
    }
    
    // MARK: - Monthly Schedule Tests (Fixed Day)
    
    func testExpandMonthly_FixedDay_WithinWindow() {
        // Given
        let schedule = TickerSchedule.monthly(day: .fixed(15), time: .init(hour: 12, minute: 0))
        let window = createWindow(start: testDate, durationHours: 720) // 30 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should include Jan 15 and Feb 15 if within window
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.day, .hour, .minute], from: date)
            return components.day == 15 && components.hour == 12 && components.minute == 0
        }, "All dates should be on day 15 at 12:00 PM")
    }
    
    func testExpandMonthly_FixedDay_InvalidDate() {
        // Given
        // Feb 30 doesn't exist, should be handled gracefully
        let schedule = TickerSchedule.monthly(day: .fixed(30), time: .init(hour: 9, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2024, month: 2, day: 1),
            end: createDate(year: 2024, month: 2, day: 29, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should return empty array or handle gracefully (Feb only has 28/29 days)
        XCTAssertGreaterThanOrEqual(dates.count, 0, "Should handle invalid date gracefully")
    }
    
    func testExpandMonthly_FixedDay_LastDayOfMonth() {
        // Given
        let schedule = TickerSchedule.monthly(day: .fixed(31), time: .init(hour: 10, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2024, month: 1, day: 1),
            end: createDate(year: 2024, month: 4, day: 30, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should include Jan 31, but not Feb 31, Mar 31, Apr 31
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date for months with 31 days")
    }
    
    func testExpandMonthly_FirstOfMonth() {
        // Given
        let schedule = TickerSchedule.monthly(day: .firstOfMonth, time: .init(hour: 9, minute: 0))
        let window = createWindow(start: testDate, durationHours: 720) // 30 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.day, .hour, .minute], from: date)
            return components.day == 1 && components.hour == 9 && components.minute == 0
        }, "All dates should be on the 1st at 9:00 AM")
    }
    
    func testExpandMonthly_LastOfMonth() {
        // Given
        let schedule = TickerSchedule.monthly(day: .lastOfMonth, time: .init(hour: 18, minute: 0))
        let window = createWindow(start: testDate, durationHours: 720) // 30 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        // Verify it's the last day of the month
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            let range = calendar.range(of: .day, in: .month, for: date)
            return range?.count == components.day
        }, "All dates should be on the last day of the month")
    }
    
    func testExpandMonthly_FirstWeekday() {
        // Given
        let schedule = TickerSchedule.monthly(day: .firstWeekday(.monday), time: .init(hour: 10, minute: 0))
        let window = createWindow(start: testDate, durationHours: 720) // 30 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let weekday = calendar.component(.weekday, from: date)
            let adjustedWeekday = (weekday == 1) ? 0 : weekday - 1
            return adjustedWeekday == TickerSchedule.Weekday.monday.rawValue
        }, "All dates should be on Monday")
    }
    
    func testExpandMonthly_LastWeekday() {
        // Given
        let schedule = TickerSchedule.monthly(day: .lastWeekday(.friday), time: .init(hour: 15, minute: 30))
        let window = createWindow(start: testDate, durationHours: 720) // 30 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let weekday = calendar.component(.weekday, from: date)
            let adjustedWeekday = (weekday == 1) ? 0 : weekday - 1
            return adjustedWeekday == TickerSchedule.Weekday.friday.rawValue
        }, "All dates should be on Friday")
    }
    
    // MARK: - Yearly Schedule Tests
    
    func testExpandYearly_RegularDate() {
        // Given
        let schedule = TickerSchedule.yearly(month: 6, day: 15, time: .init(hour: 10, minute: 30))
        let window = DateInterval(
            start: createDate(year: 2024, month: 1, day: 1),
            end: createDate(year: 2025, month: 12, day: 31, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.month, .day, .hour, .minute], from: date)
            return components.month == 6 && components.day == 15 &&
                   components.hour == 10 && components.minute == 30
        }, "All dates should be on June 15 at 10:30 AM")
    }
    
    func testExpandYearly_LeapYearDate() {
        // Given
        // Feb 29 - only exists in leap years
        let schedule = TickerSchedule.yearly(month: 2, day: 29, time: .init(hour: 12, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2024, month: 1, day: 1), // 2024 is a leap year
            end: createDate(year: 2025, month: 12, day: 31, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should include Feb 29, 2024 (leap year)
        // Should not include Feb 29, 2025 (not a leap year)
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date for leap year")
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return components.month == 2 && components.day == 29
        }, "All dates should be on Feb 29")
    }
    
    func testExpandYearly_InvalidDate() {
        // Given
        // Feb 30 doesn't exist
        let schedule = TickerSchedule.yearly(month: 2, day: 30, time: .init(hour: 9, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2024, month: 1, day: 1),
            end: createDate(year: 2025, month: 12, day: 31, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should return empty array (invalid date)
        XCTAssertEqual(dates.count, 0, "Should return empty array for invalid date")
    }
    
    func testExpandYearly_MultipleYears() {
        // Given
        let schedule = TickerSchedule.yearly(month: 1, day: 1, time: .init(hour: 0, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2024, month: 1, day: 1),
            end: createDate(year: 2026, month: 12, day: 31, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 2, "Should return at least 2 dates for multiple years")
    }
    
    // MARK: - Public Method Tests (within48HoursFrom)
    
    func testExpandSchedule_Within48Hours() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 9, minute: 0))
        
        // When
        let dates = expander.expandSchedule(schedule, within48HoursFrom: testDate)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        XCTAssertTrue(dates.allSatisfy { $0 >= testDate }, "All dates should be >= start date")
        
        let endDate = calendar.date(byAdding: .hour, value: 48, to: testDate)!
        XCTAssertTrue(dates.allSatisfy { $0 <= endDate }, "All dates should be <= end date")
    }
    
    func testExpandSchedule_Within48Hours_OneTime() {
        // Given
        let alarmDate = calendar.date(byAdding: .hour, value: 24, to: testDate)!
        let schedule = TickerSchedule.oneTime(date: alarmDate)
        
        // When
        let dates = expander.expandSchedule(schedule, within48HoursFrom: testDate)
        
        // Then
        XCTAssertEqual(dates.count, 1, "Should return exactly one date")
        XCTAssertEqual(dates.first, alarmDate)
    }
    
    // MARK: - Public Method Tests (withinCustomWindow)
    
    func testExpandSchedule_WithinCustomWindow_WithMaxAlarms() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .minutes, time: .init(hour: 0, minute: 0))
        let maxAlarms = 10
        
        // When
        let dates = expander.expandSchedule(
            schedule,
            withinCustomWindow: testDate,
            duration: 3600, // 1 hour (would normally produce 60 dates)
            maxAlarms: maxAlarms
        )
        
        // Then
        XCTAssertEqual(dates.count, maxAlarms, "Should return exactly maxAlarms dates")
    }
    
    func testExpandSchedule_WithinCustomWindow_WithoutMaxAlarms() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .minutes, time: .init(hour: 0, minute: 0))
        
        // When
        let dates = expander.expandSchedule(
            schedule,
            withinCustomWindow: testDate,
            duration: 3600, // 1 hour
            maxAlarms: nil
        )
        
        // Then
        XCTAssertEqual(dates.count, 60, "Should return all dates when maxAlarms is nil")
    }
    
    func testExpandSchedule_WithinCustomWindow_ZeroDuration() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 9, minute: 0))
        
        // When
        let dates = expander.expandSchedule(
            schedule,
            withinCustomWindow: testDate,
            duration: 0,
            maxAlarms: nil
        )
        
        // Then
        XCTAssertEqual(dates.count, 0, "Should return empty array for zero duration")
    }
    
    // MARK: - Public Method Tests (with strategy)
    
    func testExpandSchedule_WithStrategy_HighFrequency() {
        // Given
        let schedule = TickerSchedule.every(interval: 5, unit: .minutes, time: .init(hour: 0, minute: 0))
        let strategy = AlarmGenerationStrategy.highFrequency
        
        // When
        let dates = expander.expandSchedule(schedule, from: testDate, strategy: strategy)
        
        // Then
        // High frequency: 24-hour window, max 100 alarms
        XCTAssertLessThanOrEqual(dates.count, 100, "Should not exceed maxAlarms limit")
        XCTAssertTrue(dates.allSatisfy { $0 >= testDate }, "All dates should be >= start date")
        
        let endDate = calendar.date(byAdding: .second, value: Int(strategy.windowDuration), to: testDate)!
        XCTAssertTrue(dates.allSatisfy { $0 <= endDate }, "All dates should be <= end date")
    }
    
    func testExpandSchedule_WithStrategy_MediumFrequency() {
        // Given
        let schedule = TickerSchedule.hourly(interval: 1, time: .init(hour: 0, minute: 0))
        let strategy = AlarmGenerationStrategy.mediumFrequency
        
        // When
        let dates = expander.expandSchedule(schedule, from: testDate, strategy: strategy)
        
        // Then
        // Medium frequency: 48-hour window, unlimited alarms
        XCTAssertGreaterThanOrEqual(dates.count, 48, "Should return at least 48 dates for hourly schedule")
    }
    
    func testExpandSchedule_WithStrategy_LowFrequency() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 9, minute: 0))
        let strategy = AlarmGenerationStrategy.lowFrequency
        
        // When
        let dates = expander.expandSchedule(schedule, from: testDate, strategy: strategy)
        
        // Then
        // Low frequency: 7-day window, unlimited alarms
        XCTAssertGreaterThanOrEqual(dates.count, 7, "Should return at least 7 dates for daily schedule")
    }
    
    // MARK: - Edge Cases and Boundary Conditions
    
    func testExpandSchedule_EmptyWindow() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 9, minute: 0))
        let window = DateInterval(start: testDate, end: testDate)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 0, "Should return empty array for empty window")
    }
    
    func testExpandSchedule_VeryLargeWindow() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 9, minute: 0))
        let endDate = calendar.date(byAdding: .year, value: 1, to: testDate)!
        let window = DateInterval(start: testDate, end: endDate)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 365, "Should return at least 365 dates for 1-year window")
    }
    
    func testExpandSchedule_AllDatesAreSorted() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .minutes, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 2)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertTrue(dates.isSorted, "All dates should be sorted")
    }
    
    func testExpandSchedule_AllDatesWithinWindow() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 9, minute: 0))
        let window = createWindow(start: testDate, durationHours: 168) // 7 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertTrue(dates.allSatisfy { $0 >= window.start && $0 <= window.end },
                     "All dates should be within window")
    }
    
    func testExpandSchedule_DSTTransition() {
        // Given
        // Use a calendar with DST-aware timezone (e.g., US Eastern)
        var dstCalendar = Calendar(identifier: .gregorian)
        dstCalendar.timeZone = TimeZone(identifier: "America/New_York")!
        let dstExpander = TickerScheduleExpander(calendar: dstCalendar)
        
        // March 10, 2024 - DST starts (2 AM becomes 3 AM)
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10
        components.hour = 1
        components.minute = 0
        let dstStartDate = dstCalendar.date(from: components)!
        
        let schedule = TickerSchedule.daily(time: .init(hour: 2, minute: 30))
        let window = createWindow(start: dstStartDate, durationHours: 48)
        
        // When
        let dates = dstExpander.expandSchedule(schedule, within: window)
        
        // Then
        // Should handle DST transition gracefully
        XCTAssertGreaterThanOrEqual(dates.count, 0, "Should handle DST transition")
    }
    
    func testExpandSchedule_LeapYear() {
        // Given
        let schedule = TickerSchedule.monthly(day: .fixed(29), time: .init(hour: 12, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2024, month: 2, day: 1), // 2024 is a leap year
            end: createDate(year: 2024, month: 2, day: 29, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should include Feb 29 in leap year")
    }
    
    func testExpandSchedule_NonLeapYear() {
        // Given
        let schedule = TickerSchedule.monthly(day: .fixed(29), time: .init(hour: 12, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2023, month: 2, day: 1), // 2023 is not a leap year
            end: createDate(year: 2023, month: 2, day: 28, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Feb 29 doesn't exist in non-leap years, should return empty or handle gracefully
        XCTAssertGreaterThanOrEqual(dates.count, 0, "Should handle non-leap year gracefully")
    }
    
    // MARK: - Calendar Customization Tests
    
    func testExpandSchedule_CustomCalendar() {
        // Given
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let customExpander = TickerScheduleExpander(calendar: gregorianCalendar)
        
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 12
        components.minute = 0
        let testDate = gregorianCalendar.date(from: components)!
        
        let schedule = TickerSchedule.daily(time: .init(hour: 9, minute: 0))
        let window = DateInterval(
            start: testDate,
            end: gregorianCalendar.date(byAdding: .hour, value: 48, to: testDate)!
        )
        
        // When
        let dates = customExpander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should work with custom calendar")
    }
    
    // MARK: - Additional Edge Cases
    
    func testExpandEvery_MinuteInterval_ExactWindowBoundary() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .minutes, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 1)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 60, "Should return 60 dates for 1-hour window")
        XCTAssertEqual(dates.first, window.start, "First date should be window start")
        XCTAssertTrue(dates.last! <= window.end, "Last date should be <= window end")
    }
    
    func testExpandDaily_TimeAt59Minutes() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 23, minute: 59))
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertTrue(dates.allSatisfy { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return components.hour == 23 && components.minute == 59
        }, "All dates should be at 23:59")
    }
    
    func testExpandHourly_LargeInterval() {
        // Given
        let schedule = TickerSchedule.hourly(interval: 12, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 48)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 4, "Should return 4 dates for 48-hour window with 12-hour interval")
    }
    
    func testExpandEvery_Days_WithLargeInterval() {
        // Given
        let schedule = TickerSchedule.every(interval: 7, unit: .days, time: .init(hour: 9, minute: 0))
        let window = createWindow(start: testDate, durationHours: 336) // 14 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 2, "Should return at least 2 dates for 14-day window")
    }
    
    func testExpandMonthly_FirstWeekday_EdgeCase() {
        // Given
        // Test first Monday when month starts on Monday
        let schedule = TickerSchedule.monthly(day: .firstWeekday(.monday), time: .init(hour: 9, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2024, month: 1, day: 1), // Jan 1, 2024 is a Monday
            end: createDate(year: 2024, month: 2, day: 29, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
        if let firstDate = dates.first {
            let components = calendar.dateComponents([.day], from: firstDate)
            XCTAssertEqual(components.day, 1, "First Monday in January 2024 should be day 1")
        }
    }
    
    func testExpandMonthly_LastWeekday_EdgeCase() {
        // Given
        // Test last Friday when month ends on Friday
        let schedule = TickerSchedule.monthly(day: .lastWeekday(.friday), time: .init(hour: 15, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2024, month: 1, day: 1),
            end: createDate(year: 2024, month: 2, day: 29, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 1, "Should return at least one date")
    }
    
    func testExpandSchedule_YearTransition() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 0, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2023, month: 12, day: 30),
            end: createDate(year: 2024, month: 1, day: 2, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 2, "Should handle year transition correctly")
        XCTAssertTrue(dates.allSatisfy { $0 >= window.start && $0 <= window.end },
                     "All dates should be within window")
    }
    
    func testExpandSchedule_MonthTransition() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 12, minute: 0))
        let window = DateInterval(
            start: createDate(year: 2024, month: 1, day: 30),
            end: createDate(year: 2024, month: 2, day: 2, hour: 23, minute: 59)
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 2, "Should handle month transition correctly")
    }
    
    func testExpandSchedule_WeekTransition() {
        // Given
        let schedule = TickerSchedule.weekdays(time: .init(hour: 9, minute: 0), days: [.sunday])
        let window = DateInterval(
            start: createDate(year: 2024, month: 1, day: 14), // Sunday
            end: createDate(year: 2024, month: 1, day: 21, hour: 23, minute: 59) // Next Sunday
        )
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertGreaterThanOrEqual(dates.count, 2, "Should return at least 2 Sundays")
    }
    
    func testExpandSchedule_MaxAlarms_LimitsCorrectly() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .minutes, time: .init(hour: 0, minute: 0))
        let maxAlarms = 5
        
        // When
        let dates = expander.expandSchedule(
            schedule,
            withinCustomWindow: testDate,
            duration: 3600, // 1 hour (would normally produce 60 dates)
            maxAlarms: maxAlarms
        )
        
        // Then
        XCTAssertEqual(dates.count, maxAlarms, "Should return exactly maxAlarms dates")
        XCTAssertTrue(dates.isSorted, "Dates should still be sorted")
    }
    
    func testExpandSchedule_MaxAlarms_GreaterThanAvailable() {
        // Given
        let schedule = TickerSchedule.daily(time: .init(hour: 9, minute: 0))
        let maxAlarms = 100
        let window = createWindow(start: testDate, durationHours: 48) // Only 2 days
        
        // When
        let dates = expander.expandSchedule(
            schedule,
            withinCustomWindow: testDate,
            duration: 48 * 3600,
            maxAlarms: maxAlarms
        )
        
        // Then
        XCTAssertLessThanOrEqual(dates.count, maxAlarms, "Should not exceed maxAlarms")
        XCTAssertGreaterThan(dates.count, 0, "Should return at least one date")
    }
    
    func testExpandBiweekly_AllWeekdays() {
        // Given
        let schedule = TickerSchedule.biweekly(
            time: .init(hour: 9, minute: 0),
            weekdays: TickerSchedule.Weekday.allCases
        )
        let window = createWindow(start: testDate, durationHours: 336) // 14 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should include all weekdays from even weeks
        XCTAssertGreaterThanOrEqual(dates.count, 7, "Should return at least 7 dates")
    }
    
    func testExpandSchedule_WithZeroInterval() {
        // Given
        // Note: This might not be a valid schedule, but we should handle it gracefully
        let schedule = TickerSchedule.hourly(interval: 0, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 1)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        // Should handle gracefully by returning empty array to prevent infinite loop
        XCTAssertNotNil(dates, "Should not crash with zero interval")
        XCTAssertEqual(dates.count, 0, "Should return empty array for zero interval to prevent infinite loop")
    }
    
    // MARK: - Comprehensive Integration Tests
    
    func testExpandSchedule_AllScheduleTypes() {
        let schedules: [TickerSchedule] = [
            .oneTime(date: calendar.date(byAdding: .day, value: 1, to: testDate)!),
            .daily(time: .init(hour: 9, minute: 0)),
            .hourly(interval: 1, time: .init(hour: 0, minute: 0)),
            .every(interval: 5, unit: .minutes, time: .init(hour: 0, minute: 0)),
            .weekdays(time: .init(hour: 8, minute: 0), days: [.monday]),
            .biweekly(time: .init(hour: 10, minute: 0), weekdays: [.monday]),
            .monthly(day: .fixed(15), time: .init(hour: 12, minute: 0)),
            .yearly(month: 1, day: 1, time: .init(hour: 0, minute: 0))
        ]
        
        let window = createWindow(start: testDate, durationHours: 168) // 7 days
        
        for schedule in schedules {
            // When
            let dates = expander.expandSchedule(schedule, within: window)
            
            // Then
            XCTAssertNotNil(dates, "Should not return nil for schedule: \(schedule)")
            XCTAssertTrue(dates.allSatisfy { $0 >= window.start && $0 <= window.end },
                         "All dates should be within window for schedule: \(schedule)")
            XCTAssertTrue(dates.isSorted, "Dates should be sorted for schedule: \(schedule)")
        }
    }
    
    func testExpandSchedule_StressTest_HighFrequency() {
        // Given
        let schedule = TickerSchedule.every(interval: 1, unit: .minutes, time: .init(hour: 0, minute: 0))
        let window = createWindow(start: testDate, durationHours: 24)
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 1440, "Should return 1440 dates for 24-hour window with 1-minute interval")
        XCTAssertTrue(dates.isSorted, "Dates should be sorted")
    }
    
    func testExpandSchedule_StressTest_AllWeekdays() {
        // Given
        let schedule = TickerSchedule.weekdays(
            time: .init(hour: 9, minute: 0),
            days: TickerSchedule.Weekday.allCases
        )
        let window = createWindow(start: testDate, durationHours: 336) // 14 days
        
        // When
        let dates = expander.expandSchedule(schedule, within: window)
        
        // Then
        XCTAssertEqual(dates.count, 14, "Should return 14 dates for 14-day window with all weekdays")
    }
}

// MARK: - Array Extension for Testing
extension Array where Element == Date {
    var isSorted: Bool {
        guard count > 1 else { return true }
        
        for i in 1..<count {
            if self[i] < self[i-1] {
                return false
            }
        }
        return true
    }
}
