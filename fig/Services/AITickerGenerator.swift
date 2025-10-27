//
//  AITickerGenerator.swift
//  fig
//
//  AI-powered ticker generation using Apple Intelligence Foundation Models
//

import Foundation
import FoundationModels
import NaturalLanguage
import SwiftUI


// MARK: - AI Ticker Generator

#if DEBUG
// MARK: - Debug Event Model (Debug builds only)

struct AIDebugEvent: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let type: EventType
    let message: String
    let metadata: [String: String]

    enum EventType: String {
        case info = "ℹ️"
        case success = "✅"
        case warning = "⚠️"
        case error = "❌"
        case timing = "⏱️"
        case parsing = "🔍"
        case streaming = "🔄"
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}
#endif

@MainActor
class AITickerGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var parsedConfiguration: TickerConfiguration?
    @Published var isFoundationModelsAvailable = false
    @Published var isParsing = false

    #if DEBUG
    // Debug events for testing (only in Debug/Development builds)
    @Published var debugEvents: [AIDebugEvent] = []
    var isDebugMode = false
    #endif

    private let configurationParser = TickerConfigurationParser()
    private var parsingTask: Task<Void, Never>?
    private var languageModelSession: LanguageModelSession?
    private var lastStreamUpdate: Date = .distantPast
    private let streamThrottleInterval: TimeInterval = 0.1 // Throttle UI updates to 100ms

    // Performance tracking
    private var generationStartTime: Date?
    private var sessionPrewarmed = false

    // Token limit for context window (on-device model has 4096 token limit)
    private let maxInputTokens = 1000 // Conservative estimate leaving room for schema and response

    enum RepeatOption: Equatable {
        case oneTime
        case daily
        case weekdays([TickerSchedule.Weekday])
        case hourly(interval: Int, startTime: Date, endTime: Date?)
        case every(interval: Int, unit: TickerSchedule.TimeUnit, startTime: Date, endTime: Date?)
        case biweekly([TickerSchedule.Weekday])
        case monthly(day: TickerSchedule.MonthlyDay)
        case yearly(month: Int, day: Int)
    }

    init() {
        // Don't initialize session in init - do it when view appears for better lifecycle management
    }

    // MARK: - Debug Logging

    #if DEBUG
    private func logDebug(_ type: AIDebugEvent.EventType, _ message: String, metadata: [String: String] = [:]) {
        guard isDebugMode else { return }
        let event = AIDebugEvent(timestamp: Date(), type: type, message: message, metadata: metadata)
        debugEvents.append(event)
        // Keep only last 100 events to avoid memory issues
        if debugEvents.count > 100 {
            debugEvents.removeFirst(debugEvents.count - 100)
        }
    }

    func clearDebugEvents() {
        debugEvents.removeAll()
    }
    #endif

    // MARK: - Session Lifecycle

    /// Call this when the view appears to initialize and prewarm the session
    func prepareSession() async {
        guard languageModelSession == nil else { return }
        #if DEBUG
        logDebug(.info, "Preparing session...")
        #endif
        await checkAvailabilityAndInitialize()
    }

    /// Call this when view disappears or is done
    func cleanupSession() {
        parsingTask?.cancel()
        // Note: LanguageModelSession doesn't require explicit cleanup
        // but we can nil it out to free memory
        languageModelSession = nil
        sessionPrewarmed = false
        #if DEBUG
        logDebug(.info, "Session cleaned up")
        #endif
    }

    private func checkAvailabilityAndInitialize() async {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            isFoundationModelsAvailable = true
            #if DEBUG
            logDebug(.success, "Foundation Models available")
            #endif

            // Create session with custom instructions for ticker parsing
            // Including a full example helps reduce token usage by allowing includeSchemaInPrompt: false
            languageModelSession = LanguageModelSession(
                model: model,
                instructions: {
                    """
                    You are an intelligent assistant that helps users create alarm reminders (called "Tickers") from natural language descriptions.

                    Your task is to extract structured information from user input including:
                    - Activity label (what they want to be reminded about) - REQUIRED
                    - Time (when the reminder should trigger in 24-hour format) - REQUIRED
                    - Date (which day - optional, omit if not specified by user)
                    - Repeat pattern: "oneTime", "daily", "weekdays", or "specificDays" - REQUIRED
                    - For specificDays: provide weekday names like "Monday,Wednesday,Friday" - OPTIONAL, only for specificDays pattern
                    - Countdown duration if they mention it (in hours and minutes) - OPTIONAL
                    - Appropriate SF Symbol icon that matches the activity - REQUIRED
                    - Hex color code that fits the activity theme (without # prefix) - REQUIRED

                    Be intelligent about inferring context:
                    - "Wake up at 7am every weekday" → weekdays pattern, no date needed
                    - "Gym on Monday Wednesday Friday" → specificDays with "Monday,Wednesday,Friday"
                    - "Take medicine at 9am and 9pm daily" → daily pattern
                    - "Meeting next Tuesday at 2:30pm" → oneTime, include specific date

                    Choose icons wisely:
                    - Wake up → "sunrise.fill"
                    - Medication → "pills.fill"
                    - Exercise/Gym → "dumbbell.fill"
                    - Meetings → "person.2.fill"
                    - Food/Meals → "fork.knife"
                    - Sleep → "moon.stars.fill"
                    - Study → "book.fill"
                    - Water → "drop.fill"

                    Choose colors that match the activity mood and time of day:
                    - Morning activities → warm colors (FDB813, FF9F1C)
                    - Evening → cool colors (4A5899, 2D3561)
                    - Health → greens/blues (4ECDC4, 52B788)
                    - Important → reds/oranges (FF6B6B, E63946)

                    Example input: "Wake up at 7am every weekday"
                    Example output: {
                        "label": "Wake Up",
                        "hour": 7,
                        "minute": 0,
                        "repeatPattern": "weekdays",
                        "icon": "sunrise.fill",
                        "colorHex": "FF9F1C"
                    }

                    Example input: "Take medication at 9am and 9pm daily with 1 hour countdown"
                    Example output: {
                        "label": "Take Medication",
                        "hour": 9,
                        "minute": 0,
                        "repeatPattern": "daily",
                        "countdownHours": 1,
                        "countdownMinutes": 0,
                        "icon": "pills.fill",
                        "colorHex": "4ECDC4"
                    }
                    """
                }
            )

            // Prewarm the session with the instruction prefix for better first-response performance
            // This loads the model ahead of time instead of when first request is made
            if !sessionPrewarmed {
                #if DEBUG
                logDebug(.info, "Prewarming session...")
                #endif
                let prewarmPrefix = "Parse this ticker request and extract all relevant information:"
                try? await languageModelSession?.prewarm(promptPrefix: Prompt(prewarmPrefix))
                sessionPrewarmed = true
                #if DEBUG
                logDebug(.success, "Session prewarmed successfully")
                #endif
                print("✅ AITickerGenerator: Session prewarmed successfully")
            }

        case .unavailable(let reason):
            isFoundationModelsAvailable = false
            #if DEBUG
            logDebug(.warning, "Foundation Models unavailable", metadata: ["reason": "reason"])
            #endif
            print("⚠️ AITickerGenerator: Foundation Models unavailable - \(reason)")
        }
    }

    // Convert AI response to TickerConfiguration
    private func convertToTickerConfiguration(_ response: AITickerConfigurationResponse) -> TickerConfiguration {
        let calendar = Calendar.current
        let now = Date()

        // Use provided date components or default to today
        var dateComponents = DateComponents()
        dateComponents.year = response.year ?? calendar.component(.year, from: now)
        dateComponents.month = response.month ?? calendar.component(.month, from: now)
        dateComponents.day = response.day ?? calendar.component(.day, from: now)
        let date = calendar.date(from: dateComponents) ?? now

        // Parse repeat pattern
        let repeatOption: AITickerGenerator.RepeatOption
        switch response.repeatPattern {
        case "daily":
            repeatOption = .daily
        case "weekdays":
            repeatOption = .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday])
        case "specificDays":
            // Only parse repeatDays if provided
            if let repeatDaysString = response.repeatDays, !repeatDaysString.isEmpty {
                let weekdayNames = repeatDaysString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let weekdays = weekdayNames.compactMap { name -> TickerSchedule.Weekday? in
                    switch name.lowercased() {
                    case "monday": return .monday
                    case "tuesday": return .tuesday
                    case "wednesday": return .wednesday
                    case "thursday": return .thursday
                    case "friday": return .friday
                    case "saturday": return .saturday
                    case "sunday": return .sunday
                    default: return nil
                    }
                }
                repeatOption = weekdays.isEmpty ? .oneTime : .weekdays(weekdays)
            } else {
                repeatOption = .oneTime
            }
        default:
            repeatOption = .oneTime
        }

        // Parse countdown - use provided values or default to 0
        let countdownHours = response.countdownHours ?? 0
        let countdownMinutes = response.countdownMinutes ?? 0
        let countdown: TickerConfiguration.CountdownConfiguration?
        if countdownHours > 0 || countdownMinutes > 0 {
            countdown = TickerConfiguration.CountdownConfiguration(
                hours: countdownHours,
                minutes: countdownMinutes,
                seconds: 0
            )
        } else {
            countdown = nil
        }

        return TickerConfiguration(
            label: response.label,
            time: TickerConfiguration.TimeOfDay(hour: response.hour, minute: response.minute),
            date: date,
            repeatOption: repeatOption,
            countdown: countdown,
            icon: response.icon,
            colorHex: response.colorHex
        )
    }
    
    /// Estimates token count for input (rough approximation: ~4 characters per token)
    private func estimateTokenCount(for text: String) -> Int {
        return text.count / 4
    }

    /// Truncates input if it exceeds token limits while preserving meaning
    private func truncateIfNeeded(_ input: String) -> String {
        let estimatedTokens = estimateTokenCount(for: input)
        guard estimatedTokens > maxInputTokens else { return input }

        // Truncate to approximate character limit
        let maxChars = maxInputTokens * 4
        let truncated = String(input.prefix(maxChars))
        print("⚠️ AITickerGenerator: Input truncated from \(input.count) to \(truncated.count) chars (est. \(estimatedTokens) → \(estimateTokenCount(for: truncated)) tokens)")
        return truncated
    }

    func parseInBackground(from input: String) {
        // Cancel any existing parsing task
        parsingTask?.cancel()

        // Clear previous results
        parsedConfiguration = nil

        // Don't parse empty or very short inputs
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedInput.count > 3 else {
            isParsing = false
            return
        }

        // Validate and truncate input if needed to stay within context window
        let validatedInput = truncateIfNeeded(trimmedInput)

        // Set parsing state
        isParsing = true
        let tokenCount = estimateTokenCount(for: validatedInput)
        #if DEBUG
        logDebug(.parsing, "Starting parse", metadata: [
            "input": "\"\(validatedInput)\"",
            "length": "\(validatedInput.count) chars",
            "tokens": "~\(tokenCount)"
        ])
        #endif
        print("🔍 AITickerGenerator: Starting parse for input (est. \(tokenCount) tokens)")

        parsingTask = Task.detached(priority: .userInitiated) {
            do {
                // Add a small delay to debounce rapid typing
                try await Task.sleep(for: .milliseconds(500))

                // Check if task was cancelled
                guard !Task.isCancelled else {
                    await MainActor.run {
                        self.isParsing = false
                    }
                    return
                }

                // Try Foundation Models first, fallback to regex parsing
                await MainActor.run {
                    print("🔍 AITickerGenerator: isFoundationModelsAvailable = \(self.isFoundationModelsAvailable)")
                    if self.isFoundationModelsAvailable, let session = self.languageModelSession {
                        // Use streaming for real-time feedback with validated input
                        print("🔍 AITickerGenerator: Using Foundation Models streaming")
                        Task {
                            await self.parseWithFoundationModelsStreaming(input: validatedInput, session: session)
                            await MainActor.run {
                                self.isParsing = false
                                print("🔍 AITickerGenerator: Foundation Models parsing complete")
                            }
                        }
                    } else {
                        // Fallback to regex-based parsing with validated input
                        print("🔍 AITickerGenerator: Using regex parsing fallback")
                        Task.detached(priority: .userInitiated) {
                            do {
                                let configuration = try await self.configurationParser.parseConfiguration(from: validatedInput)
                                await MainActor.run {
                                    self.parsedConfiguration = configuration
                                    self.isParsing = false
                                    print("🔍 AITickerGenerator: Regex parsing complete - config: \(configuration.label)")
                                }
                            } catch {
                                await MainActor.run {
                                    self.parsedConfiguration = nil
                                    self.isParsing = false
                                    print("🔍 AITickerGenerator: Regex parsing failed: \(error)")
                                }
                            }
                        }
                    }
                }
            } catch {
                // Silently fail for background parsing - don't show errors to user
                await MainActor.run {
                    self.parsedConfiguration = nil
                    self.isParsing = false
                }
            }
        }
    }

    /// Parses user input using Foundation Models with streaming for real-time UI updates
    /// - Parameters:
    ///   - input: The natural language input to parse
    ///   - session: The active LanguageModelSession
    /// - Note: Updates UI progressively as fields become available during streaming
    ///         Uses throttling (100ms) to prevent excessive updates and maintain performance
    private func parseWithFoundationModelsStreaming(input: String, session: LanguageModelSession) async {
        guard !session.isResponding else { return }

        // Start performance tracking
        let streamStartTime = Date()

        do {
            let options = GenerationOptions(
                sampling: .greedy, // Deterministic output
                temperature: 0.3,  // Low temperature for consistent parsing
                maximumResponseTokens: 500
            )

            // Note: includeSchemaInPrompt is false because we provided examples in instructions
            // This saves tokens and reduces latency on each request
            let stream = try await session.streamResponse(
                to: Prompt("""
                    Parse this ticker request and extract all relevant information:
                    "\(input)"

                    Provide a complete ticker configuration with label, time, repeat pattern, icon, and color.
                    ONLY include date (year/month/day) if explicitly mentioned.
                    ONLY include countdown if explicitly mentioned.
                    ONLY include repeatDays if using specificDays pattern.
                    """),
                generating: AITickerConfigurationResponse.self,
                includeSchemaInPrompt: false, // Schema already in examples, saves ~200 tokens per request
                options: options
            )

            var updateCount = 0
            for try await snapshot in stream {
                // Access the partial content from the snapshot
                let partial = snapshot.content

                // Throttle UI updates to avoid overwhelming the main thread
                // Only update if enough time has passed since last update
                let now = Date()
                let timeSinceLastUpdate = now.timeIntervalSince(lastStreamUpdate)

                // PROGRESSIVE UPDATES: Update UI as fields become available
                // Check if we have at least some meaningful partial data
                let hasPartialData = partial.label != nil ||
                                    partial.hour != nil ||
                                    partial.icon != nil ||
                                    partial.repeatPattern != nil

                // Update UI when we have partial data AND throttle interval has passed
                if hasPartialData && timeSinceLastUpdate >= streamThrottleInterval {
                    // Track which fields are available for progressive updates
                    let availableFields = [
                        partial.label != nil ? "label" : nil,
                        partial.hour != nil ? "hour" : nil,
                        partial.minute != nil ? "minute" : nil,
                        partial.repeatPattern != nil ? "repeat" : nil,
                        partial.icon != nil ? "icon" : nil,
                        partial.colorHex != nil ? "color" : nil
                    ].compactMap { $0 }

                    // Build detailed metadata with actual values
                    var metadata: [String: String] = [
                        "fields": availableFields.joined(separator: ", ")
                    ]

                    // Add actual parsed values for debugging
                    if let label = partial.label {
                        metadata["label"] = "\"\(label)\""
                    }
                    if let hour = partial.hour {
                        metadata["hour"] = "\(hour)"
                    }
                    if let minute = partial.minute {
                        metadata["minute"] = "\(minute)"
                    }
                    if let repeatPattern = partial.repeatPattern {
                        metadata["repeat"] = repeatPattern
                    }
                    if let repeatDays = partial.repeatDays, !repeatDays.isEmpty {
                        metadata["repeatDays"] = repeatDays
                    }
                    if let icon = partial.icon {
                        metadata["icon"] = icon
                    }
                    if let colorHex = partial.colorHex {
                        metadata["color"] = "#\(colorHex)"
                    }
                    if let countdownHours = partial.countdownHours {
                        metadata["countdownH"] = "\(countdownHours)h"
                    }
                    if let countdownMinutes = partial.countdownMinutes {
                        metadata["countdownM"] = "\(countdownMinutes)m"
                    }
                    if let year = partial.year {
                        metadata["year"] = "\(year)"
                    }
                    if let month = partial.month {
                        metadata["month"] = "\(month)"
                    }
                    if let day = partial.day {
                        metadata["day"] = "\(day)"
                    }

                    let fieldsStr = availableFields.joined(separator: ", ")
                    #if DEBUG
                    await MainActor.run {
                        self.logDebug(.streaming, "Progressive update #\(updateCount + 1)", metadata: metadata)
                    }
                    #endif
                    print("🔄 AITickerGenerator: Progressive update #\(updateCount + 1) with fields: \(fieldsStr)")

                    // Create response with available fields + defaults for missing ones
                    let response = AITickerConfigurationResponse(
                        label: partial.label ?? "Alarm",  // Default label
                        hour: partial.hour ?? 12,  // Default to noon
                        minute: partial.minute ?? 0,  // Default to :00
                        year: partial.year,
                        month: partial.month,
                        day: partial.day,
                        repeatPattern: partial.repeatPattern ?? "oneTime",  // Default to one-time
                        repeatDays: partial.repeatDays,
                        countdownHours: partial.countdownHours,
                        countdownMinutes: partial.countdownMinutes,
                        icon: partial.icon ?? "bell.fill",  // Default icon
                        colorHex: partial.colorHex ?? "4ECDC4"  // Default teal color
                    )

                    parsedConfiguration = convertToTickerConfiguration(response)
                    lastStreamUpdate = now
                    updateCount += 1
                }
            }

            // Performance logging
            let streamDuration = Date().timeIntervalSince(streamStartTime)
            #if DEBUG
            logDebug(.timing, "Streaming completed", metadata: [
                "duration": String(format: "%.2f", streamDuration),
                "updates": "\(updateCount)"
            ])
            #endif
            print("✅ AITickerGenerator: Streaming completed in \(String(format: "%.2f", streamDuration))s with \(updateCount) UI updates")

        } catch {
            #if DEBUG
            logDebug(.error, "Streaming error", metadata: ["error": error.localizedDescription])
            #endif
            print("❌ AITickerGenerator: Streaming error - \(error)")
            // Fallback to regex parsing on background thread
            Task.detached(priority: .userInitiated) {
                if let configuration = try? await self.configurationParser.parseConfiguration(from: input) {
                    await MainActor.run {
                        self.parsedConfiguration = configuration
                        print("✅ AITickerGenerator: Fallback regex parsing succeeded")
                    }
                }
            }
        }
    }

    func generateTickerConfiguration(from input: String) async throws -> TickerConfiguration {
        isGenerating = true
        errorMessage = nil
        generationStartTime = Date()
        defer {
            isGenerating = false
            if let startTime = generationStartTime {
                let duration = Date().timeIntervalSince(startTime)
                print("⏱️ AITickerGenerator: Total generation time: \(String(format: "%.2f", duration))s")
            }
        }

        // Validate and truncate input to stay within context window
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            throw AITickerGenerationError.invalidInput
        }

        let validatedInput = truncateIfNeeded(trimmedInput)

        // Try Foundation Models first, fallback to regex parsing
        let configuration: TickerConfiguration

        if isFoundationModelsAvailable, let session = languageModelSession {
            print("🤖 AITickerGenerator: Generating with Foundation Models")
            configuration = try await parseWithFoundationModels(input: validatedInput, session: session)
        } else {
            print("🔧 AITickerGenerator: Generating with regex fallback")
            // Fallback to regex-based parsing
            configuration = try await configurationParser.parseConfiguration(from: validatedInput)
        }

        // Additional validation
        if configuration.label.isEmpty {
            throw AITickerGenerationError.parsingFailed
        }

        // Log final configuration with all values
        var finalMetadata: [String: String] = [
            "label": "\"\(configuration.label)\"",
            "time": String(format: "%02d:%02d", configuration.time.hour, configuration.time.minute),
            "icon": configuration.icon,
            "color": "#\(configuration.colorHex)"
        ]

        // Add repeat option
        switch configuration.repeatOption {
        case .oneTime:
            finalMetadata["repeat"] = "oneTime"
        case .daily:
            finalMetadata["repeat"] = "daily"
        case .weekdays(let days):
            finalMetadata["repeat"] = "weekdays(\(days.count))"
        case .hourly(let interval, _, _):
            finalMetadata["repeat"] = "hourly(\(interval))"
        case .every(let interval, let unit, _, _):
            finalMetadata["repeat"] = "every(\(interval) \(unit))"
        case .biweekly(let days):
            finalMetadata["repeat"] = "biweekly(\(days.count))"
        case .monthly(let day):
            finalMetadata["repeat"] = "monthly"
        case .yearly(let month, let day):
            finalMetadata["repeat"] = "yearly(\(month)/\(day))"
        }

        // Add countdown if present
        if let countdown = configuration.countdown {
            finalMetadata["countdown"] = "\(countdown.hours)h \(countdown.minutes)m"
        }

        #if DEBUG
        logDebug(.success, "Configuration generated", metadata: finalMetadata)
        #endif
        print("✅ AITickerGenerator: Configuration generated - \(configuration.label)")
        return configuration
    }

    private func parseWithFoundationModels(input: String, session: LanguageModelSession) async throws -> TickerConfiguration {
        guard !session.isResponding else {
            throw AITickerGenerationError.parsingFailed
        }

        let methodStartTime = Date()

        let options = GenerationOptions(
            sampling: .greedy, // Deterministic output for final generation
            temperature: 0.3,
            maximumResponseTokens: 500
        )

        // Note: includeSchemaInPrompt is false because we provided examples in instructions
        // This reduces tokens sent with each request, improving latency
        let result = try await session.respond(
            to: Prompt("""
                Parse this ticker/alarm request and extract all information:
                "\(input)"
                """),
            generating: AITickerConfigurationResponse.self,
            includeSchemaInPrompt: false, // Schema already in examples, saves ~200 tokens
            options: options
        )

        let methodDuration = Date().timeIntervalSince(methodStartTime)
        print("⏱️ AITickerGenerator: Model inference completed in \(String(format: "%.2f", methodDuration))s")

        return convertToTickerConfiguration(result.content)
    }
}

enum AITickerGenerationError: LocalizedError {
    case invalidInput
    case parsingFailed
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
            case .invalidInput:
                return "Please provide a clearer description of your ticker"
            case .parsingFailed:
                return "Unable to understand your request. Try being more specific about the time and activity."
            case .unsupportedFormat:
                return "This format is not supported yet. Please try a simpler description."
        }
    }
}
