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

// MARK: - Ticker Configuration (Simple Types for Foundation Models)

struct TickerConfiguration: Equatable {
    let label: String
    let time: TimeOfDay
    let date: Date
    let repeatOption: AITickerGenerator.RepeatOption
    let countdown: CountdownConfiguration?
    let icon: String
    let colorHex: String

    struct TimeOfDay: Equatable {
        let hour: Int
        let minute: Int
    }

    struct CountdownConfiguration: Equatable {
        let hours: Int
        let minutes: Int
        let seconds: Int
    }
}

// Foundation Models compatible configuration using only simple types
@Generable
struct AITickerConfigurationResponse: Equatable {
    @Guide(description: "A short, descriptive label for the activity or reminder (e.g., 'Morning Yoga', 'Take Medication', 'Team Meeting')")
    let label: String

    @Guide(description: "Hour in 24-hour format (0-23)")
    let hour: Int

    @Guide(description: "Minute (0-59)")
    let minute: Int

    @Guide(description: "Year (e.g., 2025). If not specified in the user's request, use the current year.")
    let year: Int?

    @Guide(description: "Month (1-12). If not specified in the user's request, use the current month.")
    let month: Int?

    @Guide(description: "Day of month (1-31). If not specified in the user's request, use today's day.")
    let day: Int?

    @Guide(.anyOf(["oneTime", "daily", "weekdays", "specificDays"]))
    let repeatPattern: String

    @Guide(description: "For specificDays pattern only: comma-separated weekday names (e.g., 'Monday,Wednesday,Friday'). Leave empty or omit for other patterns.")
    let repeatDays: String?

    @Guide(description: "Number of hours for countdown before alarm (0-23). Omit or use 0 if no countdown mentioned.")
    let countdownHours: Int?

    @Guide(description: "Number of minutes for countdown before alarm (0-59). Omit or use 0 if no countdown mentioned.")
    let countdownMinutes: Int?

    @Guide(description: "SF Symbol icon name that represents the activity (e.g., 'sunrise.fill', 'pills.fill', 'person.2.fill', 'dumbbell.fill')")
    let icon: String

    @Guide(description: "Hex color code for the ticker without # prefix (e.g., 'FF6B6B' for red, '4ECDC4' for teal)")
    let colorHex: String
}



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

    private let activityMapper = ActivityIconMapper()
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
                                let configuration = try await self.parseConfigurationWithRegex(from: validatedInput)
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
                if let configuration = try? await self.parseConfigurationWithRegex(from: input) {
                    await MainActor.run {
                        self.parsedConfiguration = configuration
                        print("✅ AITickerGenerator: Fallback regex parsing succeeded")
                    }
                }
            }
        }
    }
    
    private func parseConfigurationWithRegex(from input: String) async throws -> TickerConfiguration {
        // Use Natural Language framework for text analysis
        // Note: Already running off main thread via Task.detached in parseInBackground
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = input
        
        // Extract entities and parse the input
        let entities = extractEntities(from: input, using: tagger)
        let timeInfo = parseTime(from: input, entities: entities)
        let dateInfo = parseDate(from: input, entities: entities)
        let repeatInfo = parseRepeatPattern(from: input, entities: entities, defaultDate: dateInfo)
        let countdownInfo = parseCountdown(from: input)
        let activityInfo = parseActivity(from: input, entities: entities)
        
        // Generate configuration
        let configuration = TickerConfiguration(
            label: activityInfo.label,
            time: timeInfo,
            date: dateInfo,
            repeatOption: repeatInfo,
            countdown: countdownInfo,
            icon: activityInfo.icon,
            colorHex: activityInfo.colorHex
        )
        
        return configuration
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
            configuration = try await parseConfigurationWithRegex(from: validatedInput)
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

                Create a complete ticker configuration. Infer reasonable defaults where information is missing.
                For time: use 24-hour format. If no time specified, suggest an appropriate time based on the activity.
                For date: ONLY provide year, month, and day if explicitly mentioned. Otherwise omit these fields.
                For repeatPattern: use "oneTime", "daily", "weekdays", or "specificDays"
                For specificDays: provide comma-separated weekday names in repeatDays (e.g., "Monday,Wednesday,Friday"). Omit for other patterns.
                For countdown: ONLY provide if explicitly mentioned. Otherwise omit these fields.
                For icon: choose an appropriate SF Symbol that matches the activity.
                For color: choose a hex color that fits the activity and time of day (without # prefix).
                """),
            generating: AITickerConfigurationResponse.self,
            includeSchemaInPrompt: false, // Schema already in examples, saves ~200 tokens
            options: options
        )

        let methodDuration = Date().timeIntervalSince(methodStartTime)
        print("⏱️ AITickerGenerator: Model inference completed in \(String(format: "%.2f", methodDuration))s")

        return convertToTickerConfiguration(result.content)
    }
    
    // MARK: - Private Parsing Methods
    
    private func extractEntities(from input: String, using tagger: NLTagger) -> [String: [String]] {
        var entities: [String: [String]] = [:]
        
        // Extract named entities
        tagger.enumerateTags(in: input.startIndex..<input.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag {
                let entity = String(input[range])
                if entities[tag.rawValue] == nil {
                    entities[tag.rawValue] = []
                }
                entities[tag.rawValue]?.append(entity)
            }
            return true
        }
        
        // Extract lexical classes for better context understanding
        tagger.enumerateTags(in: input.startIndex..<input.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag {
                let word = String(input[range])
                if entities[tag.rawValue] == nil {
                    entities[tag.rawValue] = []
                }
                entities[tag.rawValue]?.append(word)
            }
            return true
        }
        
        return entities
    }
    
    private func parseTime(from input: String, entities: [String: [String]]) -> TickerConfiguration.TimeOfDay {
        let lowercaseInput = input.lowercased()
        
        // First, try to parse natural language time expressions
        if let naturalTime = parseNaturalTimeExpressions(from: lowercaseInput) {
            return naturalTime
        }
        
        // Use NSDateFormatter for time parsing
        if let time = parseTimeWithDateFormatter(input) {
            return time
        }
        
        // Try to extract time from entities if available
        if let timeFromEntities = extractTimeFromEntities(entities) {
            return timeFromEntities
        }
        
        // Default to current time + 1 hour
        let calendar = Calendar.current
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        let components = calendar.dateComponents([.hour, .minute], from: nextHour)
        
        return TickerConfiguration.TimeOfDay(
            hour: components.hour ?? 12,
            minute: components.minute ?? 0
        )
    }
    
    private func parseNaturalTimeExpressions(from input: String) -> TickerConfiguration.TimeOfDay? {
        let naturalTimeMap: [String: (hour: Int, minute: Int)] = [
            "midnight": (0, 0),
            "noon": (12, 0),
            "midday": (12, 0),
            "dawn": (6, 0),
            "sunrise": (6, 30),
            "morning": (8, 0),
            "late morning": (10, 0),
            "lunchtime": (12, 0),
            "afternoon": (14, 0),
            "late afternoon": (16, 0),
            "evening": (18, 0),
            "dusk": (19, 0),
            "sunset": (19, 30),
            "night": (20, 0),
            "late night": (22, 0)
        ]
        
        for (expression, time) in naturalTimeMap {
            if input.contains(expression) {
                return TickerConfiguration.TimeOfDay(hour: time.hour, minute: time.minute)
            }
        }
        
        return nil
    }
    
    private func parseTimeWithDateFormatter(_ input: String) -> TickerConfiguration.TimeOfDay? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try different time formats
        let timeFormats = [
            "h:mm a",      // 12:30 PM
            "h:mm a",      // 1:30 PM
            "h a",         // 1 PM
            "h:mm",        // 12:30
            "h",           // 1
            "HH:mm",       // 13:30
            "HH"           // 13
        ]
        
        for format in timeFormats {
            formatter.dateFormat = format
            
            // Try to find time in the input string
            let inputWords = input.components(separatedBy: .whitespacesAndNewlines)
            for word in inputWords {
                if let date = formatter.date(from: word) {
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.hour, .minute], from: date)
                    
                    if let hour = components.hour, let minute = components.minute {
                        // Validate time
                        guard hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 else {
                            continue
                        }
                        
                        return TickerConfiguration.TimeOfDay(hour: hour, minute: minute)
                    }
                }
            }
        }
        
        // Try parsing with relative time expressions
        return parseRelativeTimeExpressions(from: input)
    }
    
    private func parseRelativeTimeExpressions(from input: String) -> TickerConfiguration.TimeOfDay? {
        let lowercaseInput = input.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        // Parse expressions like "in 2 hours", "in 30 minutes"
        let timePatterns = [
            ("in (\\d+) hours?", { hours in
                let futureDate = calendar.date(byAdding: .hour, value: hours, to: now) ?? now
                let components = calendar.dateComponents([.hour, .minute], from: futureDate)
                return TickerConfiguration.TimeOfDay(hour: components.hour ?? 0, minute: components.minute ?? 0)
            }),
            ("in (\\d+) minutes?", { minutes in
                let futureDate = calendar.date(byAdding: .minute, value: minutes, to: now) ?? now
                let components = calendar.dateComponents([.hour, .minute], from: futureDate)
                return TickerConfiguration.TimeOfDay(hour: components.hour ?? 0, minute: components.minute ?? 0)
            })
        ]
        
        for (pattern, handler) in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: input.utf16.count)
                if let match = regex.firstMatch(in: input, options: [], range: range) {
                    let numberRange = match.range(at: 1)
                    if let numberString = Range(numberRange, in: input).map({ String(input[$0]) }),
                       let number = Int(numberString) {
                        return handler(number)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractTimeFromEntities(_ entities: [String: [String]]) -> TickerConfiguration.TimeOfDay? {
        // Look for time-related entities in the extracted data
        // This is a fallback method when regex patterns don't match
        
        // Check for numbers that might be times
        if let numbers = entities["Number"] {
            for number in numbers {
                if let num = Int(number) {
                    // If it's a reasonable hour (1-12), assume it's a time
                    if num >= 1 && num <= 12 {
                        return TickerConfiguration.TimeOfDay(hour: num, minute: 0)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseDate(from input: String, entities: [String: [String]]) -> Date {
        let lowercaseInput = input.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        // Check for relative dates with more comprehensive patterns
        if lowercaseInput.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        } else if lowercaseInput.contains("today") {
            return now
        } else if lowercaseInput.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        } else if lowercaseInput.contains("next month") {
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        } else if lowercaseInput.contains("next year") {
            return calendar.date(byAdding: .year, value: 1, to: now) ?? now
        }
        
        // Check for specific weekdays with "next" prefix
        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for (index, weekday) in weekdays.enumerated() {
            if lowercaseInput.contains(weekday) {
                let weekdayComponent = (index + 1) % 7 // Convert to Calendar weekday (1=Sunday)
                let isNextWeek = lowercaseInput.contains("next \(weekday)")
                
                let components = calendar.dateComponents([.year, .weekOfYear], from: now)
                var targetComponents = DateComponents()
                targetComponents.year = components.year
                targetComponents.weekOfYear = components.weekOfYear
                targetComponents.weekday = weekdayComponent
                
                if let targetDate = calendar.date(from: targetComponents) {
                    // If the date is in the past or it's explicitly "next [weekday]", move to next week
                    if targetDate < now || isNextWeek {
                        return calendar.date(byAdding: .weekOfYear, value: 1, to: targetDate) ?? targetDate
                    }
                    return targetDate
                }
            }
        }
        
        // Use NSDateFormatter for date parsing
        if let parsedDate = parseDateWithDateFormatter(input) {
            return parsedDate
        }
        
        // Default to today
        return now
    }
    
    private func parseDateWithDateFormatter(_ input: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try different date formats
        let dateFormats = [
            "MMMM d",           // January 15
            "MMM d",            // Jan 15
            "MMMM d, yyyy",     // January 15, 2024
            "MMM d, yyyy",      // Jan 15, 2024
            "d MMMM",           // 15 January
            "d MMM",            // 15 Jan
            "d MMMM yyyy",      // 15 January 2024
            "d MMM yyyy",       // 15 Jan 2024
            "MM/dd",            // 01/15
            "MM/dd/yyyy",       // 01/15/2024
            "dd/MM",            // 15/01
            "dd/MM/yyyy",       // 15/01/2024
            "yyyy-MM-dd"        // 2024-01-15
        ]
        
        for format in dateFormats {
            formatter.dateFormat = format
            
            // Try to find date in the input string
            let inputWords = input.components(separatedBy: .whitespacesAndNewlines)
            for word in inputWords {
                if let date = formatter.date(from: word) {
                    // If the date is in the past, move to next year
                    let calendar = Calendar.current
                    let now = Date()
                    if date < now {
                        let components = calendar.dateComponents([.month, .day], from: date)
                        var nextYearComponents = DateComponents()
                        nextYearComponents.year = calendar.component(.year, from: now) + 1
                        nextYearComponents.month = components.month
                        nextYearComponents.day = components.day
                        return calendar.date(from: nextYearComponents) ?? date
                    }
                    return date
                }
            }
        }
        
        return nil
    }
    
    private func parseSpecificDate(from input: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Month names mapping
        let monthNames = [
            "january": 1, "jan": 1,
            "february": 2, "feb": 2,
            "march": 3, "mar": 3,
            "april": 4, "apr": 4,
            "may": 5,
            "june": 6, "jun": 6,
            "july": 7, "jul": 7,
            "august": 8, "aug": 8,
            "september": 9, "sep": 9, "sept": 9,
            "october": 10, "oct": 10,
            "november": 11, "nov": 11,
            "december": 12, "dec": 12
        ]
        
        // Try patterns like "January 15th", "Jan 15", "15th of January"
        for (monthName, monthNumber) in monthNames {
            if input.contains(monthName) {
                // Look for day number
                let dayPattern = #"(\d{1,2})(?:st|nd|rd|th)?"#
                if let regex = try? NSRegularExpression(pattern: dayPattern) {
                    let range = NSRange(location: 0, length: input.utf16.count)
                    if let match = regex.firstMatch(in: input, options: [], range: range) {
                        let dayRange = match.range(at: 1)
                        if let dayString = Range(dayRange, in: input).map({ String(input[$0]) }),
                           let day = Int(dayString) {
                            
                            let currentYear = calendar.component(.year, from: now)
                            var components = DateComponents()
                            components.year = currentYear
                            components.month = monthNumber
                            components.day = day
                            
                            if let date = calendar.date(from: components) {
                                // If the date is in the past, use next year
                                if date < now {
                                    components.year = currentYear + 1
                                    return calendar.date(from: components)
                                }
                                return date
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseRepeatPattern(from input: String, entities: [String: [String]], defaultDate: Date) -> RepeatOption {
        let lowercaseInput = input.lowercased()
        
        // Check for daily patterns with more variations
        let dailyPatterns = [
            "every day", "daily", "each day", "everyday", "every single day",
            "day after day", "all days", "every 24 hours"
        ]
        
        for pattern in dailyPatterns {
            if lowercaseInput.contains(pattern) {
                return .daily
            }
        }
        
        // Check for weekday patterns with more variations
        let weekdayPatterns = [
            "weekdays", "week days", "week day", "weekday", "workdays", "work days",
            "business days", "monday to friday", "mon to fri", "mon-fri"
        ]
        
        for pattern in weekdayPatterns {
            if lowercaseInput.contains(pattern) {
                return .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday])
            }
        }
        
        // Check for specific weekdays with better parsing
        let weekdayMap: [String: TickerSchedule.Weekday] = [
            "monday": .monday, "mon": .monday,
            "tuesday": .tuesday, "tue": .tuesday, "tues": .tuesday,
            "wednesday": .wednesday, "wed": .wednesday,
            "thursday": .thursday, "thu": .thursday, "thur": .thursday, "thurs": .thursday,
            "friday": .friday, "fri": .friday,
            "saturday": .saturday, "sat": .saturday,
            "sunday": .sunday, "sun": .sunday
        ]
        
        var selectedWeekdays: [TickerSchedule.Weekday] = []
        
        // Look for patterns like "every Monday and Wednesday", "Mondays and Wednesdays"
        for (dayName, weekday) in weekdayMap {
            let patterns = [
                "every \(dayName)", "\(dayName)s", "on \(dayName)", "\(dayName) and",
                "and \(dayName)", "\(dayName),", ", \(dayName)"
            ]
            
            for pattern in patterns {
                if lowercaseInput.contains(pattern) && !selectedWeekdays.contains(weekday) {
                    selectedWeekdays.append(weekday)
                }
            }
        }
        
        if !selectedWeekdays.isEmpty {
            return .weekdays(selectedWeekdays)
        }
        
        // Check for hourly patterns with interval parsing and time ranges
        let hourlyInterval = parseHourlyInterval(from: lowercaseInput, fullInput: input)
        if hourlyInterval > 0 {
            let (startTime, endTime) = parseTimeRange(from: lowercaseInput, input: input, defaultStart: defaultDate)
            return .hourly(interval: hourlyInterval, startTime: startTime, endTime: endTime)
        }

        // Check for "every X minutes/hours/days/weeks" patterns (more flexible than hourly)
        if let everySchedule = parseEveryPattern(from: lowercaseInput, input: input, defaultStart: defaultDate) {
            return everySchedule
        }

        // Check for biweekly patterns
        let biweeklyPatterns = [
            "biweekly", "bi-weekly", "every other week", "alternate weeks",
            "fortnightly", "every two weeks", "every 2 weeks"
        ]
        
        for pattern in biweeklyPatterns {
            if lowercaseInput.contains(pattern) {
                return .biweekly([.monday, .wednesday, .friday])
            }
        }
        
        // Check for monthly patterns with advanced day options
        if let monthlyDay = parseMonthlyPattern(from: lowercaseInput, input: input) {
            return .monthly(day: monthlyDay)
        }
        
        // Check for yearly patterns
        if lowercaseInput.contains("yearly") || lowercaseInput.contains("annually") || lowercaseInput.contains("every year") {
            return .yearly(month: 1, day: 1) // Default to January 1st
        }
        
        // Default to one time
        return .oneTime
    }
    
    // MARK: - NaturalLanguage-based Parsing Methods
    
    private func parseDailyPatternWithNL(tagger: NLTagger, input: String) -> Bool {
        let dailyKeywords = ["every day", "daily", "each day", "everyday", "every single day", "day after day", "all days", "every 24 hours"]
        
        for keyword in dailyKeywords {
            if input.contains(keyword) {
                return true
            }
        }
        
        // Use NaturalLanguage to detect frequency patterns
        var hasFrequency = false
        tagger.enumerateTags(in: input.startIndex..<input.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag, tag == .adverb {
                let word = String(input[range]).lowercased()
                if word == "daily" || word == "everyday" {
                    hasFrequency = true
                    return false // Stop enumeration
                }
            }
            return true
        }
        
        return hasFrequency
    }
    
    private func parseWeekdayPatternWithNL(tagger: NLTagger, input: String) -> [TickerSchedule.Weekday]? {
        let weekdayMap: [String: TickerSchedule.Weekday] = [
            "monday": .monday, "mon": .monday,
            "tuesday": .tuesday, "tue": .tuesday, "tues": .tuesday,
            "wednesday": .wednesday, "wed": .wednesday,
            "thursday": .thursday, "thu": .thursday, "thur": .thursday, "thurs": .thursday,
            "friday": .friday, "fri": .friday,
            "saturday": .saturday, "sat": .saturday,
            "sunday": .sunday, "sun": .sunday
        ]
        
        var selectedWeekdays: [TickerSchedule.Weekday] = []
        
        // Check for general weekday patterns first
        let weekdayPatterns = [
            "weekdays", "week days", "week day", "weekday", "workdays", "work days",
            "business days", "monday to friday", "mon to fri", "mon-fri"
        ]
        
        for pattern in weekdayPatterns {
            if input.contains(pattern) {
                return [.monday, .tuesday, .wednesday, .thursday, .friday]
            }
        }
        
        // Use NaturalLanguage to detect specific weekdays
        tagger.enumerateTags(in: input.startIndex..<input.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag, tag == .noun {
                let word = String(input[range]).lowercased()
                if let weekday = weekdayMap[word] {
                    selectedWeekdays.append(weekday)
                }
            }
            return true
        }
        
        return selectedWeekdays.isEmpty ? nil : selectedWeekdays
    }
    
    private func parseCountdown(from input: String) -> TickerConfiguration.CountdownConfiguration? {
        let lowercaseInput = input.lowercased()
        
        // Use NSMeasurement for duration parsing
        if let countdown = parseCountdownWithMeasurement(input) {
            return countdown
        }
        
        // Fallback to simple number extraction for common patterns
        return parseCountdownWithSimpleExtraction(from: lowercaseInput)
    }
    
    private func parseCountdownWithMeasurement(_ input: String) -> TickerConfiguration.CountdownConfiguration? {
        // Try "X hours and Y minutes" pattern
        if let regex = try? NSRegularExpression(pattern: #"(\d+)\s*hours?\s*(?:and\s*)?(\d+)?\s*minutes?"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                let hoursRange = match.range(at: 1)
                if let hoursString = Range(hoursRange, in: input).map({ String(input[$0]) }),
                   let hours = Int(hoursString) {
                    var minutes = 0
                    if match.numberOfRanges >= 3 {
                        let minutesRange = match.range(at: 2)
                        if minutesRange.location != NSNotFound,
                           let minutesString = Range(minutesRange, in: input).map({ String(input[$0]) }),
                           !minutesString.isEmpty {
                            minutes = Int(minutesString) ?? 0
                        }
                    }
                    return TickerConfiguration.CountdownConfiguration(hours: hours, minutes: minutes, seconds: 0)
                }
            }
        }

        // Try "X minutes and Y seconds" pattern
        if let regex = try? NSRegularExpression(pattern: #"(\d+)\s*minutes?\s*(?:and\s*)?(\d+)?\s*seconds?"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                let minutesRange = match.range(at: 1)
                if let minutesString = Range(minutesRange, in: input).map({ String(input[$0]) }),
                   let minutes = Int(minutesString) {
                    var seconds = 0
                    if match.numberOfRanges >= 3 {
                        let secondsRange = match.range(at: 2)
                        if secondsRange.location != NSNotFound,
                           let secondsString = Range(secondsRange, in: input).map({ String(input[$0]) }),
                           !secondsString.isEmpty {
                            seconds = Int(secondsString) ?? 0
                        }
                    }
                    return TickerConfiguration.CountdownConfiguration(hours: 0, minutes: minutes, seconds: seconds)
                }
            }
        }

        // Try simple "X hours" pattern
        if let regex = try? NSRegularExpression(pattern: #"(\d+)\s*hours?"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range),
               let hoursString = Range(match.range(at: 1), in: input).map({ String(input[$0]) }),
               let hours = Int(hoursString) {
                return TickerConfiguration.CountdownConfiguration(hours: hours, minutes: 0, seconds: 0)
            }
        }

        // Try simple "X minutes" pattern
        if let regex = try? NSRegularExpression(pattern: #"(\d+)\s*minutes?"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range),
               let minutesString = Range(match.range(at: 1), in: input).map({ String(input[$0]) }),
               let minutes = Int(minutesString) {
                return TickerConfiguration.CountdownConfiguration(hours: 0, minutes: minutes, seconds: 0)
            }
        }

        // Try simple "X seconds" pattern
        if let regex = try? NSRegularExpression(pattern: #"(\d+)\s*seconds?"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range),
               let secondsString = Range(match.range(at: 1), in: input).map({ String(input[$0]) }),
               let seconds = Int(secondsString) {
                return TickerConfiguration.CountdownConfiguration(hours: 0, minutes: 0, seconds: seconds)
            }
        }

        return nil
    }
    
    private func parseCountdownWithSimpleExtraction(from input: String) -> TickerConfiguration.CountdownConfiguration? {
        // Try "in X hours" pattern
        if let regex = try? NSRegularExpression(pattern: #"in (\d+) hours?"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range),
               let hoursString = Range(match.range(at: 1), in: input).map({ String(input[$0]) }),
               let hours = Int(hoursString) {
                return TickerConfiguration.CountdownConfiguration(hours: hours, minutes: 0, seconds: 0)
            }
        }

        // Try "in X minutes" pattern
        if let regex = try? NSRegularExpression(pattern: #"in (\d+) minutes?"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range),
               let minutesString = Range(match.range(at: 1), in: input).map({ String(input[$0]) }),
               let minutes = Int(minutesString) {
                return TickerConfiguration.CountdownConfiguration(hours: 0, minutes: minutes, seconds: 0)
            }
        }

        // Try "with X hour countdown" pattern
        if let regex = try? NSRegularExpression(pattern: #"with (\d+) hour countdown"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range),
               let hoursString = Range(match.range(at: 1), in: input).map({ String(input[$0]) }),
               let hours = Int(hoursString) {
                return TickerConfiguration.CountdownConfiguration(hours: hours, minutes: 0, seconds: 0)
            }
        }

        // Try "with X minute countdown" pattern
        if let regex = try? NSRegularExpression(pattern: #"with (\d+) minute countdown"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range),
               let minutesString = Range(match.range(at: 1), in: input).map({ String(input[$0]) }),
               let minutes = Int(minutesString) {
                return TickerConfiguration.CountdownConfiguration(hours: 0, minutes: minutes, seconds: 0)
            }
        }

        return nil
    }
    
    private func parseActivity(from input: String, entities: [String: [String]]) -> (label: String, icon: String, colorHex: String) {
        let activityInfo = activityMapper.mapActivity(from: input)
        return (activityInfo.label, activityInfo.icon, activityInfo.colorHex)
    }

    // MARK: - Advanced Repeat Pattern Parsing Helpers

    private func parseHourlyInterval(from lowercaseInput: String, fullInput: String) -> Int {
        // Check for simple "hourly" or "every hour"
        if lowercaseInput.contains("every hour") || lowercaseInput.contains("hourly") {
            return 1
        }

        // Parse specific hourly intervals like "every 2 hours", "every 3 hours"
        let hourlyPattern = #"every\s+(\d+)\s*hours?"#
        if let regex = try? NSRegularExpression(pattern: hourlyPattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: fullInput.utf16.count)
            if let match = regex.firstMatch(in: fullInput, options: [], range: range) {
                let intervalRange = match.range(at: 1)
                if let intervalString = Range(intervalRange, in: fullInput).map({ String(fullInput[$0]) }),
                   let interval = Int(intervalString), interval > 0 && interval <= 12 {
                    return interval
                }
            }
        }

        return 0 // Not an hourly pattern
    }

    private func parseTimeRange(from lowercaseInput: String, input: String, defaultStart: Date) -> (startTime: Date, endTime: Date?) {
        let calendar = Calendar.current

        // Parse start time with patterns like "from 9am", "starting at 8am", "begins at 10am"
        let startPatterns = [
            #"from\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#,
            #"starting\s+at\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#,
            #"begins?\s+at\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#,
            #"start\s+at\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#,
            #"from\s+(\d{1,2})\s*(am|pm)"#,
            #"starting\s+at\s+(\d{1,2})\s*(am|pm)"#
        ]

        var startTime: Date = defaultStart
        for pattern in startPatterns {
            if let time = parseTimeWithPatternForRange(input, pattern: pattern) {
                // Convert TimeOfDay to Date
                var components = calendar.dateComponents([.year, .month, .day], from: defaultStart)
                components.hour = time.hour
                components.minute = time.minute
                if let date = calendar.date(from: components) {
                    startTime = date
                    break
                }
            }
        }

        // Parse end time with patterns like "to 5pm", "until 6pm", "ending at 8pm"
        let endPatterns = [
            #"(?:to|until|till)\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#,
            #"ending\s+at\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#,
            #"end\s+at\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#,
            #"(?:to|until|till)\s+(\d{1,2})\s*(am|pm)"#
        ]

        var endTime: Date? = nil
        for pattern in endPatterns {
            if let time = parseTimeWithPatternForRange(input, pattern: pattern) {
                // Convert TimeOfDay to Date
                var components = calendar.dateComponents([.year, .month, .day], from: startTime)
                components.hour = time.hour
                components.minute = time.minute
                if let date = calendar.date(from: components) {
                    endTime = date
                    break
                }
            }
        }

        return (startTime, endTime)
    }

    private func parseTimeWithPatternForRange(_ input: String, pattern: String) -> TickerConfiguration.TimeOfDay? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(location: 0, length: input.utf16.count)
        guard let match = regex.firstMatch(in: input, options: [], range: range) else {
            return nil
        }

        var hour: Int = 0
        var minute: Int = 0
        var isPM = false
        var hasAMPM = false

        // Extract hour
        if match.numberOfRanges >= 2 {
            let hourRange = match.range(at: 1)
            if let hourString = Range(hourRange, in: input).map({ String(input[$0]) }) {
                hour = Int(hourString) ?? 0
            }
        }

        // Extract minute (if present)
        if match.numberOfRanges >= 3 {
            let minuteRange = match.range(at: 2)
            if minuteRange.location != NSNotFound,
               let minuteString = Range(minuteRange, in: input).map({ String(input[$0]) }),
               !minuteString.isEmpty {
                minute = Int(minuteString) ?? 0
            }
        }

        // Extract AM/PM
        if match.numberOfRanges >= 4 {
            let ampmRange = match.range(at: match.numberOfRanges - 1)
            if let ampmString = Range(ampmRange, in: input).map({ String(input[$0]).lowercased() }) {
                if ampmString.contains("pm") {
                    isPM = true
                    hasAMPM = true
                } else if ampmString.contains("am") {
                    isPM = false
                    hasAMPM = true
                }
            }
        }

        // Apply AM/PM conversion
        if hasAMPM {
            if isPM && hour != 12 {
                hour += 12
            } else if !isPM && hour == 12 {
                hour = 0
            }
        }

        // Validate time
        guard hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 else {
            return nil
        }

        return TickerConfiguration.TimeOfDay(hour: hour, minute: minute)
    }

    private func parseEveryPattern(from lowercaseInput: String, input: String, defaultStart: Date) -> RepeatOption? {
        // Patterns for "every X minutes/hours/days/weeks"
        let everyPatterns: [(pattern: String, unit: TickerSchedule.TimeUnit)] = [
            (#"every\s+(\d+)\s*minutes?"#, .minutes),
            (#"every\s+(\d+)\s*mins?"#, .minutes),
            (#"every\s+(\d+)\s*hours?"#, .hours),
            (#"every\s+(\d+)\s*hrs?"#, .hours),
            (#"every\s+(\d+)\s*days?"#, .days),
            (#"every\s+(\d+)\s*weeks?"#, .weeks)
        ]

        for (pattern, unit) in everyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: input.utf16.count)
                if let match = regex.firstMatch(in: input, options: [], range: range) {
                    let intervalRange = match.range(at: 1)
                    if let intervalString = Range(intervalRange, in: input).map({ String(input[$0]) }),
                       let interval = Int(intervalString), interval > 0 {

                        // Validate interval based on unit
                        let isValid = switch unit {
                        case .minutes: interval <= 60
                        case .hours: interval <= 24
                        case .days: interval <= 30
                        case .weeks: interval <= 52
                        }

                        if isValid {
                            let (startTime, endTime) = parseTimeRange(from: lowercaseInput, input: input, defaultStart: defaultStart)
                            return .every(interval: interval, unit: unit, startTime: startTime, endTime: endTime)
                        }
                    }
                }
            }
        }

        return nil
    }

    private func parseMonthlyPattern(from lowercaseInput: String, input: String) -> TickerSchedule.MonthlyDay? {
        // Check for "monthly" or "every month"
        guard lowercaseInput.contains("monthly") || lowercaseInput.contains("every month") else {
            return nil
        }

        // Check for "first of month" or "first day"
        if lowercaseInput.contains("first of month") || lowercaseInput.contains("first day of month") {
            return .firstOfMonth
        }

        // Check for "last of month" or "end of month" or "last day"
        if lowercaseInput.contains("last of month") ||
           lowercaseInput.contains("end of month") ||
           lowercaseInput.contains("last day of month") ||
           lowercaseInput.contains("month end") {
            return .lastOfMonth
        }

        // Check for "first [weekday]" patterns like "first Monday", "first Friday"
        let weekdayMap: [String: TickerSchedule.Weekday] = [
            "monday": .monday, "mon": .monday,
            "tuesday": .tuesday, "tue": .tuesday, "tues": .tuesday,
            "wednesday": .wednesday, "wed": .wednesday,
            "thursday": .thursday, "thu": .thursday, "thur": .thursday, "thurs": .thursday,
            "friday": .friday, "fri": .friday,
            "saturday": .saturday, "sat": .saturday,
            "sunday": .sunday, "sun": .sunday
        ]

        for (dayName, weekday) in weekdayMap {
            if lowercaseInput.contains("first \(dayName)") {
                return .firstWeekday(weekday)
            }
            if lowercaseInput.contains("last \(dayName)") {
                return .lastWeekday(weekday)
            }
        }

        // Check for fixed day patterns like "15th of month", "on the 15th"
        let fixedDayPatterns = [
            #"(\d{1,2})(?:st|nd|rd|th)?\s*(?:of\s*)?(?:every\s*)?month"#,
            #"monthly\s*(?:report|reminder|alarm)?\s*on\s*the\s*(\d{1,2})(?:st|nd|rd|th)?"#,
            #"on\s*the\s*(\d{1,2})(?:st|nd|rd|th)?\s*(?:of\s*)?(?:every\s*)?month"#,
            #"(\d{1,2})(?:st|nd|rd|th)?\s*(?:of\s*)?month"#,
            #"day\s+(\d{1,2})\s+of\s+(?:every\s+)?month"#
        ]

        for pattern in fixedDayPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: input.utf16.count)
                if let match = regex.firstMatch(in: input, options: [], range: range) {
                    let dayRange = match.range(at: 1)
                    if let dayString = Range(dayRange, in: input).map({ String(input[$0]) }),
                       let day = Int(dayString), day >= 1 && day <= 31 {
                        return .fixed(day)
                    }
                }
            }
        }

        // Default to 1st of month if "monthly" but no specific day found
        return .fixed(1)
    }
}

// MARK: - Error Types

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
