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
    var timePickerViewModel: TimePickerViewModel
    var scheduleViewModel: ScheduleViewModel
    var iconPickerViewModel: IconPickerViewModel
    var soundPickerViewModel: SoundPickerViewModel
    var countdownViewModel: CountdownConfigViewModel
    var optionsPillsViewModel: OptionsPillsViewModel

    // MARK: - State
    var shouldShowValidationMessage = false
    private let childToEdit: CollectionChildTickerData?
    private let defaultIcon: String?
    private let defaultColorHex: String?
    private let defaultSoundName: String?

    // MARK: - Initialization

    init(
        childToEdit: CollectionChildTickerData? = nil,
        defaultIcon: String? = nil,
        defaultColorHex: String? = nil,
        defaultSoundName: String? = nil
    ) {
        self.childToEdit = childToEdit
        self.defaultIcon = defaultIcon
        self.defaultColorHex = defaultColorHex
        self.defaultSoundName = defaultSoundName
        self.labelViewModel = LabelEditorViewModel()
        self.timePickerViewModel = TimePickerViewModel()
        self.scheduleViewModel = ScheduleViewModel()
        self.iconPickerViewModel = IconPickerViewModel()
        self.soundPickerViewModel = SoundPickerViewModel()
        self.countdownViewModel = CountdownConfigViewModel()
        self.optionsPillsViewModel = OptionsPillsViewModel()
        
        // Configure OptionsPillsViewModel with references to child view models
        self.optionsPillsViewModel.configure(
            schedule: scheduleViewModel,
            label: labelViewModel,
            countdown: countdownViewModel,
            sound: soundPickerViewModel,
            icon: iconPickerViewModel
        )
        
        // Set default icon and sound from collection if provided
        if let defaultIcon = defaultIcon, let defaultColorHex = defaultColorHex {
            iconPickerViewModel.selectIcon(defaultIcon, colorHex: defaultColorHex)
        }
        
        if let defaultSoundName = defaultSoundName {
            soundPickerViewModel.selectSound(defaultSoundName)
        }

        // Prefill if editing
        if let child = childToEdit {
            prefillFromChild(child)
        }
    }

    // MARK: - Computed Properties

    var canSave: Bool {
        labelViewModel.isValid && scheduleViewModel.repeatConfigIsValid && countdownViewModel.isValid
    }

    var validationMessage: String? {
        if !labelViewModel.isValid {
            return "Label must be 50 characters or fewer"
        }
        if !scheduleViewModel.repeatConfigIsValid {
            return "Please complete schedule configuration"
        }
        if !countdownViewModel.isValid {
            return "Countdown must be greater than 0 seconds"
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

    func collapseField() {
        optionsPillsViewModel.collapseField()
    }

    // MARK: - Create Child Ticker Data

    func createChildTickerData() -> CollectionChildTickerData? {
        guard canSave else { return nil }
        let label = labelViewModel.labelText.isEmpty ? "Alarm" : labelViewModel.labelText
        let schedule = buildSchedule()
        
        // Build countdown if enabled
        let countdown: TickerCountdown?
        if countdownViewModel.isEnabled {
            let duration = TickerCountdown.CountdownDuration(
                hours: countdownViewModel.hours,
                minutes: countdownViewModel.minutes,
                seconds: countdownViewModel.seconds
            )
            countdown = TickerCountdown(preAlert: duration, postAlert: nil)
        } else {
            countdown = nil
        }
        
        // Always store icon, color, and sound values (including defaults)
        let icon = iconPickerViewModel.selectedIcon
        let colorHex = iconPickerViewModel.selectedColorHex
        let soundName = soundPickerViewModel.selectedSound?.fileName

        return CollectionChildTickerData(
            id: childToEdit?.id ?? UUID(),
            label: label,
            schedule: schedule,
            icon: icon,
            colorHex: colorHex,
            soundName: soundName,
            countdown: countdown
        )
    }

    func revealValidationMessage() {
        shouldShowValidationMessage = true
    }

    // MARK: - Private Methods

    private func buildSchedule() -> TickerSchedule {
        let time = TimeOfDay(hour: timePickerViewModel.selectedHour, minute: timePickerViewModel.selectedMinute)

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
        
        // Prefill icon and color - use custom if provided, otherwise defaults
        if let icon = child.icon, let colorHex = child.colorHex {
            iconPickerViewModel.selectIcon(icon, colorHex: colorHex)
        } else if let defaultIcon = defaultIcon, let defaultColorHex = defaultColorHex {
            iconPickerViewModel.selectIcon(defaultIcon, colorHex: defaultColorHex)
        }
        
        // Prefill sound - use custom if provided, otherwise default
        if let soundName = child.soundName {
            soundPickerViewModel.selectSound(soundName)
        } else if let defaultSoundName = defaultSoundName {
            soundPickerViewModel.selectSound(defaultSoundName)
        }
        
        // Prefill countdown if custom
        if let countdown = child.countdown, let preAlert = countdown.preAlert {
            countdownViewModel.isEnabled = true
            countdownViewModel.setDuration(
                hours: preAlert.hours,
                minutes: preAlert.minutes,
                seconds: preAlert.seconds
            )
        }
    }

    private func extractScheduleComponents(from schedule: TickerSchedule) {
        switch schedule {
        case .oneTime(let date):
            scheduleViewModel.selectOption(.oneTime)
            scheduleViewModel.selectDate(date)
            timePickerViewModel.setTimeFromDate(date)

        case .daily(let time):
            scheduleViewModel.selectOption(.daily)
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)
            timePickerViewModel.setTime(hour: time.hour, minute: time.minute)

        case .weekdays(let time, let days):
            scheduleViewModel.selectOption(.weekdays)
            scheduleViewModel.selectedWeekdays = days
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)
            timePickerViewModel.setTime(hour: time.hour, minute: time.minute)

        case .hourly(let interval, let time):
            scheduleViewModel.selectOption(.hourly)
            scheduleViewModel.hourlyInterval = interval
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)
            timePickerViewModel.setTime(hour: time.hour, minute: time.minute)

        case .every(let interval, let unit, let time):
            scheduleViewModel.selectOption(.every)
            scheduleViewModel.everyInterval = interval
            scheduleViewModel.everyUnit = unit
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)
            timePickerViewModel.setTime(hour: time.hour, minute: time.minute)

        case .biweekly(let time, let days):
            scheduleViewModel.selectOption(.biweekly)
            scheduleViewModel.biweeklyWeekdays = days
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)
            timePickerViewModel.setTime(hour: time.hour, minute: time.minute)

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
            timePickerViewModel.setTime(hour: time.hour, minute: time.minute)

        case .yearly(let month, let day, let time):
            scheduleViewModel.selectOption(.yearly)
            scheduleViewModel.yearlyMonth = month
            scheduleViewModel.yearlyDay = day
            scheduleViewModel.updateSmartDate(for: time.hour, minute: time.minute)
            timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
        }
    }
}

