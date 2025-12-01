//
//  TickerSchedule.swift
//  TickerCore
//
//  Created by Mayank Gandhi on 01/12/25.
//

import Foundation


// MARK: - TickerSchedule

public enum TickerSchedule: Codable, Hashable {
    case oneTime(date: Date)
    case daily(time: TimeOfDay)
    case hourly(interval: Int, time: TimeOfDay)
    case every(interval: Int, unit: TimeUnit, time: TimeOfDay)
    case weekdays(time: TimeOfDay, days: Array<Weekday>)
    case biweekly(time: TimeOfDay, weekdays: Array<Weekday>)
    case monthly(day: MonthlyDay, time: TimeOfDay)
    case yearly(month: Int, day: Int, time: TimeOfDay)

    public enum Weekday: Int, Codable, Hashable, CaseIterable {
        case sunday = 0
        case monday = 1
        case tuesday = 2
        case wednesday = 3
        case thursday = 4
        case friday = 5
        case saturday = 6
        
        var shortName: String {
            switch self {
                case .sunday: return "Sun"
                case .monday: return "Mon"
                case .tuesday: return "Tue"
                case .wednesday: return "Wed"
                case .thursday: return "Thu"
                case .friday: return "Fri"
                case .saturday: return "Sat"
            }
        }
    }

    public enum MonthlyDay: Codable, Hashable {
        case fixed(Int) // 1-31
        case firstWeekday(Weekday)
        case lastWeekday(Weekday)
        case firstOfMonth
        case lastOfMonth
    }

    public enum TimeUnit: String, Codable, Hashable, CaseIterable {
        case minutes = "Minutes"
        case hours = "Hours"
        case days = "Days"
        case weeks = "Weeks"

        public var displayName: String {
            rawValue
        }

        public var singularName: String {
            switch self {
            case .minutes: return "minute"
            case .hours: return "hour"
            case .days: return "day"
            case .weeks: return "week"
            }
        }
    }
}

// MARK: - Weekday Display Extensions

extension TickerSchedule {
    public var icon: String {
        switch self {
            case .oneTime: return "calendar"
            case .daily: return "repeat"
            case .hourly: return "clock"
            case .weekdays: return "calendar.badge.clock"
            case .biweekly: return "calendar.badge.clock"
            case .every: return "calendar.badge.clock"
            case .monthly: return "calendar.circle"
            case .yearly: return "calendar.badge.exclamationmark"
        }
    }
}

extension TickerSchedule.Weekday {
    public var localeWeekday: Locale.Weekday {
        switch self {
        case .sunday: return .sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        }
    }

    public var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    public var shortDisplayName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

// MARK: - TickerSchedule Display Extensions

public extension TickerSchedule {
    var displaySummary: String {
        switch self {
        case .oneTime(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)

        case .daily(let time):
            return "Daily at \(formatTime(time))"

        case .hourly(let interval, _):
            return "Every \(interval) hour\(interval == 1 ? "" : "s")"

        case .every(let interval, let unit, _):
            let unitName = interval == 1 ? unit.singularName : unit.displayName.lowercased()
            return "Every \(interval) \(unitName)"

        case .weekdays(let time, let days):
            let sortedDays = days.sorted { $0.rawValue < $1.rawValue }
            let dayNames = sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
            return "\(dayNames) at \(formatTime(time))"

        case .biweekly(let time, let weekdays):
            let sortedDays = weekdays.sorted { $0.rawValue < $1.rawValue }
            let dayNames = sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
            return "Biweekly \(dayNames) at \(formatTime(time))"

        case .monthly(let day, let time):
            let dayDesc: String
            switch day {
            case .fixed(let d):
                dayDesc = "Day \(d)"
            case .firstWeekday(let weekday):
                dayDesc = "First \(weekday.displayName)"
            case .lastWeekday(let weekday):
                dayDesc = "Last \(weekday.displayName)"
            case .firstOfMonth:
                dayDesc = "1st"
            case .lastOfMonth:
                dayDesc = "Last day"
            }
            return "Monthly \(dayDesc) at \(formatTime(time))"

        case .yearly(let month, let day, let time):
            let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return "Yearly \(monthNames[month - 1]) \(day) at \(formatTime(time))"
        }
    }

    private func formatTime(_ time: TimeOfDay) -> String {
        let hour = time.hour % 12 == 0 ? 12 : time.hour % 12
        let period = time.hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour, time.minute, period)
    }
}

