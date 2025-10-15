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
        case .noRepeat:
            return .oneTime(date: configuration.date)
            
        case .daily:
            return .daily(time: time, startDate: configuration.date)
            
        case .weekdays(let weekdays):
            return .weekdays(time: time, days: weekdays, startDate: configuration.date)
            
        case .hourly(let interval):
            return .hourly(
                interval: interval,
                startTime: configuration.date,
                endTime: nil
            )
            
        case .biweekly(let weekdays):
            return .biweekly(
                time: time,
                weekdays: weekdays,
                anchorDate: configuration.date
            )
            
        case .monthly(let day):
            let monthlyDay = TickerSchedule.MonthlyDay.fixed(day)
            return .monthly(day: monthlyDay, time: time, startDate: configuration.date)
            
        case .yearly(let month, let day):
            return .yearly(
                month: month,
                day: day,
                time: time,
                startDate: configuration.date
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
        case .biweekly(let weekdays):
            if weekdays.isEmpty {
                errors.append("No weekdays selected for biweekly repeat")
            }
        case .monthly(let day):
            if day < 1 || day > 31 {
                errors.append("Invalid day for monthly repeat: \(day)")
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
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
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
