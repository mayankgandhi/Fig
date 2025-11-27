//
//  TickerConfiguration+LLMKit.swift
//  fig
//
//  Bridges TickerConfiguration with LLMKit's ParseableModel protocol
//

import OpenAI
import TickerCore
import Foundation

/// A variant of TickerConfiguration that uses codable structs for everything, including the repeat option
public struct LLKTickerConfig: Codable, Equatable, JSONSchemaConvertible {

    public static var example: LLKTickerConfig {
        LLKTickerConfig(
            label: "Pick up mom for dinner",
            time: LLKTimeOfDay(hour: 8, minute: 0),
            date: "2025-11-28T14:30:00Z",
            repeatOption: LLKRepeatOption(
                type: .weekdays,
                weekdays: [0,1,2,3,4],
                interval: 10,
                unit: "Days",
                monthlyDay: LLKMonthlyDay(
                    type: .firstOfMonth,
                    fixedDay: 1,
                    weekday: 2
                ),
                month: 1,
                day: 1
            ),
            countdown: LLKCountdownConfiguration(hours: 0, minutes: 10, seconds: 0),
            icon: "sunset.fill",
            colorHex: "FA25EE"
        )
    }

    public let label: String
    public let time: LLKTimeOfDay
    public let date: String // "yyyy-MM-dd'T'HH:mm:ss"
    public let repeatOption: LLKRepeatOption
    public let countdown: LLKCountdownConfiguration?
    public let icon: String
    public let colorHex: String
    
    public init(
        label: String,
        time: LLKTimeOfDay,
        date: String,
        repeatOption: LLKRepeatOption,
        countdown: LLKCountdownConfiguration?,
        icon: String,
        colorHex: String
    ) {
        self.label = label
        self.time = time
        self.date = date
        self.repeatOption = repeatOption
        self.countdown = countdown
        self.icon = icon
        self.colorHex = colorHex
    }
}

// MARK: - LLKTimeOfDay

public struct LLKTimeOfDay: Codable, Equatable {
    public let hour: Int // 0-23
    public let minute: Int // 0-59
    
    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}

// MARK: - LLKRepeatOption

/// Codable struct representation of repeat options
public struct LLKRepeatOption: Codable, Equatable {
    public let type: RepeatType
    
    // For weekdays and biweekly
    public let weekdays: [Int]? // Array of weekday integers (0=Sunday, 1=Monday, etc.)
    
    // For hourly and every
    public let interval: Int?
    
    // For every
    public let unit: String? // "Minutes", "Hours", "Days", "Weeks"
    
    // For monthly
    public let monthlyDay: LLKMonthlyDay?
    
    // For yearly
    public let month: Int? // 1-12
    public let day: Int? // 1-31
    
    public enum RepeatType: String, Codable, CaseIterable, JSONSchemaEnumConvertible {
    
        public var caseNames: [String] {
            [
                "oneTime",
                "daily",
                "weekdays",
                "hourly",
                "every",
                "biweekly",
                "monthly",
                "yearly",
            ]
        }

        case oneTime
        case daily
        case weekdays
        case hourly
        case every
        case biweekly
        case monthly
        case yearly
    }
    
    public init(
        type: RepeatType,
        weekdays: [Int]? = nil,
        interval: Int? = nil,
        unit: String? = nil,
        monthlyDay: LLKMonthlyDay? = nil,
        month: Int? = nil,
        day: Int? = nil
    ) {
        self.type = type
        self.weekdays = weekdays
        self.interval = interval
        self.unit = unit
        self.monthlyDay = monthlyDay
        self.month = month
        self.day = day
    }
}

// MARK: - LLKMonthlyDay

public struct LLKMonthlyDay: Codable, Equatable {
    public let type: MonthlyDayType
    
    // For fixed day
    public let fixedDay: Int? // 1-31
    
    // For firstWeekday and lastWeekday
    public let weekday: Int? // 0=Sunday, 1=Monday, etc.
    
    public enum MonthlyDayType: String, Codable, JSONSchemaEnumConvertible {
        
        public var caseNames: [String] {
            ["fixed",
            "firstWeekday",
            "lastWeekday",
            "firstOfMonth",
            "lastOfMonth"]
        }

        case fixed
        case firstWeekday
        case lastWeekday
        case firstOfMonth
        case lastOfMonth
    }
    
    public init(
        type: MonthlyDayType,
        fixedDay: Int? = nil,
        weekday: Int? = nil
    ) {
        self.type = type
        self.fixedDay = fixedDay
        self.weekday = weekday
    }
}

// MARK: - LLKCountdownConfiguration

public struct LLKCountdownConfiguration: Codable, Equatable {
    public let hours: Int
    public let minutes: Int
    public let seconds: Int
    
    public init(hours: Int, minutes: Int, seconds: Int) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }
}

// MARK: - Conversion to TickerConfiguration

extension LLKTickerConfig {

    /// Converts LLKTickerConfig to TickerConfiguration
    public func toTickerConfiguration() throws -> TickerConfiguration {
        // Convert time
        let time = TimeOfDay(hour: self.time.hour, minute: self.time.minute)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current // This uses the device's local time zone
        
        if let date = formatter.date(from: self.date) {
            return try createConfiguration(with: time, date: date)
        } else {
            throw ConversionError.invalidDate(self.date)
        }
    }
    
    private func createConfiguration(with time: TimeOfDay, date: Date) throws -> TickerConfiguration {
        // Convert repeat option
        let repeatOption = try self.repeatOption.toAITickerGeneratorRepeatOption()
        
        // Convert countdown
        let countdown: TickerConfiguration.CountdownConfiguration? = self.countdown.map {
            TickerConfiguration.CountdownConfiguration(
                hours: $0.hours,
                minutes: $0.minutes,
                seconds: $0.seconds
            )
        }
        
        return TickerConfiguration(
            label: self.label,
            time: time,
            date: date,
            repeatOption: repeatOption,
            countdown: countdown,
            icon: self.icon,
            colorHex: self.colorHex
        )
    }
}

extension LLKRepeatOption {
    /// Converts LLKRepeatOption to AITickerGenerator.RepeatOption
    func toAITickerGeneratorRepeatOption() throws -> AITickerGenerator.RepeatOption {
        switch type {
        case .oneTime:
            return .oneTime
            
        case .daily:
            return .daily
            
        case .weekdays:
            guard let weekdayInts = weekdays, !weekdayInts.isEmpty else {
                throw ConversionError.invalidWeekdays
            }
            let weekdays = weekdayInts.compactMap { TickerSchedule.Weekday(rawValue: $0) }
            guard weekdays.count == weekdayInts.count else {
                throw ConversionError.invalidWeekdays
            }
            return .weekdays(weekdays)
            
        case .hourly:
            guard let interval = interval, interval > 0 else {
                throw ConversionError.invalidInterval
            }
            return .hourly(interval: interval)
            
        case .every:
            guard let interval = interval, interval > 0 else {
                throw ConversionError.invalidInterval
            }
            guard let unitString = unit else {
                throw ConversionError.missingUnit
            }
            let unit: TickerSchedule.TimeUnit
            switch unitString {
            case "Minutes":
                unit = .minutes
            case "Hours":
                unit = .hours
            case "Days":
                unit = .days
            case "Weeks":
                unit = .weeks
            default:
                throw ConversionError.invalidUnit(unitString)
            }
            return .every(interval: interval, unit: unit)
            
        case .biweekly:
            guard let weekdayInts = weekdays, !weekdayInts.isEmpty else {
                throw ConversionError.invalidWeekdays
            }
            let weekdays = weekdayInts.compactMap { TickerSchedule.Weekday(rawValue: $0) }
            guard weekdays.count == weekdayInts.count else {
                throw ConversionError.invalidWeekdays
            }
            return .biweekly(weekdays)
            
        case .monthly:
            guard let monthlyDay = monthlyDay else {
                throw ConversionError.missingMonthlyDay
            }
            let tickerMonthlyDay: TickerSchedule.MonthlyDay
            switch monthlyDay.type {
            case .fixed:
                guard let day = monthlyDay.fixedDay, day >= 1 && day <= 31 else {
                    throw ConversionError.invalidMonthlyDay
                }
                tickerMonthlyDay = .fixed(day)
            case .firstWeekday:
                guard let weekdayInt = monthlyDay.weekday,
                      let weekday = TickerSchedule.Weekday(rawValue: weekdayInt) else {
                    throw ConversionError.invalidWeekday
                }
                tickerMonthlyDay = .firstWeekday(weekday)
            case .lastWeekday:
                guard let weekdayInt = monthlyDay.weekday,
                      let weekday = TickerSchedule.Weekday(rawValue: weekdayInt) else {
                    throw ConversionError.invalidWeekday
                }
                tickerMonthlyDay = .lastWeekday(weekday)
            case .firstOfMonth:
                tickerMonthlyDay = .firstOfMonth
            case .lastOfMonth:
                tickerMonthlyDay = .lastOfMonth
            }
            return .monthly(day: tickerMonthlyDay)
            
        case .yearly:
            guard let month = month, month >= 1 && month <= 12 else {
                throw ConversionError.invalidMonth
            }
            guard let day = day, day >= 1 && day <= 31 else {
                throw ConversionError.invalidDay
            }
            return .yearly(month: month, day: day)
        }
    }
}

enum ConversionError: Error {
    case invalidDate(String)
    case invalidWeekdays
    case invalidInterval
    case missingUnit
    case invalidUnit(String)
    case missingMonthlyDay
    case invalidMonthlyDay
    case invalidWeekday
    case invalidMonth
    case invalidDay
    
    var errorDescription: String? {
        switch self {
        case .invalidDate(let date):
            return "Invalid date format: \(date)"
        case .invalidWeekdays:
            return "Invalid weekdays array"
        case .invalidInterval:
            return "Invalid interval value"
        case .missingUnit:
            return "Missing unit for 'every' repeat option"
        case .invalidUnit(let unit):
            return "Invalid unit: \(unit). Expected 'Minutes', 'Hours', 'Days', or 'Weeks'"
        case .missingMonthlyDay:
            return "Missing monthlyDay for monthly repeat option"
        case .invalidMonthlyDay:
            return "Invalid monthly day value (must be 1-31)"
        case .invalidWeekday:
            return "Invalid weekday value (must be 0-6)"
        case .invalidMonth:
            return "Invalid month value (must be 1-12)"
        case .invalidDay:
            return "Invalid day value (must be 1-31)"
        }
    }
}
