//
//  AlarmReliabilityTests.swift
//  TickerCoreTests
//
//  Tests for the defects behind "the alarm rings once and stops, no Dynamic
//  Island". Each test names the bug it pins down.
//

import XCTest
import SwiftData
import SwiftUI
import AlarmKit
@testable import TickerCore

@available(iOS 26.0, *)
final class AlarmReliabilityTests: XCTestCase {

    // MARK: - Schedule mapping

    /// The four copies of "is this schedule simple?" must agree, forever.
    /// They are now derived from one property; this asserts the derivation holds
    /// for every case of the enum, including ones added later.
    func test_usesNativeAlarmKitSchedule_matchesAlarmKitSchedule_forEveryScheduleCase() {
        let time = TimeOfDay(hour: 7, minute: 0)
        let schedules: [TickerSchedule] = [
            .oneTime(date: Date().addingTimeInterval(3600)),
            .daily(time: time),
            .weekdays(time: time, days: [.monday, .tuesday, .wednesday, .thursday, .friday]),
            .hourly(interval: 1, time: time),
            .every(interval: 30, unit: .minutes, time: time),
            .biweekly(time: time, weekdays: [.monday]),
            .monthly(day: .fixed(1), time: time),
            .yearly(month: 6, day: 1, time: time)
        ]

        for schedule in schedules {
            let ticker = Ticker(label: "t", schedule: schedule)
            XCTAssertEqual(
                ticker.usesNativeAlarmKitSchedule,
                ticker.alarmKitSchedule != nil,
                "Predicate drifted from alarmKitSchedule for \(schedule)"
            )
        }
    }

    /// `.weekdays` is natively expressible and must not fall back to expansion.
    /// It previously hit `default: return nil`, which put the most common alarm
    /// in the product onto the regeneration path.
    func test_weekdays_mapsToNativeWeeklyRecurrence() throws {
        let ticker = Ticker(
            label: "Work",
            schedule: .weekdays(
                time: TimeOfDay(hour: 7, minute: 0),
                days: [.monday, .wednesday, .friday]
            )
        )

        let schedule = try XCTUnwrap(ticker.alarmKitSchedule)
        guard case .relative(let relative) = schedule else {
            return XCTFail("Expected a relative schedule, got \(schedule)")
        }

        XCTAssertEqual(relative.time.hour, 7)
        XCTAssertEqual(relative.time.minute, 0)

        guard case .weekly(let days) = relative.repeats else {
            return XCTFail("Expected weekly recurrence, got \(relative.repeats)")
        }
        XCTAssertEqual(Set(days), Set([.monday, .wednesday, .friday]))
    }

    /// A pre-alert that pushes the start time back across midnight must also
    /// rotate the weekday set. Mapping the days straight through alerts a full
    /// day late, every week.
    func test_weekdays_withPreAlertCrossingMidnight_shiftsWeekdayBackOneDay() throws {
        let ticker = Ticker(
            label: "Midnight",
            schedule: .weekdays(time: TimeOfDay(hour: 0, minute: 30), days: [.monday]),
            countdown: TickerCountdown(
                preAlert: .init(hours: 1, minutes: 0, seconds: 0)
            )
        )

        let schedule = try XCTUnwrap(ticker.alarmKitSchedule)
        guard case .relative(let relative) = schedule else {
            return XCTFail("Expected a relative schedule")
        }

        // 00:30 minus one hour is 23:30 the previous day.
        XCTAssertEqual(relative.time.hour, 23)
        XCTAssertEqual(relative.time.minute, 30)

        guard case .weekly(let days) = relative.repeats else {
            return XCTFail("Expected weekly recurrence")
        }
        XCTAssertEqual(Set(days), Set([.sunday]), "Weekday should roll back to Sunday")
    }

    func test_daily_withoutPreAlert_keepsAllSevenDaysAndTime() throws {
        let ticker = Ticker(label: "Daily", schedule: .daily(time: TimeOfDay(hour: 6, minute: 45)))

        let schedule = try XCTUnwrap(ticker.alarmKitSchedule)
        guard case .relative(let relative) = schedule,
              case .weekly(let days) = relative.repeats else {
            return XCTFail("Expected weekly recurrence")
        }

        XCTAssertEqual(relative.time.hour, 6)
        XCTAssertEqual(relative.time.minute, 45)
        XCTAssertEqual(days.count, 7)
    }

    func test_expansionSchedules_haveNoNativeMapping() {
        let time = TimeOfDay(hour: 9, minute: 0)
        let expansionOnly: [TickerSchedule] = [
            .hourly(interval: 2, time: time),
            .every(interval: 15, unit: .minutes, time: time),
            .biweekly(time: time, weekdays: [.friday]),
            .monthly(day: .lastOfMonth, time: time),
            .yearly(month: 12, day: 25, time: time)
        ]

        for schedule in expansionOnly {
            let ticker = Ticker(label: "t", schedule: schedule)
            XCTAssertNil(ticker.alarmKitSchedule, "\(schedule) should still be expanded")
        }
    }

    func test_weekdays_withNoDays_hasNoSchedule() {
        let ticker = Ticker(
            label: "Empty",
            schedule: .weekdays(time: TimeOfDay(hour: 7, minute: 0), days: [])
        )
        XCTAssertNil(ticker.alarmKitSchedule)
    }

    // MARK: - Countdown / presentation gating

    /// The presentation and the countdown duration must gate on the same thing.
    /// They used to disagree (`countdown != nil` vs `preAlert != nil`), which
    /// produced a countdown presentation with a nil countdown duration.
    func test_presentationAndCountdownDuration_agreeOnGate() {
        let builder = AlarmConfigurationBuilder()
        let duration = TickerCountdown.CountdownDuration(hours: 0, minutes: 5, seconds: 0)

        let countdowns: [TickerCountdown?] = [
            nil,
            TickerCountdown(preAlert: duration, postAlert: nil),
            TickerCountdown(preAlert: nil, postAlert: .snooze(duration: duration)),
            TickerCountdown(preAlert: duration, postAlert: .snooze(duration: duration))
        ]

        for countdown in countdowns {
            let ticker = Ticker(
                label: "Gate",
                schedule: .daily(time: TimeOfDay(hour: 7, minute: 0)),
                countdown: countdown
            )
            let presentation = builder.buildPresentation(from: ticker)
            let presentationHasCountdown = presentation.countdown != nil

            XCTAssertEqual(
                presentationHasCountdown,
                ticker.hasPreAlertCountdown,
                "Presentation/duration gate disagreement for countdown: \(String(describing: countdown))"
            )
        }
    }

    /// `postAlert` used to be discarded whenever there was no pre-alert, so the
    /// snooze interval never reached AlarmKit.
    func test_postAlertSurvives_whenThereIsNoPreAlert() throws {
        let ticker = Ticker(
            label: "Snooze only",
            schedule: .daily(time: TimeOfDay(hour: 7, minute: 0)),
            countdown: TickerCountdown(
                preAlert: nil,
                postAlert: .snooze(duration: .init(hours: 0, minutes: 9, seconds: 0))
            )
        )

        let duration = try XCTUnwrap(ticker.alarmKitCountdownDuration)
        XCTAssertNil(duration.preAlert)
        XCTAssertEqual(try XCTUnwrap(duration.postAlert), 9 * 60, accuracy: 0.5)
    }

    func test_countdownDuration_isNil_whenThereIsNoCountdownAtAll() {
        let ticker = Ticker(label: "Plain", schedule: .daily(time: TimeOfDay(hour: 7, minute: 0)))
        XCTAssertNil(ticker.alarmKitCountdownDuration)
    }

    // MARK: - Configuration builder

    /// The `guard let configuration` at every call site was dead code, because
    /// `buildConfiguration` could never return nil — which hid exactly the
    /// misconfiguration it was supposed to catch.
    func test_buildConfiguration_returnsNil_whenThereIsNoScheduleAndNoCountdown() {
        let builder = AlarmConfigurationBuilder()
        let ticker = Ticker(label: "Nothing", schedule: nil, countdown: nil)
        XCTAssertNil(builder.buildConfiguration(from: ticker, occurrenceAlarmID: UUID()))
    }

    /// A sound name with no file extension used to crash on `fileComponents[1]`.
    func test_buildConfiguration_survivesSoundNameWithoutExtension() {
        let builder = AlarmConfigurationBuilder()
        let ticker = Ticker(
            label: "Odd sound",
            schedule: .daily(time: TimeOfDay(hour: 7, minute: 0)),
            soundName: "chime"
        )
        XCTAssertNotNil(builder.buildConfiguration(from: ticker, occurrenceAlarmID: UUID()))
    }

    /// A `.countdown` secondary behavior with no countdown to restart is an
    /// invalid configuration that AlarmKit rejects at schedule time.
    func test_repeatButton_isDropped_whenThereIsNoCountdown() throws {
        let builder = AlarmConfigurationBuilder()
        let ticker = Ticker(
            label: "Repeat without countdown",
            schedule: .daily(time: TimeOfDay(hour: 7, minute: 0)),
            countdown: nil,
            presentation: TickerPresentation(secondaryButtonType: .countdown)
        )

        let presentation = builder.buildPresentation(from: ticker)
        XCTAssertNil(presentation.alert.secondaryButtonBehavior)
        XCTAssertNil(presentation.alert.secondaryButton)
    }

    // MARK: - Budget

    func test_budget_allowsNothing_whenGlobalLimitIsReached() {
        XCTAssertEqual(
            AlarmBudget.allowance(
                currentGlobalCount: AlarmBudget.maxScheduledAlarms,
                currentTickerCount: 0
            ),
            0
        )
    }

    func test_budget_isCappedPerTicker_soOneScheduleCannotStarveTheOthers() {
        let allowance = AlarmBudget.allowance(currentGlobalCount: 0, currentTickerCount: 0)
        XCTAssertEqual(allowance, AlarmBudget.maxAlarmsPerTicker)
        XCTAssertLessThanOrEqual(allowance, AlarmBudget.maxScheduledAlarms)
    }

    func test_budget_neverReturnsNegativeAllowance() {
        XCTAssertEqual(
            AlarmBudget.allowance(
                currentGlobalCount: AlarmBudget.maxScheduledAlarms + 25,
                currentTickerCount: AlarmBudget.maxAlarmsPerTicker + 10
            ),
            0
        )
    }

    /// Every strategy must be bounded. `.mediumFrequency` and `.lowFrequency`
    /// returned nil (unlimited), which is how the per-app budget got exhausted.
    func test_everyGenerationStrategy_hasAnAlarmCap() {
        for strategy in [AlarmGenerationStrategy.highFrequency, .mediumFrequency, .lowFrequency] {
            XCTAssertNotNil(strategy.maxAlarms, "\(strategy) is unbounded")
            XCTAssertLessThanOrEqual(strategy.maxAlarms ?? .max, AlarmBudget.maxAlarmsPerTicker)
        }
    }

    // MARK: - Colour fallback

    /// `Color(hex: metadata?.colorHex ?? "#000000") ?? .primary` never fell back,
    /// because "000000" parses successfully — so a missing colour rendered black
    /// on the permanently black Dynamic Island.
    func test_colorHexFallback_isReachable_whenHexIsMissing() {
        let colorHex: String? = nil
        let resolved = colorHex.flatMap(Color.init(hex:)) ?? TickerColor.primary
        XCTAssertEqual(resolved, TickerColor.primary)

        // And the old idiom demonstrably does not fall back.
        XCTAssertNotNil(Color(hex: "#000000"), "'#000000' parses, so `?? fallback` is unreachable")
    }

    // MARK: - Test infrastructure

    /// The fake scheduler is what makes every error path above testable, so it
    /// gets its own test.
    func test_fakeScheduler_canBuildRealAlarmsAndReportLimitReached() async throws {
        let scheduler = FakeAlarmScheduler()
        let builder = AlarmConfigurationBuilder()
        let ticker = Ticker(label: "Budgeted", schedule: .daily(time: TimeOfDay(hour: 7, minute: 0)))
        let configuration = try XCTUnwrap(builder.buildConfiguration(from: ticker, occurrenceAlarmID: UUID()))

        scheduler.scheduleLimit = 1
        _ = try await scheduler.schedule(id: UUID(), configuration: configuration)
        XCTAssertEqual(try scheduler.alarms.count, 1)

        do {
            _ = try await scheduler.schedule(id: UUID(), configuration: configuration)
            XCTFail("Expected maximumLimitReached")
        } catch let error as AlarmManager.AlarmError {
            XCTAssertEqual(error, .maximumLimitReached)
        }
    }
}
