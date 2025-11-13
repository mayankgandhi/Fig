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

    // MARK: - AI Service (Pure)
    private let aiService = AITickerGenerator()
    private let sessionManager = AISessionManager.shared

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
    var isGenerating: Bool = false
    var isParsing: Bool = false
    var parsedConfiguration: TickerConfiguration?
    var isFoundationModelsAvailable: Bool = false
    var errorMessage: String?
    var showingError: Bool = false
    var inputText: String = "" {
        didSet {
            handleInputChange()
        }
    }
    var hasStartedTyping: Bool = false

    // MARK: - Private State
    private var parsingTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        tickerService: TickerService
    ) {
        self.modelContext = modelContext
        self.tickerService = tickerService

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
            sound: soundPickerViewModel,
            icon: iconPickerViewModel
        )
    }

    // MARK: - Lifecycle

    /// Call when view appears to initialize and prewarm the AI session
    func prepareForAppearance() async {
        AnalyticsEvents.aiAlarmCreateStarted.track()
        await sessionManager.prepare()
        isFoundationModelsAvailable = sessionManager.isFoundationModelsAvailable
    }

    /// Call when view is dismissed or done to cleanup resources
    func cleanup() {
        parsingTask?.cancel()
        sessionManager.cleanup()
    }

    // MARK: - Computed Properties

    var canGenerate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isGenerating
    }

    // MARK: - Input Handling

    private func handleInputChange() {
        if !hasStartedTyping && !inputText.isEmpty {
            hasStartedTyping = true
            AnalyticsEvents.aiInputStarted.track()
        }

        // Trigger debounced background parsing
        debouncedParse(inputText)
    }

    /// Debounced parsing with proper async/await
    private func debouncedParse(_ input: String) {
        // Cancel any existing parsing task
        parsingTask?.cancel()

        // Don't parse empty or very short inputs
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedInput.count > 3 else {
            isParsing = false
            parsedConfiguration = nil
            return
        }

        isParsing = true

        parsingTask = Task { @MainActor in
            do {
                // Debounce FIRST - wait before doing any work
                try await Task.sleep(for: .milliseconds(500))

                // Check if task was cancelled during debounce
                guard !Task.isCancelled else {
                    isParsing = false
                    return
                }

                let startTime = Date()

                // NOW parse after debounce
                let config = try await aiService.parseConfiguration(from: input)

                let parseTime = Int(Date().timeIntervalSince(startTime) * 1000)

                // Track parsing completed
                AnalyticsEvents.aiParsingCompleted(
                    inputLength: input.count,
                    parseTimeMs: parseTime
                ).track()

                // Update state on main actor
                self.parsedConfiguration = config
                self.isParsing = false

                // Update view models if config is available
                if config != nil {
                    updateViewModelsFromParsedConfig()
                }
            } catch {
                // Track parsing failed
                AnalyticsEvents.aiParsingFailed(
                    error: error.localizedDescription,
                    inputLength: input.count
                ).track()

                // Handle errors silently for background parsing
                self.isParsing = false
                print("⚠️ NaturalLanguageViewModel: Parsing error - \(error)")
            }
        }
    }

    // MARK: - View Model Synchronization

    /// Updates child view models based on AI parsed configuration
    func updateViewModelsFromParsedConfig() {
        guard let config = parsedConfiguration else {
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
        isGenerating = true
        errorMessage = nil
        showingError = false
        defer {
            isSaving = false
            isGenerating = false
        }

        // Track generation started
        AnalyticsEvents.aiGenerationStarted(inputTextLength: inputText.count).track()
        let startTime = Date()

        do {
            // Generate final configuration from AI service
            let configuration = try await aiService.generateConfiguration(from: inputText)

            let generationTime = Int(Date().timeIntervalSince(startTime) * 1000)

            // Update view models one final time with the complete configuration
            parsedConfiguration = configuration
            updateViewModelsFromParsedConfig()

            // Create ticker from view models (allowing for user edits)
            let ticker = try createTickerFromViewModels()

            let scheduleTypeString = ticker.schedule?.displaySummary ?? "unknown"
            let hasCountdown = ticker.countdown != nil

            // Save the ticker
            modelContext.insert(ticker)
            try modelContext.save()

            // Schedule the alarm
            try await tickerService.scheduleAlarm(from: ticker, context: modelContext)

            // Track AI generation completed
            AnalyticsEvents.aiGenerationCompleted(
                inputLength: inputText.count,
                scheduleType: scheduleTypeString,
                generationTimeMs: generationTime
            ).track()

            // Track AI alarm created
            AnalyticsEvents.aiAlarmCreated(
                scheduleType: scheduleTypeString,
                hasCountdown: hasCountdown,
                creationMethod: "ai"
            ).track()

            TickerHaptics.success()
        } catch {
            // Track AI generation failed
            AnalyticsEvents.aiGenerationFailed(
                error: error.localizedDescription,
                inputLength: inputText.count
            ).track()

            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

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
