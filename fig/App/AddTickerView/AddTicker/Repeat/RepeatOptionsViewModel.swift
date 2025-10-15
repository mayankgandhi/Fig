//
//  RepeatOptionsViewModel.swift
//  fig
//
//  Manages repeat frequency selection
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}



@Observable
final class RepeatOptionsViewModel {
    var selectedOption: RepeatOption = .noRepeat
    
    // Configuration for weekdays option
    var selectedWeekdays: Array<TickerSchedule.Weekday> = []
    
    // Configuration for hourly option
    var hourlyInterval: Int = 1
    var hourlyStartTime: Date = Date()
    var hourlyEndTime: Date?
    
    // Configuration for biweekly option
    var biweeklyWeekdays: Array<TickerSchedule.Weekday> = []
    var biweeklyAnchorDate: Date = Date()
    
    // Configuration for monthly option
    var monthlyDayType: MonthlyDayType = .fixed
    var monthlyFixedDay: Int = 1
    var monthlyWeekday: TickerSchedule.Weekday = .monday
    
    // Configuration for yearly option
    var yearlyMonth: Int = 1
    var yearlyDay: Int = 1
    
    enum MonthlyDayType: String, CaseIterable {
        case fixed = "Fixed Day"
        case firstWeekday = "First Weekday"
        case lastWeekday = "Last Weekday"
        case firstOfMonth = "First of Month"
        case lastOfMonth = "Last of Month"
    }
    
    enum RepeatOption: String, CaseIterable {
        case noRepeat = "No repeat"
        case daily = "Daily"
        case weekdays = "Weekdays"
        case hourly = "Hourly"
        case biweekly = "Biweekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
        
        var icon: String {
            switch self {
                case .noRepeat: return "calendar"
                case .daily: return "repeat"
                case .weekdays: return "calendar.badge.clock"
                case .hourly: return "clock"
                case .biweekly: return "calendar.badge.clock"
                case .monthly: return "calendar.circle"
                case .yearly: return "calendar.badge.exclamationmark"
            }
        }
        
        var needsConfiguration: Bool {
            switch self {
                case .noRepeat, .daily:
                    return false
                case .weekdays, .hourly, .biweekly, .monthly, .yearly:
                    return true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var isDailyRepeat: Bool {
        selectedOption == .daily
    }
    
    var displayIcon: String {
        selectedOption.icon
    }
    
    var displayText: String {
        switch selectedOption {
            case .noRepeat:
                return "No repeat"
            case .daily:
                return "Repeats every day"
            case .weekdays:
                if selectedWeekdays.isEmpty {
                    return "Weekdays (not configured)"
                } else if selectedWeekdays.count == 5 && selectedWeekdays.allSatisfy({ [.monday, .tuesday, .wednesday, .thursday, .friday].contains($0) }) {
                    return "Repeats on weekdays (Mon-Fri)"
                } else {
                    let weekdayNames = selectedWeekdays.map { $0.displayName }.joined(separator: ", ")
                    return "Repeats on \(weekdayNames)"
                }
            case .hourly:
                if hourlyInterval == 1 {
                    return "Repeats every hour"
                } else {
                    return "Repeats every \(hourlyInterval) hours"
                }
            case .biweekly:
                if biweeklyWeekdays.isEmpty {
                    return "Biweekly (not configured)"
                } else {
                    let weekdayNames = biweeklyWeekdays.map { $0.displayName }.joined(separator: ", ")
                    return "Repeats every 2 weeks on \(weekdayNames)"
                }
            case .monthly:
                switch monthlyDayType {
                    case .fixed:
                        return "Repeats on day \(monthlyFixedDay) of every month"
                    case .firstWeekday:
                        return "Repeats on first \(monthlyWeekday.displayName) of every month"
                    case .lastWeekday:
                        return "Repeats on last \(monthlyWeekday.displayName) of every month"
                    case .firstOfMonth:
                        return "Repeats on 1st of every month"
                    case .lastOfMonth:
                        return "Repeats on last day of every month"
                }
            case .yearly:
                let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                let monthName = monthNames[safe: yearlyMonth - 1] ?? "Unknown"
                return "Repeats on \(monthName) \(yearlyDay) every year"
        }
    }
    
    var needsConfiguration: Bool {
        selectedOption.needsConfiguration
    }
    
    // MARK: - Methods
    
    func selectOption(_ option: RepeatOption) {
        selectedOption = option
        
        // Set sensible defaults when selecting certain options
        switch option {
            case .weekdays:
                if selectedWeekdays.isEmpty {
                    selectedWeekdays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                }
            case .biweekly:
                if biweeklyWeekdays.isEmpty {
                    biweeklyWeekdays = [.monday, .wednesday, .friday]
                }
                biweeklyAnchorDate = Date()
            default:
                break
        }
    }
    
    func reset() {
        selectedOption = .noRepeat
        selectedWeekdays = []
        hourlyInterval = 1
        hourlyStartTime = Date()
        hourlyEndTime = nil
        biweeklyWeekdays = []
        biweeklyAnchorDate = Date()
        monthlyDayType = .fixed
        monthlyFixedDay = 1
        monthlyWeekday = .monday
        yearlyMonth = 1
        yearlyDay = 1
    }
}
