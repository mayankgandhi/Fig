//
//  AddTickerViewModel.swift
//  fig
//
//  Main coordinator ViewModel for AddTickerView
//

import Foundation
import SwiftData

@Observable
final class AddTickerViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let tickerService: TickerService
    private let calendar: Calendar

    // MARK: - Child ViewModels
    var timePickerViewModel: TimePickerViewModel
    var optionsPillsViewModel: OptionsPillsViewModel
    var scheduleViewModel: ScheduleViewModel
    var labelViewModel: LabelEditorViewModel
    var countdownViewModel: CountdownConfigViewModel
    var iconPickerViewModel: IconPickerViewModel

    // MARK: - State
    var isSaving: Bool = false
    var errorMessage: String?
    var showingError: Bool = false
    let isEditMode: Bool
    private let prefillTemplate: Ticker?

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        tickerService: TickerService,
        prefillTemplate: Ticker? = nil,
        isEditMode: Bool = false
    ) {
        self.modelContext = modelContext
        self.tickerService = tickerService
        self.calendar = .current
        self.prefillTemplate = prefillTemplate
        self.isEditMode = isEditMode

        // Initialize child ViewModels
        self.timePickerViewModel = TimePickerViewModel()
        self.scheduleViewModel = ScheduleViewModel()
        self.labelViewModel = LabelEditorViewModel()
        self.countdownViewModel = CountdownConfigViewModel()
        self.iconPickerViewModel = IconPickerViewModel()
        self.optionsPillsViewModel = OptionsPillsViewModel()

        // Configure OptionsPillsViewModel with references to child view models
        // This enables reactive computed properties
        self.optionsPillsViewModel.configure(
            schedule: scheduleViewModel,
            label: labelViewModel,
            countdown: countdownViewModel
        )

        // Prefill if editing
        if let template = prefillTemplate {
            prefillFromTemplate(template)
        }
    }

    // MARK: - Computed Properties

    var canSave: Bool {
        labelViewModel.isValid && countdownViewModel.isValid && scheduleViewModel.repeatConfigIsValid
    }


    /// Aggregated validation messages for inline UI presentation
    var validationMessages: [String] {
        var messages: [String] = []

        if !labelViewModel.isValid {
            messages.append("Label must be 50 characters or fewer")
        }
        if !countdownViewModel.isValid {
            messages.append("Countdown must be greater than 0 seconds")
        }

        switch scheduleViewModel.selectedOption {
        case .weekdays:
            if scheduleViewModel.selectedWeekdays.isEmpty {
                messages.append("Select at least one weekday")
            }
        case .biweekly:
            if scheduleViewModel.biweeklyWeekdays.isEmpty {
                messages.append("Select at least one weekday for biweekly repeat")
            }
        case .hourly:
            if scheduleViewModel.hourlyInterval < 1 {
                messages.append("Hourly interval must be at least 1 hour")
            }
            if let end = scheduleViewModel.hourlyEndTime, end <= scheduleViewModel.hourlyStartTime {
                messages.append("Hourly end time must be after start time")
            }
        case .every:
            if scheduleViewModel.everyInterval < 1 {
                messages.append("Interval must be at least 1")
            }
            if let end = scheduleViewModel.everyEndTime, end <= scheduleViewModel.everyStartTime {
                messages.append("End time must be after start time")
            }
        case .monthly:
            if scheduleViewModel.monthlyDayType == .fixed && !(1...31).contains(scheduleViewModel.monthlyFixedDay) {
                messages.append("Monthly day must be between 1 and 31")
            }
        case .yearly:
            if !(1...12).contains(scheduleViewModel.yearlyMonth) || !(1...31).contains(scheduleViewModel.yearlyDay) {
                messages.append("Select a valid month and day")
            }
        default:
            break
        }

        return messages
    }

    // MARK: - Methods

    func updateSmartDate() {
        scheduleViewModel.updateSmartDate(
            for: timePickerViewModel.selectedHour,
            minute: timePickerViewModel.selectedMinute
        )
    }


    func saveTicker() async {
        guard !isSaving else { 
            return 
        }
        guard canSave else {
            errorMessage = "Please check your inputs"
            showingError = true
            return
        }

        isSaving = true
        defer { 
            isSaving = false 
        }

        // Build schedule
        
        var components = calendar.dateComponents([.year, .month, .day], from: scheduleViewModel.selectedDate)
        components.hour = timePickerViewModel.selectedHour
        components.minute = timePickerViewModel.selectedMinute

        guard let finalDate = calendar.date(from: components) else {
            errorMessage = "Invalid date configuration"
            showingError = true
            return
        }

        let time = TickerSchedule.TimeOfDay(
            hour: timePickerViewModel.selectedHour,
            minute: timePickerViewModel.selectedMinute
        )

        let schedule: TickerSchedule
        switch scheduleViewModel.selectedOption {
        case .oneTime:
            schedule = .oneTime(date: finalDate)

        case .daily:
            schedule = .daily(time: time)

        case .weekdays:
            guard !scheduleViewModel.selectedWeekdays.isEmpty else {
                errorMessage = "Please select at least one weekday"
                showingError = true
                return
            }
            schedule = .weekdays(time: time, days: scheduleViewModel.selectedWeekdays)

        case .hourly:
            // Validate hourly configuration
            guard scheduleViewModel.hourlyInterval >= 1 else {
                errorMessage = "Hourly interval must be at least 1 hour"
                showingError = true
                return
            }
            if let end = scheduleViewModel.hourlyEndTime, end <= scheduleViewModel.hourlyStartTime {
                errorMessage = "Hourly end time must be after start time"
                showingError = true
                return
            }
            schedule = .hourly(
                interval: scheduleViewModel.hourlyInterval,
                startTime: scheduleViewModel.hourlyStartTime,
                endTime: scheduleViewModel.hourlyEndTime
            )

        case .every:
            // Validate every configuration
            guard scheduleViewModel.everyInterval >= 1 else {
                errorMessage = "Interval must be at least 1"
                showingError = true
                return
            }
            if let end = scheduleViewModel.everyEndTime, end <= scheduleViewModel.everyStartTime {
                errorMessage = "End time must be after start time"
                showingError = true
                return
            }
            schedule = .every(
                interval: scheduleViewModel.everyInterval,
                unit: scheduleViewModel.everyUnit,
                startTime: scheduleViewModel.everyStartTime,
                endTime: scheduleViewModel.everyEndTime
            )

        case .biweekly:
            guard !scheduleViewModel.biweeklyWeekdays.isEmpty else {
                errorMessage = "Please select at least one weekday for biweekly repeat"
                showingError = true
                return
            }
            schedule = .biweekly(
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
            schedule = .monthly(day: monthlyDay, time: time)

        case .yearly:
            schedule = .yearly(
                month: scheduleViewModel.yearlyMonth,
                day: scheduleViewModel.yearlyDay,
                time: time
            )
        }

        // Build countdown
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

        // Build presentation
        let presentation = TickerPresentation(
            tintColorHex: nil,
            secondaryButtonType: .none
        )

        // Build ticker data
        let tickerData = TickerData(
            name: labelViewModel.labelText.isEmpty ? "Alarm" : labelViewModel.labelText,
            icon: iconPickerViewModel.selectedIcon,
            colorHex: iconPickerViewModel.selectedColorHex
        )

        do {
            if isEditMode, let existingTicker = prefillTemplate {
                existingTicker.label = labelViewModel.labelText.isEmpty ? "Alarm" : labelViewModel.labelText
                existingTicker.schedule = schedule
                existingTicker.countdown = countdown
                existingTicker.presentation = presentation
                existingTicker.tickerData = tickerData

                try await tickerService.updateAlarm(existingTicker, context: modelContext)
            } else {
                let ticker = Ticker(
                    label: labelViewModel.labelText.isEmpty ? "Alarm" : labelViewModel.labelText,
                    isEnabled: true,
                    schedule: schedule,
                    countdown: countdown,
                    presentation: presentation,
                    tickerData: tickerData
                )

                try await tickerService.scheduleAlarm(from: ticker, context: modelContext)
            }

            TickerHaptics.success()
        } catch {
            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - Private Methods

    private func prefillFromTemplate(_ template: Ticker) {
        let now = Date()

        // Populate schedule data
        if let schedule = template.schedule {
            switch schedule {
            case .oneTime(let date):
                timePickerViewModel.setTimeFromDate(date)
                scheduleViewModel.selectedDate = date >= now ? date : now
                scheduleViewModel.selectOption(.oneTime)

            case .daily(let time):
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                scheduleViewModel.selectOption(.daily)

            case .hourly(let interval, let startTime, let endTime):
                timePickerViewModel.setTimeFromDate(startTime)
                scheduleViewModel.selectedDate = startTime
                scheduleViewModel.selectOption(.hourly)
                scheduleViewModel.hourlyInterval = interval
                scheduleViewModel.hourlyStartTime = startTime
                scheduleViewModel.hourlyEndTime = endTime

            case .every(let interval, let unit, let startTime, let endTime):
                timePickerViewModel.setTimeFromDate(startTime)
                scheduleViewModel.selectedDate = startTime
                scheduleViewModel.selectOption(.every)
                scheduleViewModel.everyInterval = interval
                scheduleViewModel.everyUnit = unit
                scheduleViewModel.everyStartTime = startTime
                scheduleViewModel.everyEndTime = endTime

            case .weekdays(let time, let days):
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                scheduleViewModel.selectOption(.weekdays)
                scheduleViewModel.selectedWeekdays = days

            case .biweekly(let time, let weekdays):
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                scheduleViewModel.selectOption(.biweekly)
                scheduleViewModel.biweeklyWeekdays = weekdays

            case .monthly(let day, let time):
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                scheduleViewModel.selectOption(.monthly)
                switch day {
                case .fixed(let d):
                    scheduleViewModel.monthlyDayType = .fixed
                    scheduleViewModel.monthlyFixedDay = d
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

            case .yearly(let month, let day, let time):
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                scheduleViewModel.selectOption(.yearly)
                scheduleViewModel.yearlyMonth = month
                scheduleViewModel.yearlyDay = day
            }
        } else {
            // Set default time to current time
            let components = calendar.dateComponents([.hour, .minute], from: now)
            timePickerViewModel.setTime(hour: components.hour ?? 12, minute: components.minute ?? 0)
            scheduleViewModel.selectedDate = now
            scheduleViewModel.selectOption(.oneTime)
        }

        // Populate label
        labelViewModel.setText(template.label)

        // Populate countdown
        if let countdown = template.countdown?.preAlert {
            countdownViewModel.isEnabled = true
            countdownViewModel.setDuration(
                hours: countdown.hours,
                minutes: countdown.minutes,
                seconds: countdown.seconds
            )
        }

        // Populate icon and color
        if let tickerData = template.tickerData {
            let icon = tickerData.icon ?? "alarm"
            let colorHex = tickerData.colorHex ?? "#8B5CF6"
            iconPickerViewModel.selectIcon(icon, colorHex: colorHex)
        } else {
            iconPickerViewModel.selectIcon("alarm", colorHex: "#8B5CF6")
        }
    }
}
