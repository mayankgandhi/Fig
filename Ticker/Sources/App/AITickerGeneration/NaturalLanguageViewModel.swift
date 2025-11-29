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
import Factory
import OpenAI

@MainActor
@Observable
final class NaturalLanguageViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    @ObservationIgnored
    @Injected(\.tickerService) private var tickerService

    // MARK: - AI Service
    @ObservationIgnored
    @Injected(\.openAITickerService) private var openAIService

    // MARK: - Network Service
    @ObservationIgnored
    @Injected(\.networkReachabilityService) private var networkReachability

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
    var isGeneratingConfig: Bool = false
    var isCreatingTicker: Bool = false
    var isSchedulingAlarm: Bool = false
    var parsedConfiguration: TickerConfiguration?
    var errorMessage: String?
    var showingError: Bool = false
    var inputText: String = "" {
        didSet {
            handleInputChange()
        }
    }
    var hasStartedTyping: Bool = false
    var isOfflineMode: Bool = false
    var isUsingLocalParser: Bool = false

    // MARK: - Private State
    private var parsingTask: Task<Void, Never>?
    private var currentParsingTaskID: UUID?

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

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



    /// Call when view is dismissed or done to cleanup resources
    func cleanup() {
        parsingTask?.cancel()
    }

    // MARK: - Computed Properties

    var canGenerate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isGenerating &&
        parsedConfiguration != nil
    }
    
    // MARK: - Validation
    
    enum ValidationError: LocalizedError {
        case emptyInput
        case noParsedConfiguration
        case stillParsing
        
        var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Please enter a description for your ticker"
            case .noParsedConfiguration:
                return "We couldn't understand your request. Please try being more specific about the time, activity, and frequency."
            case .stillParsing:
                return "Please wait while we parse your request..."
            }
        }
    }
    
    func validateBeforeGeneration() -> ValidationError? {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if input is empty
        guard !trimmedInput.isEmpty else {
            return .emptyInput
        }
        
        // Check if still parsing
        if isParsing {
            return .stillParsing
        }
        
        // Check if we have a parsed configuration
        guard parsedConfiguration != nil else {
            return .noParsedConfiguration
        }
        
        return nil
    }

    // MARK: - Input Handling

    private func handleInputChange() {
        if !hasStartedTyping && !inputText.isEmpty {
            hasStartedTyping = true
            AnalyticsEvents.aiInputStarted.track()
        }

        // Trigger debounced parsing (shows loading state)
        debouncedParse(inputText)
    }

    /// Debounced parsing with proper async/await
    /// Shows loading state during debounce period (not background parsing)
    private func debouncedParse(_ input: String) {
        // Cancel any existing parsing task
        parsingTask?.cancel()
        currentParsingTaskID = nil

        // Don't parse empty or very short inputs
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedInput.count > 3 else {
            isParsing = false
            parsedConfiguration = nil
            return
        }

        // Create a unique task ID for this parsing operation
        let taskID = UUID()
        currentParsingTaskID = taskID

        // Set loading state immediately - this is user-facing, not background parsing
        isParsing = true

        parsingTask = Task { @MainActor in
            do {
            
                // Debounce FIRST - wait before doing any work
                // Loading state is visible during this period
                try await Task.sleep(for: .milliseconds(1000))

                // Check if task was cancelled during debounce or if a new task started
                guard !Task.isCancelled && self.currentParsingTaskID == taskID else {
                    // Only update state if we're still the current task
                    if self.currentParsingTaskID == taskID {
                        self.isParsing = false
                    }
                    return
                }

                let startTime = Date()

                // NOW parse after debounce - check network and choose parsing strategy
                let config: TickerConfiguration
                if self.networkReachability.isReachable {
                    // Online: Use OpenAI
                    self.isUsingLocalParser = false
                    self.isOfflineMode = false
                    let llkConfig = try await self.openAIService.generateTickerConfig(from: input)
                    config = try llkConfig.toTickerConfiguration()
                } else {
                    // Offline: Use local parser
                    self.isUsingLocalParser = true
                    self.isOfflineMode = true
                    let parser = TickerConfigurationParser()
                    config = try await parser.parseConfiguration(from: input)
                }

                let parseTime = Int(Date().timeIntervalSince(startTime) * 1000)

                // Track parsing completed
                AnalyticsEvents.aiParsingCompleted(
                    inputLength: input.count,
                    parseTimeMs: parseTime,
                    isOffline: self.isUsingLocalParser
                ).track()

                // Only update state if we're still the current task
                guard self.currentParsingTaskID == taskID else {
                    return
                }

                // Update state on main actor
                self.parsedConfiguration = config
                self.isParsing = false

                // Update view models with parsed configuration
                updateViewModelsFromParsedConfig()
                
            } catch {
                // Track parsing failed
                AnalyticsEvents.aiParsingFailed(
                    error: error.localizedDescription,
                    inputLength: input.count,
                    isOffline: self.isUsingLocalParser
                ).track()

                // Only update state if we're still the current task
                if self.currentParsingTaskID == taskID {
                    self.isParsing = false
                }
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
        // Validate before starting
        if let validationError = validateBeforeGeneration() {
            TickerHaptics.error()
            errorMessage = validationError.errorDescription
            showingError = true
            return
        }

        // Set loading states
        isSaving = true
        isGenerating = true
        isGeneratingConfig = false
        isCreatingTicker = false
        isSchedulingAlarm = false
        errorMessage = nil
        showingError = false
        
        defer {
            isSaving = false
            isGenerating = false
            isGeneratingConfig = false
            isCreatingTicker = false
            isSchedulingAlarm = false
        }

        // Track generation started
        AnalyticsEvents.aiGenerationStarted(inputTextLength: inputText.count).track()
        let startTime = Date()

        do {
            // Reuse parsed configuration if available, otherwise generate new one
            let configuration: TickerConfiguration
            if let existingConfig = parsedConfiguration {
                // Use existing parsed configuration to avoid redundant API call
                configuration = existingConfig
            } else {
                // Generate new configuration if we don't have one
                isGeneratingConfig = true
                let llkConfig = try await openAIService.generateTickerConfig(from: inputText)
                configuration = try llkConfig.toTickerConfiguration()
                isGeneratingConfig = false
                
                // Update parsed configuration for future use
                parsedConfiguration = configuration
            }

            let generationTime = Int(Date().timeIntervalSince(startTime) * 1000)

            // Update view models one final time with the complete configuration
            updateViewModelsFromParsedConfig()

            // Create ticker from view models (allowing for user edits)
            isCreatingTicker = true
            let ticker = try createTickerFromViewModels()
            isCreatingTicker = false

            let scheduleTypeString = ticker.schedule?.displaySummary ?? "unknown"
            let hasCountdown = ticker.countdown != nil

            // Save the ticker
            modelContext.insert(ticker)
            try modelContext.save()

            // Schedule the alarm
            isSchedulingAlarm = true
            try await tickerService.scheduleAlarm(from: ticker, context: modelContext)
            isSchedulingAlarm = false

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
            
            // Provide user-friendly error messages
            if let tickerError = error as? TickerServiceError {
                switch tickerError {
                case .notAuthorized:
                    errorMessage = "Please enable alarm permissions in Settings to create tickers."
                case .invalidConfiguration:
                    errorMessage = "The ticker configuration is invalid. Please try again."
                case .schedulingFailed:
                    errorMessage = "Failed to schedule the alarm. Please try again."
                default:
                    errorMessage = "An error occurred while creating your ticker. Please try again."
                }
            } else {
                errorMessage = error.localizedDescription.isEmpty 
                    ? "An error occurred while creating your ticker. Please try again."
                    : error.localizedDescription
            }
            
            showingError = true
        }
    }

    // MARK: - Ticker Creation
    private func createTickerFromViewModels() throws -> Ticker {
    
        let parser = TickerConfigurationParser()

        // Build configuration from view models
        let configuration = TickerConfiguration(
            label: labelViewModel.labelText.isEmpty ? "Alarm" : labelViewModel.labelText,
            time: TimeOfDay(
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
