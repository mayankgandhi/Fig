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
        print("🚀 AddTickerViewModel.saveTicker() started")
        print("   → isSaving: \(isSaving)")
        print("   → canSave: \(canSave)")
        print("   → isEditMode: \(isEditMode)")
        print("   → prefillTemplate: \(prefillTemplate?.id.uuidString ?? "nil")")
        
        guard !isSaving else { 
            print("   ❌ Already saving, returning early")
            return 
        }
        guard canSave else {
            print("   ❌ Cannot save - validation failed")
            errorMessage = "Please check your inputs"
            print("   → Generic validation error")
            showingError = true
            return
        }

        print("   ✅ Validation passed, starting save process")
        isSaving = true
        defer { 
            print("   🔄 Setting isSaving to false")
            isSaving = false 
        }

        // Build schedule
        print("   📅 Building schedule configuration")
        print("   → selectedDate: \(scheduleViewModel.selectedDate)")
        print("   → selectedHour: \(timePickerViewModel.selectedHour)")
        print("   → selectedMinute: \(timePickerViewModel.selectedMinute)")
        print("   → selectedOption: \(scheduleViewModel.selectedOption)")
        
        var components = calendar.dateComponents([.year, .month, .day], from: scheduleViewModel.selectedDate)
        components.hour = timePickerViewModel.selectedHour
        components.minute = timePickerViewModel.selectedMinute

        guard let finalDate = calendar.date(from: components) else {
            print("   ❌ Invalid date configuration")
            errorMessage = "Invalid date configuration"
            showingError = true
            return
        }
        print("   → finalDate: \(finalDate)")

        let time = TickerSchedule.TimeOfDay(
            hour: timePickerViewModel.selectedHour,
            minute: timePickerViewModel.selectedMinute
        )
        print("   → time: \(time.hour):\(time.minute)")

        let schedule: TickerSchedule
        print("   → Building schedule for option: \(scheduleViewModel.selectedOption)")
        switch scheduleViewModel.selectedOption {
        case .oneTime:
            print("   → Creating one-time schedule")
            schedule = .oneTime(date: finalDate)

        case .daily:
            print("   → Creating daily schedule")
            schedule = .daily(time: time)

        case .weekdays:
            print("   → Creating weekdays schedule")
            print("   → selectedWeekdays: \(scheduleViewModel.selectedWeekdays)")
            guard !scheduleViewModel.selectedWeekdays.isEmpty else {
                print("   ❌ No weekdays selected")
                errorMessage = "Please select at least one weekday"
                showingError = true
                return
            }
            schedule = .weekdays(time: time, days: scheduleViewModel.selectedWeekdays)

        case .hourly:
            print("   → Creating hourly schedule")
            print("   → hourlyInterval: \(scheduleViewModel.hourlyInterval)")
            print("   → hourlyStartTime: \(scheduleViewModel.hourlyStartTime)")
            print("   → hourlyEndTime: \(scheduleViewModel.hourlyEndTime?.description ?? "nil")")
            // Validate hourly configuration
            guard scheduleViewModel.hourlyInterval >= 1 else {
                print("   ❌ Hourly interval too small")
                errorMessage = "Hourly interval must be at least 1 hour"
                showingError = true
                return
            }
            if let end = scheduleViewModel.hourlyEndTime, end <= scheduleViewModel.hourlyStartTime {
                print("   ❌ Hourly end time before start time")
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
            print("   → Creating every schedule")
            print("   → everyInterval: \(scheduleViewModel.everyInterval)")
            print("   → everyUnit: \(scheduleViewModel.everyUnit)")
            print("   → everyStartTime: \(scheduleViewModel.everyStartTime)")
            print("   → everyEndTime: \(scheduleViewModel.everyEndTime?.description ?? "nil")")
            // Validate every configuration
            guard scheduleViewModel.everyInterval >= 1 else {
                print("   ❌ Every interval too small")
                errorMessage = "Interval must be at least 1"
                showingError = true
                return
            }
            if let end = scheduleViewModel.everyEndTime, end <= scheduleViewModel.everyStartTime {
                print("   ❌ Every end time before start time")
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
            print("   → Creating biweekly schedule")
            print("   → biweeklyWeekdays: \(scheduleViewModel.biweeklyWeekdays)")
            guard !scheduleViewModel.biweeklyWeekdays.isEmpty else {
                print("   ❌ No biweekly weekdays selected")
                errorMessage = "Please select at least one weekday for biweekly repeat"
                showingError = true
                return
            }
            schedule = .biweekly(
                time: time,
                weekdays: scheduleViewModel.biweeklyWeekdays
            )

        case .monthly:
            print("   → Creating monthly schedule")
            print("   → monthlyDayType: \(scheduleViewModel.monthlyDayType)")
            print("   → monthlyFixedDay: \(scheduleViewModel.monthlyFixedDay)")
            print("   → monthlyWeekday: \(scheduleViewModel.monthlyWeekday)")
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
            print("   → Creating yearly schedule")
            print("   → yearlyMonth: \(scheduleViewModel.yearlyMonth)")
            print("   → yearlyDay: \(scheduleViewModel.yearlyDay)")
            schedule = .yearly(
                month: scheduleViewModel.yearlyMonth,
                day: scheduleViewModel.yearlyDay,
                time: time
            )
        }

        // Build countdown
        print("   ⏰ Building countdown configuration")
        print("   → countdownEnabled: \(countdownViewModel.isEnabled)")
        let countdown: TickerCountdown?
        if countdownViewModel.isEnabled {
            print("   → countdownHours: \(countdownViewModel.hours)")
            print("   → countdownMinutes: \(countdownViewModel.minutes)")
            print("   → countdownSeconds: \(countdownViewModel.seconds)")
            let duration = TickerCountdown.CountdownDuration(
                hours: countdownViewModel.hours,
                minutes: countdownViewModel.minutes,
                seconds: countdownViewModel.seconds
            )
            countdown = TickerCountdown(preAlert: duration, postAlert: nil)
        } else {
            print("   → No countdown configured")
            countdown = nil
        }

        // Build presentation
        print("   🎨 Building presentation configuration")
        let presentation = TickerPresentation(
            tintColorHex: nil,
            secondaryButtonType: .none
        )

        // Build ticker data
        print("   📝 Building ticker data")
        print("   → labelText: '\(labelViewModel.labelText)'")
        print("   → selectedIcon: \(iconPickerViewModel.selectedIcon)")
        print("   → selectedColorHex: \(iconPickerViewModel.selectedColorHex)")
        let tickerData = TickerData(
            name: labelViewModel.labelText.isEmpty ? "Ticker" : labelViewModel.labelText,
            icon: iconPickerViewModel.selectedIcon,
            colorHex: iconPickerViewModel.selectedColorHex
        )

        print("   💾 Starting save operation")
        do {
            if isEditMode, let existingTicker = prefillTemplate {
                print("   → Edit mode: Updating existing ticker")
                print("   → existingTicker ID: \(existingTicker.id)")
                existingTicker.label = labelViewModel.labelText.isEmpty ? "Ticker" : labelViewModel.labelText
                existingTicker.schedule = schedule
                existingTicker.countdown = countdown
                existingTicker.presentation = presentation
                existingTicker.tickerData = tickerData

                print("   → Calling tickerService.updateAlarm()")
                try await tickerService.updateAlarm(existingTicker, context: modelContext)
                print("   → updateAlarm() completed successfully")
            } else {
                print("   → Create mode: Scheduling new alarm")
                let ticker = Ticker(
                    label: labelViewModel.labelText.isEmpty ? "Ticker" : labelViewModel.labelText,
                    isEnabled: true,
                    schedule: schedule,
                    countdown: countdown,
                    presentation: presentation,
                    tickerData: tickerData
                )
                print("   → Created ticker with ID: \(ticker.id)")

                print("   → Calling tickerService.scheduleAlarm()")
                try await tickerService.scheduleAlarm(from: ticker, context: modelContext)
                print("   → scheduleAlarm() completed successfully")
            }

            print("   ✅ Save operation completed successfully")
            TickerHaptics.success()
        } catch {
            print("   ❌ Save operation failed with error: \(error)")
            print("   → Error type: \(type(of: error))")
            print("   → Error description: \(error.localizedDescription)")
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
                scheduleViewModel.selectedDate = date >= now ? date : now
                scheduleViewModel.selectOption(.oneTime)

            case .daily(let time):
                print("      → Setting daily schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                scheduleViewModel.selectOption(.daily)

            case .hourly(let interval, let startTime, let endTime):
                print("      → Setting hourly schedule: every \(interval)h")
                timePickerViewModel.setTimeFromDate(startTime)
                scheduleViewModel.selectedDate = startTime
                scheduleViewModel.selectOption(.hourly)
                scheduleViewModel.hourlyInterval = interval
                scheduleViewModel.hourlyStartTime = startTime
                scheduleViewModel.hourlyEndTime = endTime

            case .every(let interval, let unit, let startTime, let endTime):
                print("      → Setting every schedule: every \(interval) \(unit.displayName)")
                timePickerViewModel.setTimeFromDate(startTime)
                scheduleViewModel.selectedDate = startTime
                scheduleViewModel.selectOption(.every)
                scheduleViewModel.everyInterval = interval
                scheduleViewModel.everyUnit = unit
                scheduleViewModel.everyStartTime = startTime
                scheduleViewModel.everyEndTime = endTime

            case .weekdays(let time, let days):
                print("      → Setting weekdays schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                scheduleViewModel.selectOption(.weekdays)
                scheduleViewModel.selectedWeekdays = days

            case .biweekly(let time, let weekdays):
                print("      → Setting biweekly schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                scheduleViewModel.selectOption(.biweekly)
                scheduleViewModel.biweeklyWeekdays = weekdays

            case .monthly(let day, let time):
                print("      → Setting monthly schedule for: \(time.hour):\(time.minute)")
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
                print("      → Setting yearly schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                scheduleViewModel.selectOption(.yearly)
                scheduleViewModel.yearlyMonth = month
                scheduleViewModel.yearlyDay = day
            }
        } else {
            print("   ⚠️ No schedule found in template - using defaults")
            // Set default time to current time
            let components = calendar.dateComponents([.hour, .minute], from: now)
            timePickerViewModel.setTime(hour: components.hour ?? 12, minute: components.minute ?? 0)
            scheduleViewModel.selectedDate = now
            scheduleViewModel.selectOption(.oneTime)
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
