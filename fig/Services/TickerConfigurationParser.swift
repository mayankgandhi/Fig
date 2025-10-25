//
//  TickerConfigurationParser.swift
//  fig
//
//  Converts AI-generated configuration to Ticker model
//

import Foundation
import SwiftData

// MARK: - Ticker Configuration Parser

class TickerConfigurationParser {
    
    func parseToTicker(from configuration: TickerConfiguration) -> Ticker {
        let calendar = Calendar.current
        
        // Build the schedule
        let schedule = buildSchedule(from: configuration, calendar: calendar)
        
        // Build countdown
        let countdown = buildCountdown(from: configuration)
        
        // Build presentation
        let presentation = TickerPresentation(
            tintColorHex: configuration.colorHex,
            secondaryButtonType: .none
        )
        
        // Build ticker data
        let tickerData = TickerData(
            name: configuration.label,
            icon: configuration.icon,
            colorHex: configuration.colorHex
        )
        
        // Create the ticker
        let ticker = Ticker(
            label: configuration.label,
            isEnabled: true,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation,
            tickerData: tickerData
        )
        
        return ticker
    }
    
    // MARK: - Private Methods
    
    private func buildSchedule(from configuration: TickerConfiguration, calendar: Calendar) -> TickerSchedule {
        let time = TickerSchedule.TimeOfDay(
            hour: configuration.time.hour,
            minute: configuration.time.minute
        )

        switch configuration.repeatOption {
        case .oneTime:
            return .oneTime(date: configuration.date)

        case .daily:
            return .daily(time: time)

        case .weekdays(let weekdays):
            return .weekdays(time: time, days: weekdays)

        case .hourly(let interval, let startTime, let endTime):
            return .hourly(
                interval: interval,
                startTime: startTime,
                endTime: endTime
            )

        case .every(let interval, let unit, let startTime, let endTime):
            return .every(
                interval: interval,
                unit: unit,
                startTime: startTime,
                endTime: endTime
            )

        case .biweekly(let weekdays):
            return .biweekly(
                time: time,
                weekdays: weekdays
            )

        case .monthly(let monthlyDay):
            return .monthly(day: monthlyDay, time: time)

        case .yearly(let month, let day):
            return .yearly(
                month: month,
                day: day,
                time: time
            )
        }
    }
    
    private func buildCountdown(from configuration: TickerConfiguration) -> TickerCountdown? {
        guard let countdownConfig = configuration.countdown else {
            return nil
        }
        
        let duration = TickerCountdown.CountdownDuration(
            hours: countdownConfig.hours,
            minutes: countdownConfig.minutes,
            seconds: countdownConfig.seconds
        )
        
        return TickerCountdown(preAlert: duration, postAlert: nil)
    }
}

// MARK: - Validation

extension TickerConfigurationParser {
    
    func validateConfiguration(_ configuration: TickerConfiguration) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Validate time
        if configuration.time.hour < 0 || configuration.time.hour > 23 {
            errors.append("Invalid hour: \(configuration.time.hour)")
        }
        
        if configuration.time.minute < 0 || configuration.time.minute > 59 {
            errors.append("Invalid minute: \(configuration.time.minute)")
        }
        
        // Validate date
        if configuration.date < Date() {
            warnings.append("Selected date is in the past")
        }
        
        // Validate label
        if configuration.label.isEmpty {
            errors.append("Label cannot be empty")
        } else if configuration.label.count > 50 {
            errors.append("Label is too long (max 50 characters)")
        }
        
        // Validate repeat configuration
        switch configuration.repeatOption {
        case .weekdays(let weekdays):
            if weekdays.isEmpty {
                errors.append("No weekdays selected for weekday repeat")
            }
        case .hourly(let interval, let startTime, let endTime):
            if interval < 1 || interval > 12 {
                errors.append("Invalid hourly interval: \(interval)")
            }
            if let end = endTime, end <= startTime {
                errors.append("Hourly end time must be after start time")
            }
        case .every(let interval, let unit, let startTime, let endTime):
            let maxInterval = switch unit {
            case .minutes: 60
            case .hours: 24
            case .days: 30
            case .weeks: 52
            }
            if interval < 1 || interval > maxInterval {
                errors.append("Invalid interval for \(unit.displayName): \(interval)")
            }
            if let end = endTime, end <= startTime {
                errors.append("End time must be after start time")
            }
        case .biweekly(let weekdays):
            if weekdays.isEmpty {
                errors.append("No weekdays selected for biweekly repeat")
            }
        case .monthly(let monthlyDay):
            switch monthlyDay {
            case .fixed(let day):
                if day < 1 || day > 31 {
                    errors.append("Invalid day for monthly repeat: \(day)")
                }
            default:
                break // Other monthly day types are always valid
            }
        case .yearly(let month, let day):
            if month < 1 || month > 12 {
                errors.append("Invalid month for yearly repeat: \(month)")
            }
            if day < 1 || day > 31 {
                errors.append("Invalid day for yearly repeat: \(day)")
            }
        default:
            break
        }
        
        // Validate countdown
        if let countdown = configuration.countdown {
            let totalSeconds = countdown.hours * 3600 + countdown.minutes * 60 + countdown.seconds
            if totalSeconds <= 0 {
                errors.append("Countdown must be greater than 0 seconds")
            }
            if totalSeconds > 24 * 3600 {
                warnings.append("Countdown is very long (over 24 hours)")
            }
            
            // Validate countdown timing with alarm time
            validateCountdownTiming(configuration: configuration, countdown: countdown, errors: &errors, warnings: &warnings)
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    private func validateCountdownTiming(
        configuration: TickerConfiguration,
        countdown: TickerConfiguration.CountdownConfiguration,
        errors: inout [String],
        warnings: inout [String]
    ) {
        let countdownDuration = TimeInterval(countdown.hours * 3600 + countdown.minutes * 60 + countdown.seconds)
        
        // Check if countdown would start before midnight for early morning alarms
        let alarmTime = TickerSchedule.TimeOfDay(hour: configuration.time.hour, minute: configuration.time.minute)
        let countdownStartTime = alarmTime.addingTimeInterval(-countdownDuration)
        
        // Validate that countdown doesn't go beyond reasonable bounds
        if countdownDuration > 12 * 3600 { // More than 12 hours
            warnings.append("Countdown is very long - consider if this is intended")
        }
        
        // For one-time alarms, check if countdown would start in the past
        if case .oneTime = configuration.repeatOption {
            let alarmDate = configuration.date
            let countdownStartDate = alarmDate.addingTimeInterval(-countdownDuration)
            
            if countdownStartDate < Date() {
                errors.append("Countdown would start in the past. Please set an earlier alarm time or shorter countdown.")
            }
        }
        
        // For daily alarms, check if countdown crosses midnight
        if case .daily = configuration.repeatOption {
            if countdownStartTime.hour > alarmTime.hour || 
               (countdownStartTime.hour == alarmTime.hour && countdownStartTime.minute > alarmTime.minute) {
                warnings.append("Countdown crosses midnight - countdown will start the previous day")
            }
        }
        
        // Validate countdown duration is reasonable
        if countdownDuration < 60 { // Less than 1 minute
            warnings.append("Countdown is very short - consider if this provides enough notice")
        }
        
        if countdownDuration > 6 * 3600 { // More than 6 hours
            warnings.append("Countdown is very long - consider if this is necessary")
        }
    }
}

// MARK: - Validation Result

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
    
    var hasErrors: Bool {
        !errors.isEmpty
    }
    
    var hasWarnings: Bool {
        !warnings.isEmpty
    }
    
    var allMessages: [String] {
        errors + warnings
    }
}
