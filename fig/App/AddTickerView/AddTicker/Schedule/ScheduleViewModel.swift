//
//  ScheduleViewModel.swift
//  fig
//
//  Unified ViewModel managing date selection and repeat frequency
//  Combines CalendarPickerViewModel and RepeatOptionsViewModel with validation
//

import Foundation

@Observable
final class ScheduleViewModel {
    private let calendar: Calendar

    // MARK: - Date Selection (from CalendarPickerViewModel)
    var selectedDate: Date

    // MARK: - Repeat Configuration (from RepeatOptionsViewModel)
    var selectedOption: RepeatOption = .oneTime

    // Configuration for weekdays option
    var selectedWeekdays: Array<TickerSchedule.Weekday> = []

    // Configuration for hourly option
    var hourlyInterval: Int = 1
    var hourlyStartTime: Date = Date()
    var hourlyEndTime: Date?

    // Configuration for every option
    var everyInterval: Int = 1
    var everyUnit: TickerSchedule.TimeUnit = .hours
    var everyStartTime: Date = Date()
    var everyEndTime: Date?

    // Configuration for biweekly option
    var biweeklyWeekdays: Array<TickerSchedule.Weekday> = []

    // Configuration for monthly option
    var monthlyDayType: MonthlyDayType = .fixed
    var monthlyFixedDay: Int = 1
    var monthlyWeekday: TickerSchedule.Weekday = .monday

    // Configuration for yearly option
    var yearlyMonth: Int = 1
    var yearlyDay: Int = 1

    // MARK: - Nested Types (reused from RepeatOptionsViewModel)

    typealias MonthlyDayType = RepeatOptionsViewModel.MonthlyDayType
    typealias RepeatOption = RepeatOptionsViewModel.RepeatOption

    // MARK: - Initialization

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.selectedDate = Date()
    }

    // MARK: - Date Computed Properties

    var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    var isTomorrow: Bool {
        calendar.isDateInTomorrow(selectedDate)
    }

    var displayDate: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        return selectedDate.formatted(.dateTime.month(.abbreviated).day())
    }

    // MARK: - Repeat Computed Properties

    var isDailyRepeat: Bool {
        selectedOption == .daily
    }

    var displayRepeat: String {
        switch selectedOption {
            case .oneTime:
                return "One time"
            case .daily:
                return "Daily"
            case .weekdays:
                if selectedWeekdays.isEmpty {
                    return "Weekdays"
                } else if selectedWeekdays.count == 5 && selectedWeekdays.allSatisfy({ [.monday, .tuesday, .wednesday, .thursday, .friday].contains($0) }) {
                    return "Mon-Fri"
                } else {
                    return "Weekdays"
                }
            case .hourly:
                if hourlyInterval == 1 {
                    return "Hourly"
                } else {
                    return "Every \(hourlyInterval)h"
                }
            case .every:
                let unitName = everyInterval == 1 ? everyUnit.singularName : everyUnit.displayName.lowercased()
                return "Every \(everyInterval) \(unitName)"
            case .biweekly:
                return "Biweekly"
            case .monthly:
                return "Monthly"
            case .yearly:
                return "Yearly"
        }
    }

    var displayRepeatFull: String {
        switch selectedOption {
            case .oneTime:
                return "One time"
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
            case .every:
                let unitName = everyInterval == 1 ? everyUnit.singularName : everyUnit.displayName.lowercased()
                return "Repeats every \(everyInterval) \(unitName)"
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

    /// Whether the calendar grid should be shown
    var shouldShowCalendar: Bool {
        selectedOption == .oneTime
    }

    // MARK: - Unified Display Property

    /// Intelligently combines date and repeat info for pill display
    var displaySchedule: String {
        if selectedOption == .oneTime {
            // Only show date if one time
            return displayDate
        } else {
            // Show "Date, Repeat"
            return "\(displayDate), \(displayRepeat)"
        }
    }

    /// Whether schedule has any non-default value
    var hasScheduleValue: Bool {
        !isToday || selectedOption != .oneTime
    }

    // MARK: - Validation (moved from AddTickerViewModel)

    /// Validates configuration specific to the selected repeat option
    var repeatConfigIsValid: Bool {
        switch selectedOption {
        case .oneTime, .daily:
            return true
        case .weekdays:
            return !selectedWeekdays.isEmpty
        case .hourly:
            if hourlyInterval < 1 { return false }
            if let end = hourlyEndTime {
                return end > hourlyStartTime
            }
            return true
        case .every:
            if everyInterval < 1 { return false }
            if let end = everyEndTime {
                return end > everyStartTime
            }
            return true
        case .biweekly:
            return !biweeklyWeekdays.isEmpty
        case .monthly:
            if monthlyDayType == .fixed {
                return (1...31).contains(monthlyFixedDay)
            }
            return true
        case .yearly:
            return (1...12).contains(yearlyMonth) && (1...31).contains(yearlyDay)
        }
    }

    // MARK: - Date Methods

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func updateSmartDate(for hour: Int, minute: Int) {
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute

        guard let todayWithSelectedTime = calendar.date(from: components) else { return }

        if todayWithSelectedTime < now {
            selectedDate = calendar.date(byAdding: .day, value: 1, to: todayWithSelectedTime) ?? todayWithSelectedTime
        } else {
            selectedDate = todayWithSelectedTime
        }
    }


    // MARK: - Repeat Methods

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
            default:
                break
        }
    }

    func reset() {
        selectedDate = Date()
        selectedOption = .oneTime
        selectedWeekdays = []
        hourlyInterval = 1
        hourlyStartTime = Date()
        hourlyEndTime = nil
        everyInterval = 1
        everyUnit = .hours
        everyStartTime = Date()
        everyEndTime = nil
        biweeklyWeekdays = []
        monthlyDayType = .fixed
        monthlyFixedDay = 1
        monthlyWeekday = .monday
        yearlyMonth = 1
        yearlyDay = 1
    }
}
