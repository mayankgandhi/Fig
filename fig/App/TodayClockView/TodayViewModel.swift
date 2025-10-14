//
//  TodayViewModel.swift
//  fig
//
//  ViewModel for TodayClockView using MVVM architecture
//  Handles all business logic for upcoming alarm display and clock visualization
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - TodayViewModel

@Observable
final class TodayViewModel {

    // MARK: - Dependencies

    private let tickerService: TickerService
    private let modelContext: ModelContext
    private let calendar: Calendar

    // MARK: - Computed Properties

    /// All enabled alarms from TickerService
    @MainActor
    private var allEnabledAlarms: [Ticker] {
        tickerService.getAlarmsWithMetadata(context: modelContext).filter { $0.isEnabled }
    }

    /// Alarms scheduled within the next 12 hours, sorted by time
    @MainActor
    var upcomingAlarms: [UpcomingAlarmPresentation] {
        let now = Date()
        let next12Hours = now.addingTimeInterval(12 * 60 * 60)

        return allEnabledAlarms
            .filter { alarm in
                guard alarm.schedule != nil else { return false }
                let nextTime = getNextAlarmTime(for: alarm, from: now)
                return nextTime >= now && nextTime <= next12Hours
            }
            .sorted { alarm1, alarm2 in
                let time1 = getNextAlarmTime(for: alarm1, from: now)
                let time2 = getNextAlarmTime(for: alarm2, from: now)
                return time1 < time2
            }
            .map { createPresentation(from: $0, currentTime: now) }
    }

    /// Number of upcoming alarms
    @MainActor
    var upcomingAlarmsCount: Int {
        upcomingAlarms.count
    }

    /// Whether there are any upcoming alarms
    @MainActor
    var hasUpcomingAlarms: Bool {
        !upcomingAlarms.isEmpty
    }

    // MARK: - Initialization

    init(tickerService: TickerService, modelContext: ModelContext, calendar: Calendar = .current) {
        self.tickerService = tickerService
        self.modelContext = modelContext
        self.calendar = calendar
    }

    // MARK: - Presentation Model Creation

    private func createPresentation(from alarm: Ticker, currentTime: Date) -> UpcomingAlarmPresentation {
        let nextTime = getNextAlarmTime(for: alarm, from: currentTime)
        let scheduleType: UpcomingAlarmPresentation.ScheduleType = {
            guard let schedule = alarm.schedule else { return .oneTime }
            switch schedule {
            case .oneTime: return .oneTime
            case .daily: return .daily
            case .weekdays(_, let days):
                return .weekdays(days.map { $0.rawValue })
            case .hourly(let interval, _, _):
                return .hourly(interval: interval)
            case .biweekly: return .biweekly
            case .monthly: return .monthly
            case .yearly: return .yearly
            }
        }()

        // Extract hour and minute for angle calculation
        let hour = calendar.component(.hour, from: nextTime)
        let minute = calendar.component(.minute, from: nextTime)

        return UpcomingAlarmPresentation(
            id: alarm.id,
            displayName: alarm.displayName,
            icon: alarm.tickerData?.icon ?? "alarm",
            color: extractColor(from: alarm),
            nextAlarmTime: nextTime,
            scheduleType: scheduleType,
            hour: hour,
            minute: minute,
            hasCountdown: alarm.countdown?.preAlert != nil,
            tickerDataTitle: alarm.tickerData?.name
        )
    }

    // MARK: - Helper Methods

    /// Calculates the next occurrence of a daily alarm time
    private func getNextOccurrence(for time: TickerSchedule.TimeOfDay, from date: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0

        guard let todayOccurrence = calendar.date(from: components) else {
            return date
        }

        // If today's occurrence has passed, return tomorrow's
        if todayOccurrence <= date {
            return calendar.date(byAdding: .day, value: 1, to: todayOccurrence) ?? todayOccurrence
        }

        return todayOccurrence
    }

    /// Gets the next alarm time for any alarm type
    private func getNextAlarmTime(for alarm: Ticker, from date: Date) -> Date {
        guard let schedule = alarm.schedule else { return Date.distantFuture }

        switch schedule {
        case .oneTime(let alarmDate):
            return alarmDate

        case .daily(let time):
            return getNextOccurrence(for: time, from: date)

        case .weekdays(let time, let days):
            return getNextWeekdayOccurrence(for: time, days: days, from: date)

        case .hourly(let interval, let startTime, let endTime):
            return getNextHourlyOccurrence(interval: interval, startTime: startTime, endTime: endTime, from: date)

        case .biweekly(let time, let weekdays, let anchorDate):
            return getNextBiweeklyOccurrence(for: time, weekdays: weekdays, anchorDate: anchorDate, from: date)

        case .monthly(let day, let time):
            return getNextMonthlyOccurrence(day: day, time: time, from: date)

        case .yearly(let month, let day, let time):
            return getNextYearlyOccurrence(month: month, day: day, time: time, from: date)
        }
    }

    /// Calculates the next occurrence for weekdays schedule
    private func getNextWeekdayOccurrence(for time: TickerSchedule.TimeOfDay, days: [TickerSchedule.Weekday], from date: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0

        // Check next 7 days
        for dayOffset in 0..<7 {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: date) else { continue }
            let weekday = calendar.component(.weekday, from: checkDate) - 1 // 0 = Sunday

            if days.contains(where: { $0.rawValue == weekday }) {
                var checkComponents = calendar.dateComponents([.year, .month, .day], from: checkDate)
                checkComponents.hour = time.hour
                checkComponents.minute = time.minute
                checkComponents.second = 0

                if let occurrence = calendar.date(from: checkComponents), occurrence > date {
                    return occurrence
                }
            }
        }

        return Date.distantFuture
    }

    /// Calculates the next occurrence for hourly schedule
    private func getNextHourlyOccurrence(interval: Int, startTime: Date, endTime: Date?, from date: Date) -> Date {
        var current = max(startTime, date)

        while current < (endTime ?? Date.distantFuture) {
            if current > date {
                return current
            }
            current = calendar.date(byAdding: .hour, value: interval, to: current) ?? Date.distantFuture
        }

        return Date.distantFuture
    }

    /// Calculates the next occurrence for biweekly schedule
    private func getNextBiweeklyOccurrence(for time: TickerSchedule.TimeOfDay, weekdays: [TickerSchedule.Weekday], anchorDate: Date, from date: Date) -> Date {
        // Calculate which week we're in relative to anchor
        let daysSinceAnchor = calendar.dateComponents([.day], from: anchorDate, to: date).day ?? 0
        let weeksSinceAnchor = daysSinceAnchor / 7
        let isActiveWeek = weeksSinceAnchor % 2 == 0

        // If this is an active week, check remaining days
        if isActiveWeek {
        let nextOccurrence = getNextWeekdayOccurrence(for: time, days: weekdays, from: date)
            if
               nextOccurrence <= calendar.date(byAdding: .day, value: 7 - (daysSinceAnchor % 7), to: date) ?? Date.distantFuture {
                return nextOccurrence
            }
        }

        // Check next active week
        let daysToNextActiveWeek = isActiveWeek ? 14 : 7
        guard let nextActiveWeek = calendar.date(byAdding: .day, value: daysToNextActiveWeek, to: date) else {
            return Date.distantFuture
        }

        return getNextWeekdayOccurrence(for: time, days: weekdays, from: nextActiveWeek)
    }

    /// Calculates the next occurrence for monthly schedule
    private func getNextMonthlyOccurrence(day: TickerSchedule.MonthlyDay, time: TickerSchedule.TimeOfDay, from date: Date) -> Date {
        // Simplified implementation - check current and next month
        for monthOffset in 0..<2 {
            guard let checkMonth = calendar.date(byAdding: .month, value: monthOffset, to: date) else { continue }

            if let occurrence = getMonthlyDate(day: day, time: time, in: checkMonth), occurrence > date {
                return occurrence
            }
        }

        return Date.distantFuture
    }

    /// Helper to get specific day in a month
    private func getMonthlyDate(day: TickerSchedule.MonthlyDay, time: TickerSchedule.TimeOfDay, in month: Date) -> Date? {
        var components = calendar.dateComponents([.year, .month], from: month)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0

        switch day {
        case .fixed(let dayNum):
            components.day = dayNum
            return calendar.date(from: components)

        case .firstOfMonth:
            components.day = 1
            return calendar.date(from: components)

        case .lastOfMonth:
            guard let range = calendar.range(of: .day, in: .month, for: month) else { return nil }
            components.day = range.count
            return calendar.date(from: components)

        case .firstWeekday(let weekday), .lastWeekday(let weekday):
            // Simplified - would need full implementation for production
            return nil
        }
    }

    /// Calculates the next occurrence for yearly schedule
    private func getNextYearlyOccurrence(month: Int, day: Int, time: TickerSchedule.TimeOfDay, from date: Date) -> Date {
        let currentYear = calendar.component(.year, from: date)

        for yearOffset in 0..<2 {
            var components = DateComponents()
            components.year = currentYear + yearOffset
            components.month = month
            components.day = day
            components.hour = time.hour
            components.minute = time.minute
            components.second = 0

            if let occurrence = calendar.date(from: components), occurrence > date {
                return occurrence
            }
        }

        return Date.distantFuture
    }

    /// Extracts display color from alarm with fallback hierarchy
    private func extractColor(from alarm: Ticker) -> Color {
        // Try ticker data first
        if let colorHex = alarm.tickerData?.colorHex,
           let color = Color(hex: colorHex) {
            return color
        }

        // Try presentation tint
        if let tintHex = alarm.presentation.tintColorHex,
           let color = Color(hex: tintHex) {
            return color
        }

        // Default to accent
        return .accentColor
    }
}
