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

    // MARK: - Cached State (computed off main thread, stored for fast access)
    
    private(set) var upcomingAlarms: [UpcomingAlarmPresentation] = []
    private(set) var upcomingAlarmsForClock: [UpcomingAlarmPresentation] = []
    
    /// Number of upcoming alarms
    var upcomingAlarmsCount: Int {
        upcomingAlarms.count
    }

    /// Whether there are any upcoming alarms
    var hasUpcomingAlarms: Bool {
        !upcomingAlarms.isEmpty
    }

    // MARK: - Initialization

    init(tickerService: TickerService, modelContext: ModelContext, calendar: Calendar = .current) {
        self.tickerService = tickerService
        self.modelContext = modelContext
        self.calendar = calendar
    }

    // MARK: - Public Methods
    
    /// Refreshes upcoming alarms (call this when alarms change)
    /// Computation happens off main thread for better performance
    func refreshAlarms() async {
        let now = Date()
        
        // Get all enabled alarms (fast dictionary access)
        let allEnabledAlarms = tickerService.getAlarmsWithMetadata(context: modelContext).filter { $0.isEnabled }
        
        // Compute upcoming alarms off main thread
        let cutoffTime = allEnabledAlarms
            .compactMap { alarm -> Date? in
                guard alarm.schedule != nil else { return nil }
                return getNextAlarmTime(for: alarm, from: now)
            }
            .max() ?? now
        
        let allOccurrences = allEnabledAlarms.flatMap { alarm -> [UpcomingAlarmPresentation] in
            generateOccurrences(for: alarm, from: now, until: cutoffTime)
        }
        
        let sortedOccurrences = allOccurrences.sorted { $0.nextAlarmTime < $1.nextAlarmTime }

        // Compute clock alarms: just filter sortedOccurrences to next 12 hours
        let twelveHoursFromNow = calendar.date(byAdding: .hour, value: 12, to: now) ?? now
        let clockAlarms = sortedOccurrences.filter { occurrence in
            occurrence.nextAlarmTime > now && occurrence.nextAlarmTime <= twelveHoursFromNow
        }

        // Update state on main thread
        await MainActor.run {
            self.upcomingAlarms = sortedOccurrences
            self.upcomingAlarmsForClock = clockAlarms
        }
    }

    // MARK: - Helper Methods

    /// Generates all occurrences for an alarm within a time window
    private func generateOccurrences(for alarm: Ticker, from startDate: Date, until endDate: Date) -> [UpcomingAlarmPresentation] {
        guard let schedule = alarm.schedule else { return [] }

        var occurrences: [Date] = []
        var currentDate = startDate

        // For one-time alarms, just add the single occurrence if it's in range
        if case .oneTime(let alarmDate) = schedule {
            if alarmDate >= startDate && alarmDate <= endDate {
                occurrences.append(alarmDate)
            }
            return occurrences.map { createPresentation(from: alarm, at: $0) }
        }

        // For recurring alarms, generate occurrences until we reach the end date
        while currentDate <= endDate {
            let nextOccurrence = getNextAlarmTime(for: alarm, from: currentDate)

            // Break if next occurrence is beyond our window or in the far future
            if nextOccurrence > endDate || nextOccurrence == Date.distantFuture {
                break
            }

            occurrences.append(nextOccurrence)

            // Move to just after this occurrence to find the next one
            currentDate = nextOccurrence.addingTimeInterval(60) // Add 1 minute to avoid same occurrence
        }

        return occurrences.map { createPresentation(from: alarm, at: $0) }
    }

    /// Creates presentation model for a specific alarm occurrence time
    private func createPresentation(from alarm: Ticker, at time: Date) -> UpcomingAlarmPresentation {
        let scheduleType: UpcomingAlarmPresentation.ScheduleType = {
            guard let schedule = alarm.schedule else { return .oneTime }
            switch schedule {
            case .oneTime: return .oneTime
            case .daily: return .daily
            case .weekdays(_, let days, _):
                return .weekdays(days.map { $0.rawValue })
            case .hourly(let interval, _, _):
                return .hourly(interval: interval)
            case .every(let interval, let unit, _, _):
                return .every(interval: interval, unit: unit.displayName)
            case .biweekly: return .biweekly
            case .monthly: return .monthly
            case .yearly: return .yearly
            }
        }()

        // Extract hour and minute for angle calculation
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        return UpcomingAlarmPresentation(
            baseAlarmId: alarm.id,
            displayName: alarm.displayName,
            icon: alarm.tickerData?.icon ?? "alarm",
            color: extractColor(from: alarm),
            nextAlarmTime: time,
            scheduleType: scheduleType,
            hour: hour,
            minute: minute,
            hasCountdown: alarm.countdown?.preAlert != nil,
            tickerDataTitle: alarm.tickerData?.name
        )
    }

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

        case .daily(let time, _):
            return getNextOccurrence(for: time, from: date)

        case .weekdays(let time, let days, _):
            return getNextWeekdayOccurrence(for: time, days: days, from: date)

        case .hourly(let interval, let startTime, let endTime):
            return getNextHourlyOccurrence(interval: interval, startTime: startTime, endTime: endTime, from: date)

        case .every(let interval, let unit, let startTime, let endTime):
            return getNextEveryOccurrence(interval: interval, unit: unit, startTime: startTime, endTime: endTime, from: date)

        case .biweekly(let time, let weekdays, let anchorDate):
            return getNextBiweeklyOccurrence(for: time, weekdays: weekdays, anchorDate: anchorDate, from: date)

        case .monthly(let day, let time, _):
            return getNextMonthlyOccurrence(day: day, time: time, from: date)

        case .yearly(let month, let day, let time, _):
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

    /// Calculates the next occurrence for every schedule
    private func getNextEveryOccurrence(interval: Int, unit: TickerSchedule.TimeUnit, startTime: Date, endTime: Date?, from date: Date) -> Date {
        var current = max(startTime, date)

        // Map unit to Calendar.Component
        let component: Calendar.Component
        switch unit {
        case .minutes:
            component = .minute
        case .hours:
            component = .hour
        case .days:
            component = .day
        case .weeks:
            component = .weekOfYear
        }

        while current < (endTime ?? Date.distantFuture) {
            if current > date {
                return current
            }
            current = calendar.date(byAdding: component, value: interval, to: current) ?? Date.distantFuture
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
