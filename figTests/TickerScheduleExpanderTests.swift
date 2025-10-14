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
        let schedule = TickerSchedule.hourly(interval: 2, startTime: startTime, endTime: endTime)

        let window = DateInterval(start: startTime, end: endTime)
        let results = expander.expandSchedule(schedule, within: window)

        // Expected: 9:00, 11:00, 13:00, 15:00, 17:00 = 5 alarms
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(calendar.component(.hour, from: results[0]), 9)
        XCTAssertEqual(calendar.component(.hour, from: results[1]), 11)
        XCTAssertEqual(calendar.component(.hour, from: results[2]), 13)
        XCTAssertEqual(calendar.component(.hour, from: results[3]), 15)
        XCTAssertEqual(calendar.component(.hour, from: results[4]), 17)
    }

    // MARK: - Weekdays Schedule Tests

    func testWeekdaysSchedule_MondayWednesdayFriday() {
        let time = TickerSchedule.TimeOfDay(hour: 10, minute: 0)
        let weekdays: Set<TickerSchedule.Weekday> = [.monday, .wednesday, .friday]
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
