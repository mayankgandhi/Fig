//
//  TickerScheduleExpander.swift
//  fig
//
//  Service that expands TickerSchedule rules into concrete alarm dates
//  Handles all recurrence patterns and generates dates within a given window
//

import Foundation

// MARK: - TickerScheduleExpander Protocol

protocol TickerScheduleExpanderProtocol {
    func expandSchedule(_ schedule: TickerSchedule, within window: DateInterval) -> [Date]
    func expandSchedule(_ schedule: TickerSchedule, startingFrom: Date, days: Int) -> [Date]
    func expandSchedule(_ schedule: TickerSchedule, startingFrom: Date, days: Int, maxAlarms: Int) -> [Date]
}

// MARK: - TickerScheduleExpander Implementation

struct TickerScheduleExpander: TickerScheduleExpanderProtocol {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Public Methods

    func expandSchedule(_ schedule: TickerSchedule, within window: DateInterval) -> [Date] {
        switch schedule {
        case .oneTime(let date):
            return expandOneTime(date: date, within: window)

        case .daily(let time):
            return expandDaily(time: time, within: window)

        case .hourly(let interval, let startTime, let endTime):
            return expandHourly(interval: interval, startTime: startTime, endTime: endTime, within: window)

        case .every(let interval, let unit, let startTime, let endTime):
            return expandEvery(interval: interval, unit: unit, startTime: startTime, endTime: endTime, within: window)

        case .weekdays(let time, let days):
            return expandWeekdays(time: time, days: days, within: window)

        case .biweekly(let time, let weekdays):
            return expandBiweekly(time: time, weekdays: weekdays, within: window)

        case .monthly(let day, let time):
            return expandMonthly(day: day, time: time, within: window)

        case .yearly(let month, let day, let time):
            return expandYearly(month: month, day: day, time: time, within: window)
        }
    }

    func expandSchedule(_ schedule: TickerSchedule, startingFrom: Date, days: Int) -> [Date] {
        // Default to maximum 2 alarms for efficiency
        return expandSchedule(schedule, startingFrom: startingFrom, days: days, maxAlarms: 2)
    }
    
    func expandSchedule(_ schedule: TickerSchedule, startingFrom: Date, days: Int, maxAlarms: Int) -> [Date] {
        guard let endDate = calendar.date(byAdding: .day, value: days, to: startingFrom) else {
            return []
        }
        let window = DateInterval(start: startingFrom, end: endDate)
        let allDates = expandSchedule(schedule, within: window)
        
        // Limit to specified maximum number of alarms
        return Array(allDates.prefix(maxAlarms))
    }

    // MARK: - Private Expansion Methods

    private func expandOneTime(date: Date, within window: DateInterval) -> [Date] {
        return window.contains(date) ? [date] : []
    }

    private func expandDaily(time: TickerSchedule.TimeOfDay, within window: DateInterval) -> [Date] {
        var dates: [Date] = []

        // Smart start: begin from window.start
        var currentDate = window.start

        while currentDate <= window.end {
            if let alarmDate = createDate(from: currentDate, with: time) {
                // Only include if the alarm time is within the window
                if alarmDate >= window.start && alarmDate <= window.end {
                    dates.append(alarmDate)
                }
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates.sorted()
    }

    private func expandHourly(interval: Int, startTime: Date, endTime: Date?, within window: DateInterval) -> [Date] {
        var dates: [Date] = []
        let effectiveEndTime = endTime ?? window.end
        
        // Ensure we start from a future date
        let now = Date()
        var currentDate: Date
        
        if startTime > now {
            // Start time is in the future, use it
            currentDate = max(startTime, window.start)
        } else {
            // Start time is in the past, find the next occurrence from now
            currentDate = findNextOccurrence(from: now, interval: interval, unit: .hours, originalStartTime: startTime)
            currentDate = max(currentDate, window.start)
        }

        while currentDate <= min(effectiveEndTime, window.end) {
            dates.append(currentDate)

            guard let nextDate = calendar.date(byAdding: .hour, value: interval, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates.sorted()
    }

    private func expandEvery(interval: Int, unit: TickerSchedule.TimeUnit, startTime: Date, endTime: Date?, within window: DateInterval) -> [Date] {
        var dates: [Date] = []
        let effectiveEndTime = endTime ?? window.end
        
        // Ensure we start from a future date - use the later of startTime or window.start
        // but if startTime is in the past, find the next occurrence from now
        let now = Date()
        var currentDate: Date
        
        if startTime > now {
            // Start time is in the future, use it
            currentDate = max(startTime, window.start)
        } else {
            // Start time is in the past, find the next occurrence from now
            currentDate = findNextOccurrence(from: now, interval: interval, unit: unit, originalStartTime: startTime)
            currentDate = max(currentDate, window.start)
        }

        // Map TimeUnit to Calendar.Component
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

        while currentDate <= min(effectiveEndTime, window.end) {
            dates.append(currentDate)

            guard let nextDate = calendar.date(byAdding: component, value: interval, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates.sorted()
    }

    private func expandWeekdays(time: TickerSchedule.TimeOfDay, days: Array<TickerSchedule.Weekday>, within window: DateInterval) -> [Date] {
        var dates: [Date] = []

        // Smart start: begin from window.start
        var currentDate = window.start

        while currentDate <= window.end {
            let weekday = calendar.component(.weekday, from: currentDate)
            // Convert Calendar weekday (1=Sunday) to our Weekday enum (0=Sunday)
            let adjustedWeekday = (weekday == 1) ? 0 : weekday - 1

            if let tickerWeekday = TickerSchedule.Weekday(rawValue: adjustedWeekday),
               days.contains(tickerWeekday) {
                if let alarmDate = createDate(from: currentDate, with: time) {
                    // Only include if the alarm time is within the window
                    if alarmDate >= window.start && alarmDate <= window.end {
                        dates.append(alarmDate)
                    }
                }
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates.sorted()
    }

    private func expandBiweekly(time: TickerSchedule.TimeOfDay, weekdays: Array<TickerSchedule.Weekday>, within window: DateInterval) -> [Date] {
        var dates: [Date] = []

        // Use window.start as the implicit anchor (week 0)
        // This means the week containing window.start is always an "on" week
        let anchorWeekStart = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: window.start)
        guard let anchorWeekDate = calendar.date(from: anchorWeekStart) else {
            return []
        }

        var currentDate = window.start
        while currentDate <= window.end {
            let currentWeekStart = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
            guard let currentWeekDate = calendar.date(from: currentWeekStart) else {
                break
            }

            // Calculate week difference from anchor
            let weeksDifference = calendar.dateComponents([.weekOfYear], from: anchorWeekDate, to: currentWeekDate).weekOfYear ?? 0

            // Check if this is an "on" week (even number of weeks from anchor, including week 0)
            if weeksDifference % 2 == 0 {
                let weekday = calendar.component(.weekday, from: currentDate)
                let adjustedWeekday = (weekday == 1) ? 0 : weekday - 1

                if let tickerWeekday = TickerSchedule.Weekday(rawValue: adjustedWeekday),
                   weekdays.contains(tickerWeekday) {
                    if let alarmDate = createDate(from: currentDate, with: time) {
                        // Only include if the alarm time is within the window
                        if alarmDate >= window.start && alarmDate <= window.end {
                            dates.append(alarmDate)
                        }
                    }
                }
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates.sorted()
    }

    private func expandMonthly(day: TickerSchedule.MonthlyDay, time: TickerSchedule.TimeOfDay, within window: DateInterval) -> [Date] {
        var dates: [Date] = []

        // Smart start: begin from window.start
        let startComponents = calendar.dateComponents([.year, .month], from: window.start)
        let endComponents = calendar.dateComponents([.year, .month], from: window.end)

        guard let startYear = startComponents.year,
              let startMonth = startComponents.month,
              let endYear = endComponents.year,
              let endMonth = endComponents.month else {
            return []
        }

        // Iterate through each month in the window
        var currentYear = startYear
        var currentMonth = startMonth

        while (currentYear < endYear) || (currentYear == endYear && currentMonth <= endMonth) {
            if let alarmDate = createMonthlyDate(year: currentYear, month: currentMonth, day: day, time: time) {
                if alarmDate >= window.start && alarmDate <= window.end {
                    dates.append(alarmDate)
                }
            }

            // Move to next month
            currentMonth += 1
            if currentMonth > 12 {
                currentMonth = 1
                currentYear += 1
            }
        }

        return dates.sorted()
    }

    private func expandYearly(month: Int, day: Int, time: TickerSchedule.TimeOfDay, within window: DateInterval) -> [Date] {
        var dates: [Date] = []

        // Smart start: begin from window.start
        let startYear = calendar.component(.year, from: window.start)
        let endYear = calendar.component(.year, from: window.end)

        for year in startYear...endYear {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            components.hour = time.hour
            components.minute = time.minute

            if let alarmDate = calendar.date(from: components) {
                if alarmDate >= window.start && alarmDate <= window.end {
                    dates.append(alarmDate)
                }
            }
        }

        return dates.sorted()
    }

    // MARK: - Helper Methods

    private func findNextOccurrence(from now: Date, interval: Int, unit: TickerSchedule.TimeUnit, originalStartTime: Date) -> Date {
        // Calculate how many intervals have passed since the original start time
        let timeSinceStart = now.timeIntervalSince(originalStartTime)
        let intervalSeconds: TimeInterval
        
        switch unit {
        case .minutes:
            intervalSeconds = TimeInterval(interval * 60)
        case .hours:
            intervalSeconds = TimeInterval(interval * 3600)
        case .days:
            intervalSeconds = TimeInterval(interval * 86400)
        case .weeks:
            intervalSeconds = TimeInterval(interval * 604800)
        }
        
        // Find how many complete intervals have passed
        let intervalsPassed = Int(timeSinceStart / intervalSeconds)
        
        // Calculate the next occurrence
        let nextIntervalCount = intervalsPassed + 1
        
        // Map TimeUnit to Calendar.Component
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
        
        // Calculate the next occurrence by adding the appropriate number of intervals
        guard let nextDate = calendar.date(byAdding: component, value: interval * nextIntervalCount, to: originalStartTime) else {
            // Fallback: just add one interval from now
            return calendar.date(byAdding: component, value: interval, to: now) ?? now
        }
        
        return nextDate
    }

    private func createDate(from baseDate: Date, with time: TickerSchedule.TimeOfDay) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0
        return calendar.date(from: components)
    }

    private func createMonthlyDate(year: Int, month: Int, day: TickerSchedule.MonthlyDay, time: TickerSchedule.TimeOfDay) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0

        switch day {
        case .fixed(let dayNumber):
            components.day = dayNumber
            // Handle invalid dates (e.g., Feb 30)
            return calendar.date(from: components)

        case .firstOfMonth:
            components.day = 1
            return calendar.date(from: components)

        case .lastOfMonth:
            // Get the range of days in this month
            components.day = 1
            guard let firstOfMonth = calendar.date(from: components),
                  let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
                return nil
            }
            components.day = range.count
            return calendar.date(from: components)

        case .firstWeekday(let weekday):
            return findFirstWeekday(weekday, in: year, month: month, time: time)

        case .lastWeekday(let weekday):
            return findLastWeekday(weekday, in: year, month: month, time: time)
        }
    }

    private func findFirstWeekday(_ weekday: TickerSchedule.Weekday, in year: Int, month: Int, time: TickerSchedule.TimeOfDay) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstOfMonth = calendar.date(from: components) else {
            return nil
        }

        // Find the first occurrence of the specified weekday
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let adjustedFirstWeekday = (firstWeekday == 1) ? 0 : firstWeekday - 1

        let targetWeekday = weekday.rawValue
        var daysToAdd = (targetWeekday - adjustedFirstWeekday + 7) % 7

        guard let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: firstOfMonth) else {
            return nil
        }

        return createDate(from: targetDate, with: time)
    }

    private func findLastWeekday(_ weekday: TickerSchedule.Weekday, in year: Int, month: Int, time: TickerSchedule.TimeOfDay) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth),
              let lastOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: firstOfMonth) else {
            return nil
        }

        // Find the last occurrence of the specified weekday
        let lastWeekday = calendar.component(.weekday, from: lastOfMonth)
        let adjustedLastWeekday = (lastWeekday == 1) ? 0 : lastWeekday - 1

        let targetWeekday = weekday.rawValue
        var daysToSubtract = (adjustedLastWeekday - targetWeekday + 7) % 7

        guard let targetDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: lastOfMonth) else {
            return nil
        }

        return createDate(from: targetDate, with: time)
    }
}
