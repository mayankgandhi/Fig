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
    
    // Token limit for context window (on-device model has 4096 token limit)
    private let maxInputTokens = 1000 // Conservative estimate leaving room for schema and response
    
    public enum RepeatOption: Equatable, Codable {
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
        
        print("🔧 AITickerGenerator: Generating with regex fallback")
        // Fallback to regex-based parsing
        configuration = try await configurationParser.parseConfiguration(from: validatedInput)
    
        
        // Additional validation
        if configuration.label.isEmpty {
            throw AITickerGenerationError.parsingFailed
        }
        
        // Log final configuration with all values
        print("✅ AITickerGenerator: Configuration generated - \(configuration.label)")
        return configuration
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
