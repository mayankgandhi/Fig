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
    private let alarmService: AlarmService
    private let calendar: Calendar

    // MARK: - Child ViewModels
    var timePickerViewModel: TimePickerViewModel
    var optionsPillsViewModel: OptionsPillsViewModel
    var calendarViewModel: CalendarPickerViewModel
    var repeatViewModel: RepeatOptionsViewModel
    var labelViewModel: LabelEditorViewModel
    var notesViewModel: NotesEditorViewModel
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
        alarmService: AlarmService,
        prefillTemplate: Ticker? = nil,
        isEditMode: Bool = false
    ) {
        self.modelContext = modelContext
        self.alarmService = alarmService
        self.calendar = .current
        self.prefillTemplate = prefillTemplate
        self.isEditMode = isEditMode

        // Initialize child ViewModels
        self.timePickerViewModel = TimePickerViewModel()
        self.calendarViewModel = CalendarPickerViewModel()
        self.repeatViewModel = RepeatOptionsViewModel()
        self.labelViewModel = LabelEditorViewModel()
        self.notesViewModel = NotesEditorViewModel()
        self.countdownViewModel = CountdownConfigViewModel()
        self.iconPickerViewModel = IconPickerViewModel()
        self.optionsPillsViewModel = OptionsPillsViewModel()

        // Configure OptionsPillsViewModel with references to child view models
        // This enables reactive computed properties
        self.optionsPillsViewModel.configure(
            calendar: calendarViewModel,
            repeat: repeatViewModel,
            label: labelViewModel,
            notes: notesViewModel,
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
                existingTicker.notes = notesViewModel.notesText
                existingTicker.schedule = schedule
                existingTicker.countdown = countdown
                existingTicker.presentation = presentation
                existingTicker.tickerData = tickerData

                try await alarmService.updateAlarm(existingTicker, context: modelContext)
            } else {
                // Create mode: Schedule new alarm
                let ticker = Ticker(
                    label: labelViewModel.labelText.isEmpty ? "Ticker" : labelViewModel.labelText,
                    isEnabled: true,
                    notes: notesViewModel.notesText,
                    schedule: schedule,
                    countdown: countdown,
                    presentation: presentation,
                    tickerData: tickerData
                )

                try await alarmService.scheduleAlarm(from: ticker, context: modelContext)
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
                calendarViewModel.selectedDate = date >= now ? date : now
                repeatViewModel.selectOption(.noRepeat)

            case .daily(let time):
                timePickerViewModel.setTime(hour: time.hour, minute: time.minute)
                repeatViewModel.selectOption(.daily)

                // Set selectedDate to next occurrence
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = time.hour
                components.minute = time.minute
                guard let todayOccurrence = calendar.date(from: components) else { return }

                if todayOccurrence <= now {
                    calendarViewModel.selectedDate = calendar.date(byAdding: .day, value: 1, to: todayOccurrence) ?? todayOccurrence
                } else {
                    calendarViewModel.selectedDate = todayOccurrence
                }
            }
        }

        // Populate label and notes
        labelViewModel.setText(template.label)
        notesViewModel.setNotes(template.notes)

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
            iconPickerViewModel.selectIcon(
                tickerData.icon ?? "alarm",
                colorHex: tickerData.colorHex ?? "#8B5CF6"
            )
        }
    }
}
