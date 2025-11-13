//
//  TickerConfigurationParserTests.swift
//  TickerCoreTests
//
//  Exhaustive unit tests exercising the natural language parsing pipeline
//  and schedule conversion logic in TickerConfigurationParser.
//

import XCTest
@testable import TickerCore

final class TickerConfigurationParserTests: XCTestCase {

    private var parser: TickerConfigurationParser!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        parser = TickerConfigurationParser()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
    }

    override func tearDown() {
        parser = nil
        calendar = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func assertSameDay(_ date: Date, as reference: Date, file: StaticString = #filePath, line: UInt = #line) {
        let lhs = calendar.dateComponents([.year, .month, .day], from: date)
        let rhs = calendar.dateComponents([.year, .month, .day], from: reference)
        XCTAssertEqual(lhs.year, rhs.year, "Years should match", file: file, line: line)
        XCTAssertEqual(lhs.month, rhs.month, "Months should match", file: file, line: line)
        XCTAssertEqual(lhs.day, rhs.day, "Days should match", file: file, line: line)
    }

    private func assertTime(_ time: TickerConfiguration.TimeOfDay, hour: Int, minute: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(time.hour, hour, "Hour mismatch", file: file, line: line)
        XCTAssertEqual(time.minute, minute, "Minute mismatch", file: file, line: line)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }

    private func timeComponents(for date: Date) -> (hour: Int, minute: Int) {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0, comps.minute ?? 0)
    }

    // MARK: - Natural Language Parsing Coverage

    func testParseConfiguration_TomorrowMorningMedicationWithCountdown() async throws {
        let now = Date()
        let input = "Remind me tomorrow at 7:45 am to take medication with a 30 minute countdown."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 7, minute: 45)
        if let expectedDate = calendar.date(byAdding: .day, value: 1, to: now) {
            assertSameDay(configuration.date, as: expectedDate)
        }

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertEqual(configuration.countdown, TickerConfiguration.CountdownConfiguration(hours: 0, minutes: 30, seconds: 0))
        XCTAssertEqual(configuration.label, "Medication")
        XCTAssertEqual(configuration.icon, "pills")
        XCTAssertEqual(configuration.colorHex, "#EF4444")
    }

    func testParseConfiguration_DailyMorningWorkout() async throws {
        let now = Date()
        let input = "Set my workout reminder every day at 6 am."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 6, minute: 0)
        assertSameDay(configuration.date, as: now)

        guard case .daily = configuration.repeatOption else {
            return XCTFail("Expected daily repeat option")
        }

        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Workout")
        XCTAssertEqual(configuration.icon, "figure.run")
        XCTAssertEqual(configuration.colorHex, "#FF6B35")
    }

    func testParseConfiguration_WeekdaysPattern() async throws {
        let now = Date()
        let input = "Schedule coffee check-in on weekdays at 9:00 am."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 9, minute: 0)
        assertSameDay(configuration.date, as: now)

        guard case .weekdays(let weekdays) = configuration.repeatOption else {
            return XCTFail("Expected weekdays repeat option")
        }

        XCTAssertEqual(Set(weekdays), Set([.monday, .tuesday, .wednesday, .thursday, .friday]))
        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Coffee")
        XCTAssertEqual(configuration.icon, "cup.and.saucer")
        XCTAssertEqual(configuration.colorHex, "#92400E")
    }

    func testParseConfiguration_SpecificWeekdays() async throws {
        let now = Date()
        let input = "Remind me every Monday and Wednesday at 5:30 pm to join the team sync."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 17, minute: 30)
        assertSameDay(configuration.date, as: now)

        guard case .weekdays(let weekdays) = configuration.repeatOption else {
            return XCTFail("Expected weekdays repeat option")
        }

        XCTAssertEqual(Set(weekdays), Set([.monday, .wednesday]))
        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Team Meeting")
        XCTAssertEqual(configuration.icon, "person.3")
        XCTAssertEqual(configuration.colorHex, "#3B82F6")
    }

    func testParseConfiguration_HourlyInterval() async throws {
        let now = Date()
        let input = "Every 3 hours starting at 9 am remind me to stretch."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 9, minute: 0)
        assertSameDay(configuration.date, as: now)

        guard case .hourly(let interval) = configuration.repeatOption else {
            return XCTFail("Expected hourly repeat option")
        }

        XCTAssertEqual(interval, 3)
        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Stretch")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_EveryFortyFiveMinutes() async throws {
        let now = Date()
        let input = "Starting at 8:15 am remind me every 45 minutes to stretch and breathe."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 8, minute: 15)
        assertSameDay(configuration.date, as: now)

        guard case .every(let interval, let unit) = configuration.repeatOption else {
            return XCTFail("Expected every repeat option")
        }

        XCTAssertEqual(interval, 45)
        XCTAssertEqual(unit, .minutes)
        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Stretch Breathe")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_EveryTwoDays() async throws {
        let now = Date()
        let input = "Starting tomorrow at 10 am remind me every 2 days to water the plants."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 10, minute: 0)

        if let expectedDate = calendar.date(byAdding: .day, value: 1, to: now) {
            assertSameDay(configuration.date, as: expectedDate)
        }

        guard case .every(let interval, let unit) = configuration.repeatOption else {
            return XCTFail("Expected every repeat option")
        }

        XCTAssertEqual(interval, 2)
        XCTAssertEqual(unit, .days)
        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Water Plants")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_EveryTwoWeeks() async throws {
        let now = Date()
        let input = "Remind me every 2 weeks at 10 am to review OKRs."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 10, minute: 0)
        assertSameDay(configuration.date, as: now)

        guard case .every(let interval, let unit) = configuration.repeatOption else {
            return XCTFail("Expected every repeat option")
        }

        XCTAssertEqual(interval, 2)
        XCTAssertEqual(unit, .weeks)
        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Review Okrs")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_BiweeklyPatternDefaultsProvidedWeekdays() async throws {
        let now = Date()
        let input = "Set a reminder for biweekly expense review at 4 pm."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 16, minute: 0)
        assertSameDay(configuration.date, as: now)

        guard case .biweekly(let weekdays) = configuration.repeatOption else {
            return XCTFail("Expected biweekly repeat option")
        }

        XCTAssertEqual(Set(weekdays), Set([.monday, .wednesday, .friday]))
        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Reminder")
        XCTAssertEqual(configuration.icon, "bell")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_MonthlyFixedDay() async throws {
        let now = Date()
        let input = "Set rent reminder monthly on the 15th at 10 am."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 10, minute: 0)
        assertSameDay(configuration.date, as: now)

        guard case .monthly(let monthlyDay) = configuration.repeatOption else {
            return XCTFail("Expected monthly repeat option")
        }

        switch monthlyDay {
        case .fixed(let value):
            XCTAssertEqual(value, 15)
        default:
            XCTFail("Expected fixed monthly day")
        }

        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Reminder")
        XCTAssertEqual(configuration.icon, "bell")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_MonthlyFirstWeekday() async throws {
        let now = Date()
        let input = "Schedule the status report monthly on the first Monday at 8 am."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 8, minute: 0)
        assertSameDay(configuration.date, as: now)

        guard case .monthly(let monthlyDay) = configuration.repeatOption else {
            return XCTFail("Expected monthly repeat option")
        }

        switch monthlyDay {
        case .firstWeekday(let weekday):
            XCTAssertEqual(weekday, TickerSchedule.Weekday.monday)
        default:
            XCTFail("Expected first weekday monthly pattern")
        }

        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Status Report")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_YearlyPatternDefaultsToJanuaryFirst() async throws {
        let now = Date()
        let input = "Schedule yearly dentist check at 2 pm."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 14, minute: 0)
        assertSameDay(configuration.date, as: now)

        guard case .yearly(let month, let day) = configuration.repeatOption else {
            return XCTFail("Expected yearly repeat option")
        }

        XCTAssertEqual(month, 1)
        XCTAssertEqual(day, 1)
        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Dentist Check")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_NaturalLanguageSunriseTime() async throws {
        let now = Date()
        let input = "Remind me tomorrow at sunrise to go running."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 6, minute: 30)
        if let expectedDate = calendar.date(byAdding: .day, value: 1, to: now) {
            assertSameDay(configuration.date, as: expectedDate)
        }

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Running")
        XCTAssertEqual(configuration.icon, "figure.run")
        XCTAssertEqual(configuration.colorHex, "#FF6B35")
    }

    func testParseConfiguration_RelativeTimeInTwoHours() async throws {
        let now = Date()
        let input = "In 2 hours remind me to drink water."

        let configuration = try await parser.parseConfiguration(from: input)

        let expectedDate = calendar.date(byAdding: .hour, value: 2, to: now) ?? now
        let expectedTime = timeComponents(for: expectedDate)

        XCTAssertEqual(configuration.time.hour, expectedTime.hour)
        XCTAssertEqual(configuration.time.minute, expectedTime.minute)
        assertSameDay(configuration.date, as: expectedDate)

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Drink Water")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_DefaultTimeFallsBackToNextHour() async throws {
        let now = Date()
        let input = "Remind me soon to send the follow up email."

        let configuration = try await parser.parseConfiguration(from: input)

        let expectedDate = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        let expectedTime = timeComponents(for: expectedDate)

        XCTAssertEqual(configuration.time.hour, expectedTime.hour)
        XCTAssertEqual(configuration.time.minute, expectedTime.minute)
        assertSameDay(configuration.date, as: expectedDate)

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Send Follow Up Email")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_CountdownMinutes() async throws {
        let input = "Schedule meeting tomorrow at 3 pm with a 45 minute countdown."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 15, minute: 0)
        if let expectedDate = calendar.date(byAdding: .day, value: 1, to: Date()) {
            assertSameDay(configuration.date, as: expectedDate)
        }

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertEqual(configuration.countdown, TickerConfiguration.CountdownConfiguration(hours: 0, minutes: 45, seconds: 0))
        XCTAssertEqual(configuration.label, "Meeting")
        XCTAssertEqual(configuration.icon, "person.3")
        XCTAssertEqual(configuration.colorHex, "#3B82F6")
    }

    func testParseConfiguration_CountdownHours() async throws {
        let input = "Remind me at 6 pm tomorrow with a countdown 2 hours before the flight."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 18, minute: 0)
        if let expectedDate = calendar.date(byAdding: .day, value: 1, to: Date()) {
            assertSameDay(configuration.date, as: expectedDate)
        }

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertEqual(configuration.countdown, TickerConfiguration.CountdownConfiguration(hours: 2, minutes: 0, seconds: 0))
        XCTAssertEqual(configuration.label, "Flight")
        XCTAssertEqual(configuration.icon, "airplane")
        XCTAssertEqual(configuration.colorHex, "#3B82F6")
    }

    func testParseConfiguration_CountdownSeconds() async throws {
        let input = "Set an alarm at 3 pm with a 45 second countdown."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 15, minute: 0)
        assertSameDay(configuration.date, as: Date())

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertEqual(configuration.countdown, TickerConfiguration.CountdownConfiguration(hours: 0, minutes: 0, seconds: 45))
        XCTAssertEqual(configuration.label, "Alarm")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_ActivityMappingForReading() async throws {
        let input = "Remind me tomorrow evening to continue reading my book."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 18, minute: 0)
        if let expectedDate = calendar.date(byAdding: .day, value: 1, to: Date()) {
            assertSameDay(configuration.date, as: expectedDate)
        }

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertNil(configuration.countdown)
        XCTAssertEqual(configuration.label, "Reading")
        XCTAssertEqual(configuration.icon, "book")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_TimeAndCountdownNumbersAreDisambiguated() async throws {
        let now = Date()
        let input = "Remind me at 8 pm with a 30 minute countdown to start cooking."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 20, minute: 0)
        assertSameDay(configuration.date, as: now)

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertEqual(configuration.countdown, TickerConfiguration.CountdownConfiguration(hours: 0, minutes: 30, seconds: 0))
        XCTAssertEqual(configuration.label, "Start Cooking")
        XCTAssertEqual(configuration.icon, "alarm")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    func testParseConfiguration_LabelNotEmptyForUnknownActivity() async throws {
        let input = "Create a reminder tomorrow at 1 pm for quarterly brainstorming."

        let configuration = try await parser.parseConfiguration(from: input)

        assertTime(configuration.time, hour: 13, minute: 0)
        if let expectedDate = calendar.date(byAdding: .day, value: 1, to: Date()) {
            assertSameDay(configuration.date, as: expectedDate)
        }

        guard case .oneTime = configuration.repeatOption else {
            return XCTFail("Expected one-time repeat option")
        }

        XCTAssertNil(configuration.countdown)
        XCTAssertFalse(configuration.label.isEmpty)
        XCTAssertEqual(configuration.icon, "bell")
        XCTAssertEqual(configuration.colorHex, "#8B5CF6")
    }

    // MARK: - Conversion Tests

    func testParseToTickerBuildsExpectedTicker() {
        let startDate = makeDate(year: 2025, month: 6, day: 1, hour: 9, minute: 0)
        let configuration = TickerConfiguration(
            label: "Morning Medication",
            time: .init(hour: 9, minute: 0),
            date: startDate,
            repeatOption: .daily,
            countdown: .init(hours: 1, minutes: 15, seconds: 0),
            icon: "pills",
            colorHex: "#EF4444"
        )

        let ticker = parser.parseToTicker(from: configuration)

        XCTAssertEqual(ticker.label, configuration.label)
        XCTAssertTrue(ticker.isEnabled)
        XCTAssertEqual(ticker.presentation.tintColorHex, configuration.colorHex)
        XCTAssertEqual(ticker.tickerData?.name, configuration.label)
        XCTAssertEqual(ticker.tickerData?.icon, configuration.icon)

        if let schedule = ticker.schedule {
            switch schedule {
            case .daily(let time):
                XCTAssertEqual(time.hour, configuration.time.hour)
                XCTAssertEqual(time.minute, configuration.time.minute)
            default:
                XCTFail("Expected daily ticker schedule")
            }
        } else {
            XCTFail("Ticker schedule should not be nil")
        }

        guard let countdown = ticker.countdown?.preAlert else {
            return XCTFail("Ticker countdown should be populated")
        }

        XCTAssertEqual(countdown.hours, configuration.countdown?.hours)
        XCTAssertEqual(countdown.minutes, configuration.countdown?.minutes)
        XCTAssertEqual(countdown.seconds, configuration.countdown?.seconds)
    }

    // MARK: - Validation Tests

    func testValidateConfiguration_WithValidConfiguration() {
        let futureDate = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let configuration = TickerConfiguration(
            label: "Focus Block",
            time: .init(hour: 10, minute: 30),
            date: futureDate,
            repeatOption: .weekdays([.monday, .tuesday, .wednesday]),
            countdown: .init(hours: 0, minutes: 15, seconds: 0),
            icon: "timer",
            colorHex: "#3B82F6"
        )

        let validation = parser.validateConfiguration(configuration)

        XCTAssertTrue(validation.isValid)
        XCTAssertFalse(validation.hasErrors)
        XCTAssertTrue(validation.warnings.isEmpty)
    }

    func testValidateConfiguration_InvalidTimeIntervalAndCountdown() {
        let pastDate = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let configuration = TickerConfiguration(
            label: "",
            time: .init(hour: 25, minute: 70),
            date: pastDate,
            repeatOption: .every(interval: 0, unit: .minutes),
            countdown: .init(hours: 0, minutes: 0, seconds: 0),
            icon: "alarm",
            colorHex: "#000000"
        )

        let validation = parser.validateConfiguration(configuration)

        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.hasErrors)

        XCTAssertTrue(validation.errors.contains(where: { $0.contains("Invalid hour") }))
        XCTAssertTrue(validation.errors.contains(where: { $0.contains("Invalid minute") }))
        XCTAssertTrue(validation.errors.contains(where: { $0.contains("Label cannot be empty") }))
        XCTAssertTrue(validation.errors.contains(where: { $0.contains("Invalid interval for") }))
        XCTAssertTrue(validation.errors.contains(where: { $0.contains("Countdown must be greater than 0 seconds") }))

        XCTAssertTrue(validation.warnings.contains(where: { $0.contains("Selected date is in the past") }))
    }

    func testValidateConfiguration_LongCountdownWarnings() {
        let futureDate = calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        let configuration = TickerConfiguration(
            label: "Long Prep",
            time: .init(hour: 8, minute: 0),
            date: futureDate,
            repeatOption: .oneTime,
            countdown: .init(hours: 13, minutes: 0, seconds: 0),
            icon: "alarm",
            colorHex: "#FFFFFF"
        )

        let validation = parser.validateConfiguration(configuration)

        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.warnings.contains(where: { $0.contains("very long") }))
        XCTAssertTrue(validation.warnings.contains(where: { $0.contains("consider if this is necessary") }))
    }
}

