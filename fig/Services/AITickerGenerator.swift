//
//  AITickerGenerator.swift
//  fig
//
//  AI-powered ticker generation using Apple Intelligence
//

import Foundation
import NaturalLanguage
import SwiftUI

// MARK: - Ticker Configuration

struct TickerConfiguration: Equatable {
    let label: String
    let time: TimeOfDay
    let date: Date
    let repeatOption: AITickerGenerator.RepeatOption
    let countdown: CountdownConfiguration?
    let icon: String
    let colorHex: String
    
    struct TimeOfDay: Equatable{
        let hour: Int
        let minute: Int
    }
    
    struct CountdownConfiguration: Equatable {
        let hours: Int
        let minutes: Int
        let seconds: Int
    }
}



// MARK: - AI Ticker Generator

@MainActor
class AITickerGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var parsedConfiguration: TickerConfiguration?
    
    private let activityMapper = ActivityIconMapper()
    private var parsingTask: Task<Void, Never>?
    
    enum RepeatOption: Equatable {
        case oneTime
        case daily
        case weekdays([TickerSchedule.Weekday])
        case hourly(interval: Int)
        case biweekly([TickerSchedule.Weekday])
        case monthly(day: Int)
        case yearly(month: Int, day: Int)
    }
    
    func parseInBackground(from input: String) {
        // Cancel any existing parsing task
        parsingTask?.cancel()
        
        // Clear previous results
        parsedConfiguration = nil
        
        // Don't parse empty or very short inputs
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedInput.count > 3 else {
            return
        }
        
        parsingTask = Task {
            do {
                // Add a small delay to debounce rapid typing
                try await Task.sleep(for: .milliseconds(500))
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                // Perform lightweight parsing
                let configuration = try await parseConfiguration(from: trimmedInput)
                
                // Update on main thread
                await MainActor.run {
                    self.parsedConfiguration = configuration
                }
            } catch {
                // Silently fail for background parsing - don't show errors to user
                await MainActor.run {
                    self.parsedConfiguration = nil
                }
            }
        }
    }
    
    private func parseConfiguration(from input: String) async throws -> TickerConfiguration {
        // Use Natural Language framework for text analysis
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = input
        
        // Extract entities and parse the input
        let entities = extractEntities(from: input, using: tagger)
        let timeInfo = parseTime(from: input, entities: entities)
        let dateInfo = parseDate(from: input, entities: entities)
        let repeatInfo = parseRepeatPattern(from: input, entities: entities)
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
        defer { isGenerating = false }
        
        // Validate input
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            throw AITickerGenerationError.invalidInput
        }
        
        // Use the shared parsing logic
        let configuration = try await parseConfiguration(from: trimmedInput)
        
        // Additional validation
        if configuration.label.isEmpty {
            throw AITickerGenerationError.parsingFailed
        }
        
        return configuration
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
        
        // Enhanced regex patterns for better time parsing
        let timePatterns = [
            // 12-hour format with AM/PM (prioritize these first)
            #"(\d{1,2}):(\d{2})\s*(am|pm)"#,
            #"(\d{1,2})\s*(am|pm)"#,
            #"at\s+(\d{1,2}):(\d{2})\s*(am|pm)"#,
            #"at\s+(\d{1,2})\s*(am|pm)"#,
            #"(\d{1,2})\s*:\s*(\d{2})\s*(am|pm)"#,
            #"(\d{1,2})\s*(am|pm)\s*(\d{2})"#,
            #"(\d{1,2})\s*\.\s*(\d{2})\s*(am|pm)"#,
            #"(?:at|around|about|by)\s+(\d{1,2}):(\d{2})\s*(am|pm)"#,
            #"(?:at|around|about|by)\s+(\d{1,2})\s*(am|pm)"#,
            
            // 24-hour format patterns (fallback)
            #"(\d{1,2}):(\d{2})\s*(?:am|pm)?"#,
            #"at\s+(\d{1,2}):(\d{2})"#,
            #"(\d{1,2}):(\d{2})"#,
            #"(\d{1,2})\s*:\s*(\d{2})\s*(?:am|pm)?"#,
            #"(\d{1,2})\s*\.\s*(\d{2})\s*(?:am|pm)?"#,
            #"(?:at|around|about|by)\s+(\d{1,2}):(\d{2})\s*(?:am|pm)?"#
        ]
        
        for pattern in timePatterns {
            if let time = parseTimeWithPattern(input, pattern: pattern) {
                return time
            }
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
    
    private func parseTimeWithPattern(_ input: String, pattern: String) -> TickerConfiguration.TimeOfDay? {
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
            if let minuteString = Range(minuteRange, in: input).map({ String(input[$0]) }) {
                // Check if this is actually AM/PM (for patterns like "7am")
                if minuteString.lowercased().contains("am") || minuteString.lowercased().contains("pm") {
                    hasAMPM = true
                    isPM = minuteString.lowercased().contains("pm")
                } else {
                    minute = Int(minuteString) ?? 0
                }
            }
        }
        
        // Extract AM/PM (if not already extracted)
        if !hasAMPM && match.numberOfRanges >= 3 {
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
        
        // Try to parse specific dates (e.g., "January 15th", "Dec 25")
        if let specificDate = parseSpecificDate(from: lowercaseInput) {
            return specificDate
        }
        
        // Default to today
        return now
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
    
    private func parseRepeatPattern(from input: String, entities: [String: [String]]) -> RepeatOption {
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
        
        // Check for hourly patterns with interval parsing
        if lowercaseInput.contains("every hour") || lowercaseInput.contains("hourly") {
            return .hourly(interval: 1)
        }
        
        // Parse specific hourly intervals
        let hourlyPattern = #"every\s+(\d+)\s*hours?"#
        if let regex = try? NSRegularExpression(pattern: hourlyPattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                let intervalRange = match.range(at: 1)
                if let intervalString = Range(intervalRange, in: input).map({ String(input[$0]) }),
                   let interval = Int(intervalString), interval > 0 {
                    return .hourly(interval: interval)
                }
            }
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
        
        // Check for monthly patterns
        if lowercaseInput.contains("monthly") || lowercaseInput.contains("every month") {
            // Try to extract day of month with more flexible patterns
            let monthlyPatterns = [
                #"(\d{1,2})(?:st|nd|rd|th)?\s*(?:of\s*)?(?:every\s*)?month"#,
                #"monthly\s*report\s*on\s*the\s*(\d{1,2})(?:st|nd|rd|th)?"#,
                #"on\s*the\s*(\d{1,2})(?:st|nd|rd|th)?\s*(?:of\s*)?(?:every\s*)?month"#,
                #"(\d{1,2})(?:st|nd|rd|th)?\s*(?:of\s*)?month"#
            ]
            
            for pattern in monthlyPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(location: 0, length: input.utf16.count)
                    if let match = regex.firstMatch(in: input, options: [], range: range) {
                        let dayRange = match.range(at: 1)
                        if let dayString = Range(dayRange, in: input).map({ String(input[$0]) }),
                           let day = Int(dayString), day >= 1 && day <= 31 {
                            return .monthly(day: day)
                        }
                    }
                }
            }
            return .monthly(day: 1) // Default to 1st of month
        }
        
        // Check for yearly patterns
        if lowercaseInput.contains("yearly") || lowercaseInput.contains("annually") || lowercaseInput.contains("every year") {
            return .yearly(month: 1, day: 1) // Default to January 1st
        }
        
        // Default to one time
        return .oneTime
    }
    
    private func parseCountdown(from input: String) -> TickerConfiguration.CountdownConfiguration? {
        let lowercaseInput = input.lowercased()
        
        // Enhanced countdown patterns
        let countdownPatterns = [
            // Hours and minutes (prioritize these first)
            #"(\d+)\s*hour\s*(?:and\s*)?(\d+)?\s*minute\s*countdown"#,
            #"(\d+)\s*hr\s*(?:and\s*)?(\d+)?\s*min\s*countdown"#,
            #"(\d+)\s*h\s*(?:and\s*)?(\d+)?\s*m\s*countdown"#,
            #"(\d+)\s*hour\s*(?:and\s*)?(\d+)?\s*minute"#,
            #"(\d+)\s*hr\s*(?:and\s*)?(\d+)?\s*min"#,
            
            // Minutes only
            #"(\d+)\s*minute\s*countdown"#,
            #"(\d+)\s*min\s*countdown"#,
            #"countdown\s*of\s*(\d+)\s*minutes"#,
            #"(\d+)\s*minute\s*reminder"#,
            #"(\d+)\s*min\s*reminder"#,
            #"(\d+)\s*minute\s*alert"#,
            #"(\d+)\s*min\s*alert"#,
            #"(\d+)\s*minute\s*notice"#,
            #"(\d+)\s*min\s*notice"#,
            
            // With "with" or "after" or "in"
            #"with\s*(\d+)\s*minute\s*countdown"#,
            #"after\s*(\d+)\s*minutes"#,
            #"in\s*(\d+)\s*minutes"#,
            #"in\s*(\d+)\s*hours"#,
            #"wake\s*up\s*in\s*(\d+)\s*hours"#,
            
            // Seconds
            #"(\d+)\s*second\s*countdown"#,
            #"(\d+)\s*sec\s*countdown"#
        ]
        
        for pattern in countdownPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: input.utf16.count)
                if let match = regex.firstMatch(in: input, options: [], range: range) {
                    var hours = 0
                    var minutes = 0
                    var seconds = 0
                    
                    // Extract first number (could be hours or minutes)
                    if match.numberOfRanges >= 2 {
                        let firstRange = match.range(at: 1)
                        if let firstString = Range(firstRange, in: input).map({ String(input[$0]) }),
                           let firstValue = Int(firstString) {
                            
                            // Check if this is a time pattern with hours and minutes
                            if pattern.contains("hour") || pattern.contains("hr") || pattern.contains("h\\s") || pattern.contains("hours") {
                                hours = firstValue
                                
                                // Extract minutes if present
                                if match.numberOfRanges >= 3 {
                                    let secondRange = match.range(at: 2)
                                    if let secondString = Range(secondRange, in: input).map({ String(input[$0]) }),
                                       let secondValue = Int(secondString) {
                                        minutes = secondValue
                                    }
                                }
                            } else if pattern.contains("second") || pattern.contains("sec") {
                                seconds = firstValue
                            } else {
                                // Default to minutes
                                minutes = firstValue
                            }
                        }
                    }
                    
                    // Validate the countdown duration
                    if hours > 0 || minutes > 0 || seconds > 0 {
                        return TickerConfiguration.CountdownConfiguration(
                            hours: hours,
                            minutes: minutes,
                            seconds: seconds
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseActivity(from input: String, entities: [String: [String]]) -> (label: String, icon: String, colorHex: String) {
        let activityInfo = activityMapper.mapActivity(from: input)
        return (activityInfo.label, activityInfo.icon, activityInfo.colorHex)
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
