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
        case hourly(interval: Int, startTime: Date, endTime: Date?)
        case every(interval: Int, unit: TickerSchedule.TimeUnit, startTime: Date, endTime: Date?)
        case biweekly([TickerSchedule.Weekday])
        case monthly(day: TickerSchedule.MonthlyDay)
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
        
        parsingTask = Task.detached(priority: .userInitiated) {
            do {
                // Add a small delay to debounce rapid typing
                try await Task.sleep(for: .milliseconds(500))
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                // Perform lightweight parsing off main thread
                let configuration = try await self.parseConfiguration(from: trimmedInput)
                
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
        let lowercaseInput = input.lowercased()
        
        // Parse duration using NSMeasurement
        let measurementFormats = [
            ("(\\d+)\\s*hours?\\s*(?:and\\s*)?(\\d+)?\\s*minutes?", { hours, minutes in
                TickerConfiguration.CountdownConfiguration(hours: hours, minutes: minutes ?? 0, seconds: 0)
            }),
            ("(\\d+)\\s*minutes?\\s*(?:and\\s*)?(\\d+)?\\s*seconds?", { minutes, seconds in
                TickerConfiguration.CountdownConfiguration(hours: 0, minutes: minutes, seconds: seconds ?? 0)
            }),
            ("(\\d+)\\s*hours?", { hours in
                TickerConfiguration.CountdownConfiguration(hours: hours, minutes: 0, seconds: 0)
            }),
            ("(\\d+)\\s*minutes?", { minutes in
                TickerConfiguration.CountdownConfiguration(hours: 0, minutes: minutes, seconds: 0)
            }),
            ("(\\d+)\\s*seconds?", { seconds in
                TickerConfiguration.CountdownConfiguration(hours: 0, minutes: 0, seconds: seconds)
            })
        ]
        
        for (pattern, handler) in measurementFormats {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: input.utf16.count)
                if let match = regex.firstMatch(in: input, options: [], range: range) {
                    let firstRange = match.range(at: 1)
                    if let firstString = Range(firstRange, in: input).map({ String(input[$0]) }),
                       let firstValue = Int(firstString) {
                        
                        var secondValue: Int? = nil
                        if match.numberOfRanges >= 3 {
                            let secondRange = match.range(at: 2)
                            if secondRange.location != NSNotFound,
                               let secondString = Range(secondRange, in: input).map({ String(input[$0]) }),
                               !secondString.isEmpty {
                                secondValue = Int(secondString)
                            }
                        }
                        
                        return handler(firstValue, secondValue)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseCountdownWithSimpleExtraction(from input: String) -> TickerConfiguration.CountdownConfiguration? {
        // Simple extraction for common patterns like "in 30 minutes", "with 2 hour countdown"
        let simplePatterns = [
            ("in (\\d+) hours?", { hours in
                TickerConfiguration.CountdownConfiguration(hours: hours, minutes: 0, seconds: 0)
            }),
            ("in (\\d+) minutes?", { minutes in
                TickerConfiguration.CountdownConfiguration(hours: 0, minutes: minutes, seconds: 0)
            }),
            ("with (\\d+) hour countdown", { hours in
                TickerConfiguration.CountdownConfiguration(hours: hours, minutes: 0, seconds: 0)
            }),
            ("with (\\d+) minute countdown", { minutes in
                TickerConfiguration.CountdownConfiguration(hours: 0, minutes: minutes, seconds: 0)
            })
        ]
        
        for (pattern, handler) in simplePatterns {
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
