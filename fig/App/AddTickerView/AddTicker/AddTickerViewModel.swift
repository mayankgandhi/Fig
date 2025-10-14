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
        labelViewModel.isValid && countdownViewModel.isValid
    }

    // MARK: - Methods

    func updateSmartDate() {
        calendarViewModel.updateSmartDate(
            for: timePickerViewModel.selectedHour,
            minute: timePickerViewModel.selectedMinute
        )
    }

    @MainActor
    func saveTicker() async {
        guard !isSaving else { return }
        guard canSave else {
            errorMessage = "Please check your inputs"
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

        let schedule: TickerSchedule
        if repeatViewModel.isDailyRepeat {
            schedule = .daily(time: TickerSchedule.TimeOfDay(
                hour: timePickerViewModel.selectedHour,
                minute: timePickerViewModel.selectedMinute
            ))
        } else {
            schedule = .oneTime(date: finalDate)
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

            case .daily(let time):
                print("      → Setting daily schedule for: \(time.hour):\(time.minute)")
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                repeatViewModel.selectOption(.daily)

                // Set selectedDate to next occurrence
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = time.hour
                components.minute = time.minute
                guard let todayOccurrence = calendar.date(from: components) else {
                    print("      ⚠️ Failed to create date from components")
                    return
                }

                if todayOccurrence <= now {
                    calendarViewModel.selectedDate = calendar.date(byAdding: .day, value: 1, to: todayOccurrence) ?? todayOccurrence
                } else {
                    calendarViewModel.selectedDate = todayOccurrence
                }
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
