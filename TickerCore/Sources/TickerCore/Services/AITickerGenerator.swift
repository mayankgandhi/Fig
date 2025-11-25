//
//  AITickerGenerator.swift
//  fig
//
//  AI-powered ticker generation using Apple Intelligence Foundation Models
//  Pure service - all state management handled by calling code
//

import Foundation
import FoundationModels
import NaturalLanguage
import SwiftUI

// MARK: - AI Ticker Generator

@MainActor
public final class AITickerGenerator {

    private let configurationParser = TickerConfigurationParser()
    private let foundationModelsParser = FoundationModelsParser()
    private let sessionManager = AISessionManager.shared

    // Token limit for context window (on-device model has 4096 token limit)
    private let maxInputTokens = 1000 // Conservative estimate leaving room for schema and response

    public enum RepeatOption: Equatable {
        case oneTime
        case daily
        case weekdays([TickerSchedule.Weekday])
        case hourly(interval: Int)
        case every(interval: Int, unit: TickerSchedule.TimeUnit)
        case biweekly([TickerSchedule.Weekday])
        case monthly(day: TickerSchedule.MonthlyDay)
        case yearly(month: Int, day: Int)
    }

    public init() {}

    // MARK: - Pure Async Functions

    /// Parses user input into a TickerConfiguration
    /// Returns nil if input is too short or cannot be parsed
    public func parseConfiguration(from input: String) async throws -> TickerConfiguration? {
        // Don't parse empty or very short inputs
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedInput.count > 3 else {
            return nil
        }

        // Validate and truncate input if needed to stay within context window
        let validatedInput = truncateIfNeeded(trimmedInput)
        let tokenCount = estimateTokenCount(for: validatedInput)

        print("🔍 AITickerGenerator: Starting parse for input (est. \(tokenCount) tokens)")

        // Try Foundation Models first, fallback to regex parsing
        if sessionManager.isFoundationModelsAvailable, let session = sessionManager.getSession() {
            print("🔍 AITickerGenerator: Using Foundation Models")
            do {
                let response = try await foundationModelsParser.parse(input: validatedInput, session: session)
                let configuration = convertToTickerConfiguration(response)
                print("🔍 AITickerGenerator: Foundation Models parsing complete - config: \(configuration.label)")
                return configuration
            } catch {
                print("❌ AITickerGenerator: Foundation Models error - \(error)")
                // Fallback to regex parsing on error
                if let configuration = try? await configurationParser.parseConfiguration(from: validatedInput) {
                    print("✅ AITickerGenerator: Fallback regex parsing succeeded")
                    return configuration
                } else {
                    print("❌ AITickerGenerator: Regex parsing also failed")
                    return nil
                }
            }
        } else {
            // Fallback to regex-based parsing with validated input
            print("🔍 AITickerGenerator: Using regex parsing fallback")
            do {
                let configuration = try await configurationParser.parseConfiguration(from: validatedInput)
                print("🔍 AITickerGenerator: Regex parsing complete - config: \(configuration.label)")
                return configuration
            } catch {
                print("🔍 AITickerGenerator: Regex parsing failed: \(error)")
                return nil
            }
        }
    }

    /// Generates a complete TickerConfiguration from user input
    /// Throws AITickerGenerationError if parsing fails
    public func generateConfiguration(from input: String) async throws -> TickerConfiguration {
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            print("⏱️ AITickerGenerator: Total generation time: \(String(format: "%.2f", duration))s")
        }

        // Validate and truncate input to stay within context window
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            throw AITickerGenerationError.invalidInput
        }

        let validatedInput = truncateIfNeeded(trimmedInput)

        // Try Foundation Models first, fallback to regex parsing
        let configuration: TickerConfiguration

        if sessionManager.isFoundationModelsAvailable, let session = sessionManager.getSession() {
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
        print("✅ AITickerGenerator: Configuration generated - \(configuration.label)")
        return configuration
    }

    // MARK: - Private Helper Functions

    private func parseWithFoundationModels(input: String, session: LanguageModelSession) async throws -> TickerConfiguration {
        let response = try await foundationModelsParser.parse(input: input, session: session)
        return convertToTickerConfiguration(response)
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
                    let weekdays = parseWeekdays(from: repeatDaysString)
                    repeatOption = weekdays.isEmpty ? .oneTime : .weekdays(weekdays)
                } else {
                    repeatOption = .oneTime
                }
            case "hourly":
                let interval = response.repeatInterval ?? 1
                repeatOption = .hourly(interval: interval)
            case "every":
                let interval = response.repeatInterval ?? 1
                let unitString = response.repeatUnit ?? "Hours"
                let unit: TickerSchedule.TimeUnit
                switch unitString.lowercased() {
                    case "minutes", "minute": unit = .minutes
                    case "hours", "hour": unit = .hours
                    case "days", "day": unit = .days
                    case "weeks", "week": unit = .weeks
                    default: unit = .hours
                }
                repeatOption = .every(interval: interval, unit: unit)
            case "biweekly":
                if let repeatDaysString = response.repeatDays, !repeatDaysString.isEmpty {
                    let weekdays = parseWeekdays(from: repeatDaysString)
                    repeatOption = weekdays.isEmpty ? .oneTime : .biweekly(weekdays)
                } else {
                    // Default to weekdays if no days specified
                    repeatOption = .biweekly([.monday, .tuesday, .wednesday, .thursday, .friday])
                }
            case "monthly":
                let monthlyDay = parseMonthlyDay(from: response.monthlyDay)
                repeatOption = .monthly(day: monthlyDay)
            case "yearly":
                let month = response.month ?? calendar.component(.month, from: now)
                let day = response.day ?? calendar.component(.day, from: now)
                repeatOption = .yearly(month: month, day: day)
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
            time: TimeOfDay(hour: response.hour, minute: response.minute),
            date: date,
            repeatOption: repeatOption,
            countdown: countdown,
            icon: response.icon,
            colorHex: response.colorHex
        )
    }

    private func parseWeekdays(from repeatDaysString: String) -> [TickerSchedule.Weekday] {
        let weekdayNames = repeatDaysString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return weekdayNames.compactMap { name -> TickerSchedule.Weekday? in
            switch name.lowercased() {
                case "monday", "mon": return .monday
                case "tuesday", "tue", "tues": return .tuesday
                case "wednesday", "wed": return .wednesday
                case "thursday", "thu", "thur", "thurs": return .thursday
                case "friday", "fri": return .friday
                case "saturday", "sat": return .saturday
                case "sunday", "sun": return .sunday
                default: return nil
            }
        }
    }

    private func parseMonthlyDay(from monthlyDayString: String?) -> TickerSchedule.MonthlyDay {
        guard let monthlyDayString = monthlyDayString, !monthlyDayString.isEmpty else {
            // Default to first of month if not specified
            return .firstOfMonth
        }

        let lowercased = monthlyDayString.lowercased()

        // Check for special cases
        if lowercased == "firstofmonth" || lowercased == "first of month" || lowercased == "firstday" {
            return .firstOfMonth
        }

        if lowercased == "lastofmonth" || lowercased == "last of month" || lowercased == "lastday" {
            return .lastOfMonth
        }

        // Check for first weekday patterns (e.g., "firstMonday", "first Monday")
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
            if lowercased.contains("first\(dayName)") || lowercased.contains("first \(dayName)") {
                return .firstWeekday(weekday)
            }
            if lowercased.contains("last\(dayName)") || lowercased.contains("last \(dayName)") {
                return .lastWeekday(weekday)
            }
        }

        // Try to parse as fixed day number (1-31)
        if let dayNumber = Int(monthlyDayString.trimmingCharacters(in: .whitespaces)) {
            if dayNumber >= 1 && dayNumber <= 31 {
                return .fixed(dayNumber)
            }
        }

        // Default to first of month if parsing fails
        return .firstOfMonth
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
}

public enum AITickerGenerationError: LocalizedError {
    case invalidInput
    case parsingFailed
    case unsupportedFormat

    public var errorDescription: String? {
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
