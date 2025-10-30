//
//  NaturalLanguageViewModel.swift
//  fig
//
//  Main coordinator ViewModel for NaturalLanguageTickerView
//  Manages AI parsing and coordinates child view models for MVVM architecture
//

import Foundation
import SwiftData
import Observation
import TickerCore

@MainActor
@Observable
final class NaturalLanguageViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let tickerService: TickerService

    // MARK: - AI Generator
    @ObservationIgnored var aiGenerator: AITickerGenerator

    // MARK: - Child ViewModels
    var timePickerViewModel: TimePickerViewModel
    var scheduleViewModel: ScheduleViewModel
    var labelViewModel: LabelEditorViewModel
    var countdownViewModel: CountdownConfigViewModel
    var iconPickerViewModel: IconPickerViewModel
    var soundPickerViewModel: SoundPickerViewModel
    var optionsPillsViewModel: OptionsPillsViewModel

    // MARK: - State
    var isSaving: Bool = false
    var errorMessage: String?
    var showingError: Bool = false
    var inputText: String = "" {
        didSet {
            handleInputChange()
        }
    }
    var hasStartedTyping: Bool = false

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        tickerService: TickerService
    ) {
        self.modelContext = modelContext
        self.tickerService = tickerService

        // Initialize AI generator (session will be prepared when view appears)
        self.aiGenerator = AITickerGenerator()

        // Initialize child view models
        self.timePickerViewModel = TimePickerViewModel()
        self.scheduleViewModel = ScheduleViewModel()
        self.labelViewModel = LabelEditorViewModel()
        self.countdownViewModel = CountdownConfigViewModel()
        self.iconPickerViewModel = IconPickerViewModel()
        self.soundPickerViewModel = SoundPickerViewModel()
        self.optionsPillsViewModel = OptionsPillsViewModel()

        // Configure OptionsPillsViewModel with references to child view models
        self.optionsPillsViewModel.configure(
            schedule: scheduleViewModel,
            label: labelViewModel,
            countdown: countdownViewModel,
            sound: soundPickerViewModel
        )
    }

    // MARK: - Lifecycle

    /// Call when view appears to initialize and prewarm the AI session
    func prepareForAppearance() async {
        await aiGenerator.prepareSession()
    }

    /// Call when view is dismissed or done to cleanup resources
    func cleanup() {
        aiGenerator.cleanupSession()
    }

    // MARK: - Computed Properties

    var canGenerate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !aiGenerator.isGenerating
    }

    // MARK: - Input Handling

    private func handleInputChange() {
        if !hasStartedTyping && !inputText.isEmpty {
            hasStartedTyping = true
        }

        // Trigger background parsing
        aiGenerator.parseInBackground(from: inputText)
    }

    // MARK: - View Model Synchronization

    /// Updates child view models based on AI parsed configuration
    func updateViewModelsFromParsedConfig() {
        guard let config = aiGenerator.parsedConfiguration else {
            return
        }

        // Update time picker
        timePickerViewModel.setTime(hour: config.time.hour, minute: config.time.minute)

        // Update label
        labelViewModel.setText(config.label)

        // Update schedule (date and repeat)
        scheduleViewModel.selectDate(config.date)

        // Map AI repeat option to schedule view model
        switch config.repeatOption {
        case .oneTime:
            scheduleViewModel.selectOption(.oneTime)

        case .daily:
            scheduleViewModel.selectOption(.daily)

        case .weekdays(let weekdays):
            scheduleViewModel.selectOption(.weekdays)
            scheduleViewModel.selectedWeekdays = weekdays

        case .hourly(let interval):
            scheduleViewModel.selectOption(.hourly)
            scheduleViewModel.hourlyInterval = interval

        case .every(let interval, let unit):
            scheduleViewModel.selectOption(.every)
            scheduleViewModel.everyInterval = interval
            scheduleViewModel.everyUnit = unit

        case .biweekly(let weekdays):
            scheduleViewModel.selectOption(.biweekly)
            scheduleViewModel.biweeklyWeekdays = weekdays

        case .monthly(let monthlyDay):
            scheduleViewModel.selectOption(.monthly)
            switch monthlyDay {
            case .fixed(let day):
                scheduleViewModel.monthlyDayType = .fixed
                scheduleViewModel.monthlyFixedDay = day
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

        case .yearly(let month, let day):
            scheduleViewModel.selectOption(.yearly)
            scheduleViewModel.yearlyMonth = month
            scheduleViewModel.yearlyDay = day
        }

        // Update countdown
        if let countdown = config.countdown {
            countdownViewModel.enable()
            countdownViewModel.setDuration(
                hours: countdown.hours,
                minutes: countdown.minutes,
                seconds: countdown.seconds
            )
        } else {
            countdownViewModel.disable()
        }

        // Update icon and color
        iconPickerViewModel.selectIcon(config.icon, colorHex: config.colorHex)
    }

    // MARK: - Generation & Saving

    func generateAndSave() async {
        guard canGenerate else { return }

        isSaving = true
        errorMessage = nil
        showingError = false
        defer { isSaving = false }

        do {
            // Generate final configuration from AI
            let configuration = try await aiGenerator.generateTickerConfiguration(from: inputText)

            // Update view models one final time with the complete configuration
            aiGenerator.parsedConfiguration = configuration
            updateViewModelsFromParsedConfig()

            // Create ticker from view models (allowing for user edits)
            let ticker = try createTickerFromViewModels()

            // Save the ticker
            modelContext.insert(ticker)
            try modelContext.save()

            // Schedule the alarm
            try await tickerService.scheduleAlarm(from: ticker, context: modelContext)

            TickerHaptics.success()
        } catch {
            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - SiriKit Donation
    


    // MARK: - Ticker Creation

    private func createTickerFromViewModels() throws -> Ticker {
    
        let parser = TickerConfigurationParser()

        // Build configuration from view models
        let configuration = TickerConfiguration(
            label: labelViewModel.labelText.isEmpty ? "Alarm" : labelViewModel.labelText,
            time: TickerConfiguration.TimeOfDay(
                hour: timePickerViewModel.selectedHour,
                minute: timePickerViewModel.selectedMinute
            ),
            date: scheduleViewModel.selectedDate,
            repeatOption: mapScheduleToAIRepeatOption(),
            countdown: countdownViewModel.isEnabled ? TickerConfiguration.CountdownConfiguration(
                hours: countdownViewModel.hours,
                minutes: countdownViewModel.minutes,
                seconds: countdownViewModel.seconds
            ) : nil,
            icon: iconPickerViewModel.selectedIcon,
            colorHex: iconPickerViewModel.selectedColorHex
        )

        let ticker = parser.parseToTicker(from: configuration)

        ticker.soundName = soundPickerViewModel.selectedSound?.fileName

        return ticker
    }

    private func mapScheduleToAIRepeatOption() -> AITickerGenerator.RepeatOption {
        switch scheduleViewModel.selectedOption {
        case .oneTime:
            return .oneTime
        case .daily:
            return .daily
        case .weekdays:
            return .weekdays(scheduleViewModel.selectedWeekdays)
        case .hourly:
            return .hourly(
                interval: scheduleViewModel.hourlyInterval,
            )
        case .every:
            return .every(
                interval: scheduleViewModel.everyInterval,
                unit: scheduleViewModel.everyUnit,
            )
        case .biweekly:
            return .biweekly(scheduleViewModel.biweeklyWeekdays)
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
            return .monthly(day: monthlyDay)
        case .yearly:
            return .yearly(month: scheduleViewModel.yearlyMonth, day: scheduleViewModel.yearlyDay)
        }
    }
}
