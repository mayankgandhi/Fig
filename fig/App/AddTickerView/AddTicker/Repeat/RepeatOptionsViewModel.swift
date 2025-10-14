//
//  RepeatOptionsViewModel.swift
//  fig
//
//  Manages repeat frequency selection
//

import Foundation

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

    // MARK: - Computed Properties

    var isDailyRepeat: Bool {
        selectedOption == .daily
    }

    var displayIcon: String {
        selectedOption.icon
    }

    var displayText: String {
        selectedOption.rawValue
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
