//
//  AddCollectionChildTickerViewModel.swift
//  fig
//
//  ViewModel for AddCollectionChildTickerView
//  Manages label and schedule configuration for collection child tickers
//

import Foundation
import TickerCore

@Observable
final class AddCollectionChildTickerViewModel {
    // MARK: - Child ViewModels
    var labelViewModel: LabelEditorViewModel
    var scheduleViewModel: ScheduleViewModel

    // MARK: - State
    var expandedField: SimplifiedExpandableField? = nil
    var shouldShowValidationMessage = false
    private let childToEdit: CollectionChildTickerData?

    // MARK: - Initialization

    init(childToEdit: CollectionChildTickerData? = nil) {
        self.childToEdit = childToEdit
        self.labelViewModel = LabelEditorViewModel()
        self.scheduleViewModel = ScheduleViewModel()

        // Prefill if editing
        if let child = childToEdit {
            prefillFromChild(child)
        }
    }

    // MARK: - Computed Properties

    var canSave: Bool {
        labelViewModel.isValid && scheduleViewModel.repeatConfigIsValid
    }

    var validationMessage: String? {
        if !labelViewModel.isValid {
            return "Label must be 50 characters or fewer"
        }
        if !scheduleViewModel.repeatConfigIsValid {
            return "Please complete schedule configuration"
        }
        return nil
    }

    var validationBannerMessage: String? {
        guard shouldShowValidationMessage else { return nil }
        return validationMessage
    }

    var displayLabel: String {
        labelViewModel.isEmpty ? "Label" : labelViewModel.labelText
    }

    var displaySchedule: String {
        scheduleViewModel.displaySchedule
    }

    // MARK: - Field Management

    func toggleField(_ field: SimplifiedExpandableField) {
        if expandedField == field {
            expandedField = nil
        } else {
            expandedField = field
        }
    }

    func collapseField() {
        expandedField = nil
    }

    // MARK: - Create Child Ticker Data

    func createChildTickerData() -> CollectionChildTickerData? {
        guard canSave else { return nil }
        let label = labelViewModel.labelText.isEmpty ? "Alarm" : labelViewModel.labelText
        let schedule = buildSchedule()

        return CollectionChildTickerData(
            id: childToEdit?.id ?? UUID(),
            label: label,
            schedule: schedule
        )
    }

    func revealValidationMessage() {
        shouldShowValidationMessage = true
    }

    // MARK: - Private Methods

    private func buildSchedule() -> TickerSchedule {
        let time = extractTimeFromSchedule()

        switch scheduleViewModel.selectedOption {
        case .oneTime:
            return .oneTime(date: scheduleViewModel.selectedDate)
        case .daily:
            return .daily(time: time)
        case .weekdays:
            return .weekdays(time: time, days: scheduleViewModel.selectedWeekdays)
        case .hourly:
            return .hourly(
                interval: scheduleViewModel.hourlyInterval,
                time: time
            )
        case .every:
            return .every(
                interval: scheduleViewModel.everyInterval,
                unit: scheduleViewModel.everyUnit,
                time: time
            )
        case .biweekly:
            return .biweekly(
                time: time,
                weekdays: scheduleViewModel.biweeklyWeekdays
            )
        case .monthly:
            let monthlyDay: TickerSchedule.MonthlyDay
            switch scheduleViewModel.monthlyDayType {
            case .fixed:
                monthlyDay = .fixed(scheduleViewModel.monthlyFixedDay)
            case .firstWeekday:
                monthlyDay = .firstWeekday(scheduleViewModel.monthlyWeekday)
            case .lastWeekday:
                monthlyDay = .lastWeekday(scheduleViewModel.monthlyWeekday)
            case .firstOfMonth:
                monthlyDay = .firstOfMonth
            case .lastOfMonth:
                monthlyDay = .lastOfMonth
            }
            return .monthly(day: monthlyDay, time: time)
        case .yearly:
            return .yearly(month: scheduleViewModel.yearlyMonth, day: scheduleViewModel.yearlyDay, time: time)
        }
    }

    private func prefillFromChild(_ child: CollectionChildTickerData) {
        // Prefill label
        labelViewModel.setText(child.label)

        // Extract schedule components and prefill schedule view model
        extractScheduleComponents(from: child.schedule)
    }

    private func extractScheduleComponents(from schedule: TickerSchedule) {
        switch schedule {
        case .oneTime(let date):
            scheduleViewModel.selectOption(.oneTime)
            scheduleViewModel.selectDate(date)

        case .daily(let time):
            scheduleViewModel.selectOption(.daily)
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)

        case .weekdays(let time, let days):
            scheduleViewModel.selectOption(.weekdays)
            scheduleViewModel.selectedWeekdays = days
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)

        case .hourly(let interval, let time):
            scheduleViewModel.selectOption(.hourly)
            scheduleViewModel.hourlyInterval = interval
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)

        case .every(let interval, let unit, let time):
            scheduleViewModel.selectOption(.every)
            scheduleViewModel.everyInterval = interval
            scheduleViewModel.everyUnit = unit
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)

        case .biweekly(let time, let days):
            scheduleViewModel.selectOption(.biweekly)
            scheduleViewModel.biweeklyWeekdays = days
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)

        case .monthly(let day, let time):
            scheduleViewModel.selectOption(.monthly)
            switch day {
            case .fixed(let dayNumber):
                scheduleViewModel.monthlyDayType = .fixed
                scheduleViewModel.monthlyFixedDay = dayNumber
            case .firstWeekday(let weekday):
                scheduleViewModel.monthlyDayType = .firstWeekday
                scheduleViewModel.monthlyWeekday = weekday
            case .lastWeekday(let weekday):
                scheduleViewModel.monthlyDayType = .lastWeekday
                scheduleViewModel.monthlyWeekday = weekday
            case .firstOfMonth:
                scheduleViewModel.monthlyDayType = .firstOfMonth
            case .lastOfMonth:
                scheduleViewModel.monthlyDayType = .lastOfMonth
            }
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)

        case .yearly(let month, let day, let time):
            scheduleViewModel.selectOption(.yearly)
            scheduleViewModel.yearlyMonth = month
            scheduleViewModel.yearlyDay = day
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)
        }
    }

    private func extractTimeFromSchedule() -> TimeOfDay {
        // For schedules that need time, extract from selected date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: scheduleViewModel.selectedDate)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0
        return TimeOfDay(hour: hour, minute: minute)
    }
}

// MARK: - Expandable Field Enum

enum SimplifiedExpandableField: Hashable {
    case label
    case schedule
}
