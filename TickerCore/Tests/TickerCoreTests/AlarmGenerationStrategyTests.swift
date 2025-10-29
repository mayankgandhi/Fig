//
//  AlarmGenerationStrategyTests.swift
//  TickerCoreTests
//
//  Comprehensive tests for AlarmGenerationStrategy
//

import XCTest
@testable import TickerCore

final class AlarmGenerationStrategyTests: XCTestCase {

    // MARK: - Window Duration Tests

    func testHighFrequencyWindowDuration() {
        let strategy = AlarmGenerationStrategy.highFrequency
        XCTAssertEqual(strategy.windowDuration, 24 * 3600, "High frequency should have 24-hour window")
    }

    func testMediumFrequencyWindowDuration() {
        let strategy = AlarmGenerationStrategy.mediumFrequency
        XCTAssertEqual(strategy.windowDuration, 48 * 3600, "Medium frequency should have 48-hour window")
    }

    func testLowFrequencyWindowDuration() {
        let strategy = AlarmGenerationStrategy.lowFrequency
        XCTAssertEqual(strategy.windowDuration, 7 * 24 * 3600, "Low frequency should have 7-day window")
    }

    // MARK: - Max Alarms Tests

    func testHighFrequencyMaxAlarms() {
        let strategy = AlarmGenerationStrategy.highFrequency
        XCTAssertEqual(strategy.maxAlarms, 100, "High frequency should cap at 100 alarms")
    }

    func testMediumFrequencyMaxAlarms() {
        let strategy = AlarmGenerationStrategy.mediumFrequency
        XCTAssertNil(strategy.maxAlarms, "Medium frequency should have no alarm cap")
    }

    func testLowFrequencyMaxAlarms() {
        let strategy = AlarmGenerationStrategy.lowFrequency
        XCTAssertNil(strategy.maxAlarms, "Low frequency should have no alarm cap")
    }

    // MARK: - Regeneration Threshold Tests

    func testHighFrequencyRegenerationThreshold() {
        let strategy = AlarmGenerationStrategy.highFrequency
        XCTAssertEqual(strategy.regenerationThreshold, 12 * 3600, "High frequency threshold should be 12 hours")
    }

    func testMediumFrequencyRegenerationThreshold() {
        let strategy = AlarmGenerationStrategy.mediumFrequency
        XCTAssertEqual(strategy.regenerationThreshold, 24 * 3600, "Medium frequency threshold should be 24 hours")
    }

    func testLowFrequencyRegenerationThreshold() {
        let strategy = AlarmGenerationStrategy.lowFrequency
        XCTAssertEqual(strategy.regenerationThreshold, 3 * 24 * 3600, "Low frequency threshold should be 3 days")
    }

    // MARK: - Minimum Alarm Count Tests

    func testHighFrequencyMinimumAlarmCount() {
        let strategy = AlarmGenerationStrategy.highFrequency
        XCTAssertEqual(strategy.minimumAlarmCount, 20, "High frequency minimum should be 20 alarms")
    }

    func testMediumFrequencyMinimumAlarmCount() {
        let strategy = AlarmGenerationStrategy.mediumFrequency
        XCTAssertEqual(strategy.minimumAlarmCount, 12, "Medium frequency minimum should be 12 alarms")
    }

    func testLowFrequencyMinimumAlarmCount() {
        let strategy = AlarmGenerationStrategy.lowFrequency
        XCTAssertEqual(strategy.minimumAlarmCount, 3, "Low frequency minimum should be 3 alarms")
    }

    // MARK: - Strategy Detection - One Time

    func testDetermineStrategyOneTime() {
        let schedule = TickerSchedule.oneTime(Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "One-time should use low frequency")
    }

    // MARK: - Strategy Detection - Daily

    func testDetermineStrategyDaily() {
        let components = DateComponents(hour: 9, minute: 0)
        let schedule = TickerSchedule.daily(components)
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Daily should use low frequency")
    }

    // MARK: - Strategy Detection - Hourly

    func testDetermineStrategyHourlyOneHour() {
        let schedule = TickerSchedule.hourly(interval: 1, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .mediumFrequency, "Hourly (1h) should use medium frequency")
    }

    func testDetermineStrategyHourlyTwoHours() {
        let schedule = TickerSchedule.hourly(interval: 2, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .mediumFrequency, "Hourly (2h) should use medium frequency")
    }

    func testDetermineStrategyHourlyFourHours() {
        let schedule = TickerSchedule.hourly(interval: 4, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Hourly (4h+) should use low frequency")
    }

    // MARK: - Strategy Detection - Every (Minutes)

    func testDetermineStrategyEveryFiveMinutes() {
        let schedule = TickerSchedule.every(5, .minutes, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .highFrequency, "Every 5 minutes should use high frequency")
    }

    func testDetermineStrategyEveryThirtyMinutes() {
        let schedule = TickerSchedule.every(30, .minutes, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .highFrequency, "Every 30 minutes should use high frequency")
    }

    func testDetermineStrategyEveryFortyFiveMinutes() {
        let schedule = TickerSchedule.every(45, .minutes, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .mediumFrequency, "Every 45 minutes should use medium frequency")
    }

    // MARK: - Strategy Detection - Every (Hours)

    func testDetermineStrategyEveryOneHour() {
        let schedule = TickerSchedule.every(1, .hours, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .mediumFrequency, "Every 1 hour should use medium frequency")
    }

    func testDetermineStrategyEveryThreeHours() {
        let schedule = TickerSchedule.every(3, .hours, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .mediumFrequency, "Every 3 hours should use medium frequency")
    }

    func testDetermineStrategyEverySixHours() {
        let schedule = TickerSchedule.every(6, .hours, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Every 6 hours should use low frequency")
    }

    // MARK: - Strategy Detection - Every (Days/Weeks)

    func testDetermineStrategyEveryDay() {
        let schedule = TickerSchedule.every(1, .days, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Every day should use low frequency")
    }

    func testDetermineStrategyEveryWeek() {
        let schedule = TickerSchedule.every(1, .weeks, startingAt: Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Every week should use low frequency")
    }

    // MARK: - Strategy Detection - Weekdays

    func testDetermineStrategyWeekdays() {
        let components = DateComponents(hour: 9, minute: 0)
        let schedule = TickerSchedule.weekdays([.monday, .wednesday, .friday], at: components)
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Weekdays should use low frequency")
    }

    // MARK: - Strategy Detection - Biweekly

    func testDetermineStrategyBiweekly() {
        let schedule = TickerSchedule.biweekly(Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Biweekly should use low frequency")
    }

    // MARK: - Strategy Detection - Monthly

    func testDetermineStrategyMonthly() {
        let schedule = TickerSchedule.monthly(day: 15, at: DateComponents(hour: 10, minute: 0))
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Monthly should use low frequency")
    }

    // MARK: - Strategy Detection - Yearly

    func testDetermineStrategyYearly() {
        let schedule = TickerSchedule.yearly(Date())
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Yearly should use low frequency")
    }

    // MARK: - Display Tests

    func testDisplayNames() {
        XCTAssertEqual(AlarmGenerationStrategy.highFrequency.displayName, "High Frequency")
        XCTAssertEqual(AlarmGenerationStrategy.mediumFrequency.displayName, "Medium Frequency")
        XCTAssertEqual(AlarmGenerationStrategy.lowFrequency.displayName, "Low Frequency")
    }

    func testDescriptions() {
        let highDesc = AlarmGenerationStrategy.highFrequency.description
        XCTAssertTrue(highDesc.contains("5-30 minutes"))
        XCTAssertTrue(highDesc.contains("24h"))
        XCTAssertTrue(highDesc.contains("100"))

        let mediumDesc = AlarmGenerationStrategy.mediumFrequency.description
        XCTAssertTrue(mediumDesc.contains("Hourly"))
        XCTAssertTrue(mediumDesc.contains("48h"))

        let lowDesc = AlarmGenerationStrategy.lowFrequency.description
        XCTAssertTrue(lowDesc.contains("Daily"))
        XCTAssertTrue(lowDesc.contains("7-day"))
    }

    // MARK: - Codable Tests

    func testCodableEncoding() throws {
        let strategy = AlarmGenerationStrategy.highFrequency

        let encoder = JSONEncoder()
        let data = try encoder.encode(strategy)

        XCTAssertNotNil(data)
    }

    func testCodableDecoding() throws {
        let original = AlarmGenerationStrategy.mediumFrequency

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AlarmGenerationStrategy.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        XCTAssertEqual(AlarmGenerationStrategy.highFrequency, AlarmGenerationStrategy.highFrequency)
        XCTAssertNotEqual(AlarmGenerationStrategy.highFrequency, AlarmGenerationStrategy.mediumFrequency)
        XCTAssertNotEqual(AlarmGenerationStrategy.mediumFrequency, AlarmGenerationStrategy.lowFrequency)
    }

    // MARK: - Hashable Tests

    func testHashable() {
        let set: Set<AlarmGenerationStrategy> = [.highFrequency, .mediumFrequency, .lowFrequency]

        XCTAssertEqual(set.count, 3)
        XCTAssertTrue(set.contains(.highFrequency))
        XCTAssertTrue(set.contains(.mediumFrequency))
        XCTAssertTrue(set.contains(.lowFrequency))
    }
}
