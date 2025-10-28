//
//  TickerScheduleExpanderTests.swift
//  figTests
//
//  Unit tests for TickerScheduleExpander
//

import XCTest
@testable import Ticker

final class TickerScheduleExpanderTests: XCTestCase {
    var expander: TickerScheduleExpander!
    var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        expander = TickerScheduleExpander(calendar: calendar)
    }

    override func tearDown() {
        expander = nil
        calendar = nil
        super.tearDown()
    }

    // MARK: - One-Time Schedule Tests

    func testOneTimeSchedule_WithinWindow() {
        let alarmDate = createDate(year: 2025, month: 1, day: 15, hour: 9, minute: 0)
        let schedule = TickerSchedule.oneTime(date: alarmDate)

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let end = createDate(year: 2025, month: 1, day: 31, hour: 23, minute: 59)
        let window = DateInterval(start: start, end: end)

        let results = expander.expandSchedule(schedule, within: window)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, alarmDate)
    }

    func testOneTimeSchedule_OutsideWindow() {
        let alarmDate = createDate(year: 2025, month: 3, day: 15, hour: 9, minute: 0)
        let schedule = TickerSchedule.oneTime(date: alarmDate)

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let end = createDate(year: 2025, month: 1, day: 31, hour: 23, minute: 59)
        let window = DateInterval(start: start, end: end)

        let results = expander.expandSchedule(schedule, within: window)

        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Daily Schedule Tests

    func testDailySchedule() {
        let time = TickerSchedule.TimeOfDay(hour: 9, minute: 30)
        let schedule = TickerSchedule.daily(time: time)

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let end = createDate(year: 2025, month: 1, day: 5, hour: 23, minute: 59)
        let window = DateInterval(start: start, end: end)

        let results = expander.expandSchedule(schedule, within: window)

        XCTAssertEqual(results.count, 5) // 5 days
        for (index, date) in results.enumerated() {
            let components = calendar.dateComponents([.day, .hour, .minute], from: date)
            XCTAssertEqual(components.day, index + 1)
            XCTAssertEqual(components.hour, 9)
            XCTAssertEqual(components.minute, 30)
        }
    }

    // MARK: - Hourly Schedule Tests

    func testHourlySchedule() {
        let startTime = createDate(year: 2025, month: 1, day: 1, hour: 9, minute: 0)
        let endTime = createDate(year: 2025, month: 1, day: 1, hour: 17, minute: 0)
        let schedule = TickerSchedule.hourly(interval: 2, time: TickerSchedule.TimeOfDay(hour: 9, minute: 0))

        let window = DateInterval(start: startTime, end: endTime)
        let results = expander.expandSchedule(schedule, within: window)

        // Expected: 9:00, 11:00, 13:00, 15:00 = 4 alarms (within window)
        XCTAssertEqual(results.count, 4)
        XCTAssertEqual(calendar.component(.hour, from: results[0]), 9)
        XCTAssertEqual(calendar.component(.hour, from: results[1]), 11)
        XCTAssertEqual(calendar.component(.hour, from: results[2]), 13)
        XCTAssertEqual(calendar.component(.hour, from: results[3]), 15)
    }

    func testHourlySchedule_FutureStartDate() {
        // Test the scenario where start time is in the future (like October 19th)
        let startTime = createDate(year: 2025, month: 10, day: 19, hour: 9, minute: 0)
        let endTime = createDate(year: 2025, month: 10, day: 19, hour: 17, minute: 0)
        let schedule = TickerSchedule.hourly(interval: 2, time: TickerSchedule.TimeOfDay(hour: 9, minute: 0))

        // Window starts from "now" (January 1st) but should respect the future start time
        let windowStart = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let windowEnd = createDate(year: 2025, month: 12, day: 31, hour: 23, minute: 59)
        let window = DateInterval(start: windowStart, end: windowEnd)
        
        let results = expander.expandSchedule(schedule, within: window)

        // Expected: 9:00, 11:00, 13:00, 15:00, 17:00 on October 19th = 5 alarms
        XCTAssertEqual(results.count, 5)
        
        // Verify all alarms are on October 19th
        for result in results {
            let components = calendar.dateComponents([.month, .day], from: result)
            XCTAssertEqual(components.month, 10)
            XCTAssertEqual(components.day, 19)
        }
        
        // Verify the hours are correct
        XCTAssertEqual(calendar.component(.hour, from: results[0]), 9)
        XCTAssertEqual(calendar.component(.hour, from: results[1]), 11)
        XCTAssertEqual(calendar.component(.hour, from: results[2]), 13)
        XCTAssertEqual(calendar.component(.hour, from: results[3]), 15)
        XCTAssertEqual(calendar.component(.hour, from: results[4]), 17)
    }

    // MARK: - Weekdays Schedule Tests

    func testWeekdaysSchedule_MondayWednesdayFriday() {
        let time = TickerSchedule.TimeOfDay(hour: 10, minute: 0)
        let weekdays: Array<TickerSchedule.Weekday> = [.monday, .wednesday, .friday]
        let schedule = TickerSchedule.weekdays(time: time, days: weekdays)

        // Jan 1, 2025 is a Wednesday
        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let end = createDate(year: 2025, month: 1, day: 10, hour: 23, minute: 59)
        let window = DateInterval(start: start, end: end)

        let results = expander.expandSchedule(schedule, within: window)

        // Expected: Wed 1, Fri 3, Mon 6, Wed 8, Fri 10 = 5 alarms
        XCTAssertEqual(results.count, 5)

        let expectedDays = [1, 3, 6, 8, 10]
        for (index, date) in results.enumerated() {
            let day = calendar.component(.day, from: date)
            XCTAssertEqual(day, expectedDays[index])
        }
    }

    // MARK: - Monthly Schedule Tests

    func testMonthlySchedule_FixedDay() {
        let time = TickerSchedule.TimeOfDay(hour: 14, minute: 0)
        let schedule = TickerSchedule.monthly(day: .fixed(15), time: time)

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let end = createDate(year: 2025, month: 3, day: 31, hour: 23, minute: 59)
        let window = DateInterval(start: start, end: end)

        let results = expander.expandSchedule(schedule, within: window)

        // Expected: Jan 15, Feb 15, Mar 15 = 3 alarms
        XCTAssertEqual(results.count, 3)

        for (monthOffset, date) in results.enumerated() {
            let components = calendar.dateComponents([.month, .day, .hour], from: date)
            XCTAssertEqual(components.month, monthOffset + 1)
            XCTAssertEqual(components.day, 15)
            XCTAssertEqual(components.hour, 14)
        }
    }

    func testMonthlySchedule_FirstOfMonth() {
        let time = TickerSchedule.TimeOfDay(hour: 8, minute: 0)
        let schedule = TickerSchedule.monthly(day: .firstOfMonth, time: time)

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let end = createDate(year: 2025, month: 3, day: 31, hour: 23, minute: 59)
        let window = DateInterval(start: start, end: end)

        let results = expander.expandSchedule(schedule, within: window)

        XCTAssertEqual(results.count, 3)
        for date in results {
            XCTAssertEqual(calendar.component(.day, from: date), 1)
        }
    }

    func testMonthlySchedule_LastOfMonth() {
        let time = TickerSchedule.TimeOfDay(hour: 23, minute: 59)
        let schedule = TickerSchedule.monthly(day: .lastOfMonth, time: time)

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let end = createDate(year: 2025, month: 3, day: 31, hour: 23, minute: 59)
        let window = DateInterval(start: start, end: end)

        let results = expander.expandSchedule(schedule, within: window)

        XCTAssertEqual(results.count, 3)
        // Jan 31, Feb 28 (2025 is not a leap year), Mar 31
        XCTAssertEqual(calendar.component(.day, from: results[0]), 31)
        XCTAssertEqual(calendar.component(.day, from: results[1]), 28)
        XCTAssertEqual(calendar.component(.day, from: results[2]), 31)
    }

    // MARK: - Yearly Schedule Tests

    func testYearlySchedule() {
        let time = TickerSchedule.TimeOfDay(hour: 12, minute: 0)
        let schedule = TickerSchedule.yearly(month: 3, day: 15, time: time) // March 15

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let end = createDate(year: 2027, month: 12, day: 31, hour: 23, minute: 59)
        let window = DateInterval(start: start, end: end)

        let results = expander.expandSchedule(schedule, within: window)

        // Expected: Mar 15 2025, Mar 15 2026, Mar 15 2027 = 3 alarms
        XCTAssertEqual(results.count, 3)

        for (yearOffset, date) in results.enumerated() {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            XCTAssertEqual(components.year, 2025 + yearOffset)
            XCTAssertEqual(components.month, 3)
            XCTAssertEqual(components.day, 15)
        }
    }

    // MARK: - 48-Hour Window Tests

    func test48HourWindow_DailySchedule() {
        let time = TickerSchedule.TimeOfDay(hour: 9, minute: 30)
        let schedule = TickerSchedule.daily(time: time)

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let results = expander.expandSchedule(schedule, within48HoursFrom: start)

        // Should return 2 alarms (Jan 1 and Jan 2)
        XCTAssertEqual(results.count, 2)

        // Verify both days
        for (index, date) in results.enumerated() {
            let components = calendar.dateComponents([.day, .hour, .minute], from: date)
            XCTAssertEqual(components.day, index + 1) // Days 1, 2
            XCTAssertEqual(components.hour, 9)
            XCTAssertEqual(components.minute, 30)
        }
    }

    func test48HourWindow_HourlySchedule() {
        let startTime = createDate(year: 2025, month: 1, day: 1, hour: 9, minute: 0)
        let endTime = createDate(year: 2025, month: 1, day: 10, hour: 17, minute: 0)
        let schedule = TickerSchedule.hourly(interval: 6, time: TickerSchedule.TimeOfDay(hour: 9, minute: 0))

        let results = expander.expandSchedule(schedule, within48HoursFrom: startTime)

        // 48 hours / 6 hour interval = 8 alarms
        // Jan 1: 9:00, 15:00, 21:00
        // Jan 2: 3:00, 9:00, 15:00, 21:00
        // Jan 3: 3:00
        XCTAssertEqual(results.count, 8)
    }

    func test48HourWindow_WeekdaysSchedule() {
        let time = TickerSchedule.TimeOfDay(hour: 10, minute: 0)
        let weekdays: Array<TickerSchedule.Weekday> = [.monday, .wednesday, .friday]
        let schedule = TickerSchedule.weekdays(time: time, days: weekdays)

        // Jan 1, 2025 is a Wednesday
        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let results = expander.expandSchedule(schedule, within48HoursFrom: start)

        // Within 48 hours: Wed Jan 1, Fri Jan 3
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(calendar.component(.day, from: results[0]), 1) // Wednesday
        XCTAssertEqual(calendar.component(.day, from: results[1]), 3) // Friday
    }

    // MARK: - Every Schedule Tests

    func testEverySchedule_MinuteInterval() {
        // Test 4-minute intervals starting from current time
        let startTime = createDate(year: 2025, month: 1, day: 1, hour: 9, minute: 2) // Start at 9:02
        let endTime = createDate(year: 2025, month: 1, day: 1, hour: 9, minute: 20)   // End at 9:20
        let schedule = TickerSchedule.every(interval: 4, unit: .minutes, time: TickerSchedule.TimeOfDay(hour: 9, minute: 0))

        let window = DateInterval(start: startTime, end: endTime)
        let results = expander.expandSchedule(schedule, within: window)

        // Should generate alarms every 4 minutes starting from window.start (9:02)
        // Expected: 9:02, 9:06, 9:10, 9:14, 9:18 = 5 alarms
        XCTAssertEqual(results.count, 5)
        
        // Verify the intervals are correct
        for (index, date) in results.enumerated() {
            let expectedMinute = 2 + (index * 4)
            let actualMinute = calendar.component(.minute, from: date)
            XCTAssertEqual(actualMinute, expectedMinute, "Alarm \(index) should be at minute \(expectedMinute)")
        }
    }

    func testEverySchedule_MinuteInterval_FromSpecificTime() {
        // Test minute intervals starting from a specific time (not current time)
        let startTime = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let endTime = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 20)
        let schedule = TickerSchedule.every(interval: 5, unit: .minutes, time: TickerSchedule.TimeOfDay(hour: 0, minute: 0))

        let window = DateInterval(start: startTime, end: endTime)
        let results = expander.expandSchedule(schedule, within: window)

        // Should generate alarms every 5 minutes starting from 0:00
        // Expected: 0:00, 0:05, 0:10, 0:15, 0:20 = 5 alarms
        XCTAssertEqual(results.count, 5)
        
        for (index, date) in results.enumerated() {
            let expectedMinute = index * 5
            let actualMinute = calendar.component(.minute, from: date)
            XCTAssertEqual(actualMinute, expectedMinute, "Alarm \(index) should be at minute \(expectedMinute)")
        }
    }

    func testEverySchedule_HourInterval() {
        // Test hour intervals (should use the old logic)
        let startTime = createDate(year: 2025, month: 1, day: 1, hour: 8, minute: 0)
        let endTime = createDate(year: 2025, month: 1, day: 1, hour: 20, minute: 0)
        let schedule = TickerSchedule.every(interval: 3, unit: .hours, time: TickerSchedule.TimeOfDay(hour: 9, minute: 0))

        let window = DateInterval(start: startTime, end: endTime)
        let results = expander.expandSchedule(schedule, within: window)

        // Should find 9:00 AM and then generate every 3 hours
        // Expected: 9:00, 12:00, 15:00, 18:00 = 4 alarms
        XCTAssertEqual(results.count, 4)
        
        let expectedHours = [9, 12, 15, 18]
        for (index, date) in results.enumerated() {
            let actualHour = calendar.component(.hour, from: date)
            XCTAssertEqual(actualHour, expectedHours[index], "Alarm \(index) should be at hour \(expectedHours[index])")
        }
    }

    // MARK: - Strategy-Based Expansion Tests

    func testStrategyBasedExpansion_HighFrequency() {
        // Every 10 minutes
        let startTime = createDate(year: 2025, month: 1, day: 1, hour: 9, minute: 0)
        let endTime = createDate(year: 2025, month: 1, day: 10, hour: 17, minute: 0)
        let schedule = TickerSchedule.every(interval: 10, unit: .minutes, time: TickerSchedule.TimeOfDay(hour: 9, minute: 0))

        let strategy = AlarmGenerationStrategy.highFrequency
        let results = expander.expandSchedule(schedule, from: startTime, strategy: strategy)

        // High frequency: 24h window, max 100 alarms
        // 10 min interval = 6 per hour * 24h = 144 potential alarms
        // Should be capped at 100
        XCTAssertEqual(results.count, 100)
    }

    func testStrategyBasedExpansion_MediumFrequency() {
        let time = TickerSchedule.TimeOfDay(hour: 9, minute: 30)
        let schedule = TickerSchedule.daily(time: time)

        let strategy = AlarmGenerationStrategy.mediumFrequency
        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let results = expander.expandSchedule(schedule, from: start, strategy: strategy)

        // Medium frequency: 48h window, unlimited
        // Daily alarm = 2 alarms in 48 hours
        XCTAssertEqual(results.count, 2)
    }

    func testStrategyBasedExpansion_LowFrequency() {
        let time = TickerSchedule.TimeOfDay(hour: 14, minute: 0)
        let schedule = TickerSchedule.monthly(day: .fixed(15), time: time)

        let strategy = AlarmGenerationStrategy.lowFrequency
        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let results = expander.expandSchedule(schedule, from: start, strategy: strategy)

        // Low frequency: 7-day window, unlimited
        // Monthly alarm on 15th: should have Jan 15 within 7 days
        XCTAssertEqual(results.count, 1)
        let components = calendar.dateComponents([.day, .hour], from: results[0])
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 14)
    }

    // MARK: - Custom Window Tests

    func testCustomWindow_WithMaxAlarms() {
        let time = TickerSchedule.TimeOfDay(hour: 9, minute: 0)
        let schedule = TickerSchedule.daily(time: time)

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let duration: TimeInterval = 10 * 24 * 3600 // 10 days

        let results = expander.expandSchedule(
            schedule,
            withinCustomWindow: start,
            duration: duration,
            maxAlarms: 5
        )

        // 10 days of daily alarms, limited to 5
        XCTAssertEqual(results.count, 5)
    }

    func testCustomWindow_NoLimit() {
        let time = TickerSchedule.TimeOfDay(hour: 9, minute: 0)
        let schedule = TickerSchedule.daily(time: time)

        let start = createDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        let duration: TimeInterval = 5 * 24 * 3600 // 5 days

        let results = expander.expandSchedule(
            schedule,
            withinCustomWindow: start,
            duration: duration,
            maxAlarms: nil
        )

        // 5 days of daily alarms, no limit
        XCTAssertEqual(results.count, 5)
    }

    // MARK: - Helper Methods

    private func createDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = calendar.timeZone
        return calendar.date(from: components)!
    }
}
