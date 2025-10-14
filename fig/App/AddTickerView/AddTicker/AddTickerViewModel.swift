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
    var calendarViewModel: CalendarPickerViewModel
    var repeatViewModel: RepeatOptionsViewModel
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
        self.calendarViewModel = CalendarPickerViewModel()
        self.repeatViewModel = RepeatOptionsViewModel()
        self.labelViewModel = LabelEditorViewModel()
        self.countdownViewModel = CountdownConfigViewModel()
        self.iconPickerViewModel = IconPickerViewModel()
        self.optionsPillsViewModel = OptionsPillsViewModel()

        // Configure OptionsPillsViewModel with references to child view models
        // This enables reactive computed properties
        self.optionsPillsViewModel.configure(
            calendar: calendarViewModel,
            repeat: repeatViewModel,
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
        labelViewModel.isValid && countdownViewModel.isValid && repeatConfigIsValid && !hasDateWeekdayMismatch
    }
    
    /// Checks if the selected date conflicts with the selected weekdays
    var hasDateWeekdayMismatch: Bool {
        guard repeatViewModel.selectedOption == .weekdays else { return false }
        guard !repeatViewModel.selectedWeekdays.isEmpty else { return false }
        
        let selectedWeekday = calendar.component(.weekday, from: calendarViewModel.selectedDate)
        // Convert Calendar weekday (1=Sunday) to our Weekday enum (0=Sunday)
        let adjustedWeekday = (selectedWeekday == 1) ? 0 : selectedWeekday - 1
        
        guard let tickerWeekday = TickerSchedule.Weekday(rawValue: adjustedWeekday) else { return true }
        
        return !repeatViewModel.selectedWeekdays.contains(tickerWeekday)
    }
    
    /// Returns a helpful message about the date/weekday mismatch
    var dateWeekdayMismatchMessage: String? {
        guard hasDateWeekdayMismatch else { return nil }
        
        let selectedWeekday = calendar.component(.weekday, from: calendarViewModel.selectedDate)
        let adjustedWeekday = (selectedWeekday == 1) ? 0 : selectedWeekday - 1
        
        guard let tickerWeekday = TickerSchedule.Weekday(rawValue: adjustedWeekday) else { return nil }
        
        let selectedDayNames = repeatViewModel.selectedWeekdays.map { $0.displayName }.joined(separator: ", ")
        return "Selected date (\(tickerWeekday.displayName)) doesn't match selected days (\(selectedDayNames))"
    }

    /// Validates configuration specific to the selected repeat option
    var repeatConfigIsValid: Bool {
        switch repeatViewModel.selectedOption {
        case .noRepeat, .daily:
            return true
        case .weekdays:
            return !repeatViewModel.selectedWeekdays.isEmpty
        case .hourly:
            if repeatViewModel.hourlyInterval < 1 { return false }
            if let end = repeatViewModel.hourlyEndTime {
                return end > repeatViewModel.hourlyStartTime
            }
            return true
        case .biweekly:
            return !repeatViewModel.biweeklyWeekdays.isEmpty
        case .monthly:
            if repeatViewModel.monthlyDayType == .fixed {
                return (1...31).contains(repeatViewModel.monthlyFixedDay)
            }
            return true
        case .yearly:
            return (1...12).contains(repeatViewModel.yearlyMonth) && (1...31).contains(repeatViewModel.yearlyDay)
        }
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
        if let mismatch = dateWeekdayMismatchMessage { messages.append(mismatch) }

        switch repeatViewModel.selectedOption {
        case .weekdays:
            if repeatViewModel.selectedWeekdays.isEmpty {
                messages.append("Select at least one weekday")
            }
        case .biweekly:
            if repeatViewModel.biweeklyWeekdays.isEmpty {
                messages.append("Select at least one weekday for biweekly repeat")
            }
        case .hourly:
            if repeatViewModel.hourlyInterval < 1 {
                messages.append("Hourly interval must be at least 1 hour")
            }
            if let end = repeatViewModel.hourlyEndTime, end <= repeatViewModel.hourlyStartTime {
                messages.append("Hourly end time must be after start time")
            }
        case .monthly:
            if repeatViewModel.monthlyDayType == .fixed && !(1...31).contains(repeatViewModel.monthlyFixedDay) {
                messages.append("Monthly day must be between 1 and 31")
            }
        case .yearly:
            if !(1...12).contains(repeatViewModel.yearlyMonth) || !(1...31).contains(repeatViewModel.yearlyDay) {
                messages.append("Select a valid month and day")
            }
        default:
            break
        }

        return messages
    }

    // MARK: - Methods

    func updateSmartDate() {
        calendarViewModel.updateSmartDate(
            for: timePickerViewModel.selectedHour,
            minute: timePickerViewModel.selectedMinute
        )
    }
    
    /// Automatically adjusts the selected date to the next occurrence of the selected weekdays
    func adjustDateToMatchWeekdays() {
        guard repeatViewModel.selectedOption == .weekdays else { return }
        guard !repeatViewModel.selectedWeekdays.isEmpty else { return }
        
        let currentDate = calendarViewModel.selectedDate
        let timeComponents = calendar.dateComponents([.hour, .minute], from: currentDate)
        
        // Find the next occurrence of any selected weekday
        var searchDate = currentDate
        for _ in 0..<7 { // Check up to 7 days ahead
            let weekday = calendar.component(.weekday, from: searchDate)
            let adjustedWeekday = (weekday == 1) ? 0 : weekday - 1
            
            if let tickerWeekday = TickerSchedule.Weekday(rawValue: adjustedWeekday),
               repeatViewModel.selectedWeekdays.contains(tickerWeekday) {
                
                // Set the time to match the selected time
                var components = calendar.dateComponents([.year, .month, .day], from: searchDate)
                components.hour = timePickerViewModel.selectedHour
                components.minute = timePickerViewModel.selectedMinute
                
                if let adjustedDate = calendar.date(from: components) {
                    calendarViewModel.selectedDate = adjustedDate
                }
                return
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: searchDate) else { break }
            searchDate = nextDate
        }
    }

    @MainActor
    func saveTicker() async {
        guard !isSaving else { return }
        guard canSave else {
            if hasDateWeekdayMismatch {
                errorMessage = dateWeekdayMismatchMessage ?? "Date and weekday selection don't match"
            } else {
                errorMessage = "Please check your inputs"
            }
            showingError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        // Build schedule
        var components = calendar.dateComponents([.year, .month, .day], from: calendarViewModel.selectedDate)
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
        switch repeatViewModel.selectedOption {
        case .noRepeat:
            schedule = .oneTime(date: finalDate)

        case .daily:
            schedule = .daily(time: time, startDate: calendarViewModel.selectedDate)

        case .weekdays:
            guard !repeatViewModel.selectedWeekdays.isEmpty else {
                errorMessage = "Please select at least one weekday"
                showingError = true
                return
            }
            schedule = .weekdays(time: time, days: repeatViewModel.selectedWeekdays, startDate: calendarViewModel.selectedDate)

        case .hourly:
            // Validate hourly configuration
            guard repeatViewModel.hourlyInterval >= 1 else {
                errorMessage = "Hourly interval must be at least 1 hour"
                showingError = true
                return
            }
            if let end = repeatViewModel.hourlyEndTime, end <= repeatViewModel.hourlyStartTime {
                errorMessage = "Hourly end time must be after start time"
                showingError = true
                return
            }
            schedule = .hourly(
                interval: repeatViewModel.hourlyInterval,
                startTime: repeatViewModel.hourlyStartTime,
                endTime: repeatViewModel.hourlyEndTime
            )

        case .biweekly:
            guard !repeatViewModel.biweeklyWeekdays.isEmpty else {
                errorMessage = "Please select at least one weekday for biweekly repeat"
                showingError = true
                return
            }
            schedule = .biweekly(
                time: time,
                weekdays: repeatViewModel.biweeklyWeekdays,
                anchorDate: repeatViewModel.biweeklyAnchorDate
            )

        case .monthly:
            let monthlyDay: TickerSchedule.MonthlyDay
            switch repeatViewModel.monthlyDayType {
            case .fixed:
                monthlyDay = .fixed(repeatViewModel.monthlyFixedDay)
            case .firstWeekday:
                monthlyDay = .firstWeekday(repeatViewModel.monthlyWeekday)
            case .lastWeekday:
                monthlyDay = .lastWeekday(repeatViewModel.monthlyWeekday)
            case .firstOfMonth:
                monthlyDay = .firstOfMonth
            case .lastOfMonth:
                monthlyDay = .lastOfMonth
            }
            schedule = .monthly(day: monthlyDay, time: time, startDate: calendarViewModel.selectedDate)

        case .yearly:
            schedule = .yearly(
                month: repeatViewModel.yearlyMonth,
                day: repeatViewModel.yearlyDay,
                time: time,
                startDate: calendarViewModel.selectedDate
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
            name: labelViewModel.labelText.isEmpty ? "Ticker" : labelViewModel.labelText,
            icon: iconPickerViewModel.selectedIcon,
            colorHex: iconPickerViewModel.selectedColorHex
        )

        do {
            if isEditMode, let existingTicker = prefillTemplate {
                // Edit mode: Update existing ticker
                existingTicker.label = labelViewModel.labelText.isEmpty ? "Ticker" : labelViewModel.labelText
                existingTicker.schedule = schedule
                existingTicker.countdown = countdown
                existingTicker.presentation = presentation
                existingTicker.tickerData = tickerData

                try await tickerService.updateAlarm(existingTicker, context: modelContext)
            } else {
                // Create mode: Schedule new alarm
                let ticker = Ticker(
                    label: labelViewModel.labelText.isEmpty ? "Ticker" : labelViewModel.labelText,
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
        print("🎨 Starting template prefill...")
        print("   Template ID: \(template.id)")
        print("   Template Label: \(template.label)")
        print("   Template isEnabled: \(template.isEnabled)")
        print("   Template schedule: \(String(describing: template.schedule))")
        print("   Template countdown: \(String(describing: template.countdown))")
        print("   Template tickerData: \(String(describing: template.tickerData))")

        let now = Date()

        // Populate schedule data
        if let schedule = template.schedule {
            print("   ✅ Schedule found: \(schedule)")
            switch schedule {
            case .oneTime(let date):
                print("      → Setting one-time schedule for: \(date)")
                timePickerViewModel.setTimeFromDate(date)
                calendarViewModel.selectedDate = date >= now ? date : now
                repeatViewModel.selectOption(.noRepeat)

            case .daily(let time, let startDate):
                print("      → Setting daily schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                repeatViewModel.selectOption(.daily)

                // Use the start date from the template, but ensure it's not in the past
                calendarViewModel.selectedDate = max(startDate, now)

            case .hourly(let interval, let startTime, let endTime):
                print("      → Setting hourly schedule: every \(interval)h")
                timePickerViewModel.setTimeFromDate(startTime)
                calendarViewModel.selectedDate = startTime
                repeatViewModel.selectOption(.hourly)
                repeatViewModel.hourlyInterval = interval
                repeatViewModel.hourlyStartTime = startTime
                repeatViewModel.hourlyEndTime = endTime

            case .weekdays(let time, let days, let startDate):
                print("      → Setting weekdays schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                repeatViewModel.selectOption(.weekdays)
                repeatViewModel.selectedWeekdays = days
                // Use the start date from the template, but ensure it's not in the past
                calendarViewModel.selectedDate = max(startDate, now)

            case .biweekly(let time, let weekdays, let anchorDate):
                print("      → Setting biweekly schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                repeatViewModel.selectOption(.biweekly)
                repeatViewModel.biweeklyWeekdays = weekdays
                repeatViewModel.biweeklyAnchorDate = anchorDate
                // Set selectedDate to next occurrence
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = time.hour
                components.minute = time.minute
                if let todayOccurrence = calendar.date(from: components) {
                    calendarViewModel.selectedDate = todayOccurrence <= now ? calendar.date(byAdding: .day, value: 1, to: todayOccurrence) ?? todayOccurrence : todayOccurrence
                } else {
                    calendarViewModel.selectedDate = now
                }

            case .monthly(let day, let time, let startDate):
                print("      → Setting monthly schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                repeatViewModel.selectOption(.monthly)
                switch day {
                case .fixed(let d):
                    repeatViewModel.monthlyDayType = .fixed
                    repeatViewModel.monthlyFixedDay = d
                case .firstWeekday(let weekday):
                    repeatViewModel.monthlyDayType = .firstWeekday
                    repeatViewModel.monthlyWeekday = weekday
                case .lastWeekday(let weekday):
                    repeatViewModel.monthlyDayType = .lastWeekday
                    repeatViewModel.monthlyWeekday = weekday
                case .firstOfMonth:
                    repeatViewModel.monthlyDayType = .firstOfMonth
                case .lastOfMonth:
                    repeatViewModel.monthlyDayType = .lastOfMonth
                }
                // Use the start date from the template, but ensure it's not in the past
                calendarViewModel.selectedDate = max(startDate, now)

            case .yearly(let month, let day, let time, let startDate):
                print("      → Setting yearly schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                repeatViewModel.selectOption(.yearly)
                repeatViewModel.yearlyMonth = month
                repeatViewModel.yearlyDay = day
                // Use the start date from the template, but ensure it's not in the past
                calendarViewModel.selectedDate = max(startDate, now)
            }
        } else {
            print("   ⚠️ No schedule found in template - using defaults")
            // Set default time to current time
            let components = calendar.dateComponents([.hour, .minute], from: now)
            timePickerViewModel.setTime(hour: components.hour ?? 12, minute: components.minute ?? 0)
            calendarViewModel.selectedDate = now
            repeatViewModel.selectOption(.noRepeat)
        }

        // Populate label
        print("   → Setting label: '\(template.label)'")
        labelViewModel.setText(template.label)

        // Populate countdown
        if let countdown = template.countdown?.preAlert {
            print("   ✅ Countdown found: \(countdown.hours)h \(countdown.minutes)m \(countdown.seconds)s")
            countdownViewModel.isEnabled = true
            countdownViewModel.setDuration(
                hours: countdown.hours,
                minutes: countdown.minutes,
                seconds: countdown.seconds
            )
        } else {
            print("   → No countdown to set")
        }

        // Populate icon and color
        if let tickerData = template.tickerData {
            let icon = tickerData.icon ?? "alarm"
            let colorHex = tickerData.colorHex ?? "#8B5CF6"
            print("   ✅ TickerData found - Icon: \(icon), Color: \(colorHex)")
            iconPickerViewModel.selectIcon(icon, colorHex: colorHex)
        } else {
            print("   ⚠️ No tickerData found - using defaults")
            iconPickerViewModel.selectIcon("alarm", colorHex: "#8B5CF6")
        }

        print("🎨 Template prefill completed!")
    }
}
