//
//  ActivityIconMapper.swift
//  fig
//
//  Maps activities to appropriate icons and colors
//

import Foundation
import NaturalLanguage
import SwiftUI

// MARK: - Activity Mapping Result

public struct ActivityMapping {
    public let label: String
    public let icon: String
    public let colorHex: String
    public let category: ActivityCategory

    public init(label: String, icon: String, colorHex: String, category: ActivityCategory) {
        self.label = label
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
    }
}

public enum ActivityCategory: String, CaseIterable {
    case health = "Health"
    case work = "Work"
    case personal = "Personal"
    case exercise = "Exercise"
    case meals = "Meals"
    case medication = "Medication"
    case sleep = "Sleep"
    case general = "General"
}

// MARK: - Activity Icon Mapper

public class ActivityIconMapper {
    
    private let activityMappings: [String: ActivityMapping] = [
        // Health & Medication
        "medication": ActivityMapping(label: "Medication", icon: "pills", colorHex: "#EF4444", category: .medication),
        "medicine": ActivityMapping(label: "Medicine", icon: "pills", colorHex: "#EF4444", category: .medication),
        "pills": ActivityMapping(label: "Pills", icon: "pills", colorHex: "#EF4444", category: .medication),
        "doctor": ActivityMapping(label: "Doctor", icon: "cross.case", colorHex: "#EF4444", category: .health),
        "appointment": ActivityMapping(label: "Appointment", icon: "cross.case", colorHex: "#EF4444", category: .health),
        "checkup": ActivityMapping(label: "Checkup", icon: "cross.case", colorHex: "#EF4444", category: .health),
        
        // Exercise & Fitness
        "yoga": ActivityMapping(label: "Yoga", icon: "figure.yoga", colorHex: "#84CC16", category: .exercise),
        "workout": ActivityMapping(label: "Workout", icon: "figure.run", colorHex: "#FF6B35", category: .exercise),
        "gym": ActivityMapping(label: "Gym", icon: "dumbbell", colorHex: "#FF6B35", category: .exercise),
        "running": ActivityMapping(label: "Running", icon: "figure.run", colorHex: "#FF6B35", category: .exercise),
        "jogging": ActivityMapping(label: "Jogging", icon: "figure.run", colorHex: "#FF6B35", category: .exercise),
        "walking": ActivityMapping(label: "Walking", icon: "figure.walk", colorHex: "#10B981", category: .exercise),
        "cycling": ActivityMapping(label: "Cycling", icon: "bicycle", colorHex: "#10B981", category: .exercise),
        "swimming": ActivityMapping(label: "Swimming", icon: "figure.pool.swim", colorHex: "#06B6D4", category: .exercise),
        
        // Work & Meetings
        "meeting": ActivityMapping(label: "Meeting", icon: "person.3", colorHex: "#3B82F6", category: .work),
        "team meeting": ActivityMapping(label: "Team Meeting", icon: "person.3", colorHex: "#3B82F6", category: .work),
        "team": ActivityMapping(label: "Team Meeting", icon: "person.3", colorHex: "#3B82F6", category: .work),
        "conference": ActivityMapping(label: "Conference", icon: "person.3", colorHex: "#3B82F6", category: .work),
        "call": ActivityMapping(label: "Call", icon: "phone", colorHex: "#3B82F6", category: .work),
        "presentation": ActivityMapping(label: "Presentation", icon: "presentation", colorHex: "#3B82F6", category: .work),
        "deadline": ActivityMapping(label: "Deadline", icon: "calendar.badge.clock", colorHex: "#F59E0B", category: .work),
        "project": ActivityMapping(label: "Project", icon: "folder", colorHex: "#3B82F6", category: .work),
        
        // Meals & Food
        "breakfast": ActivityMapping(label: "Breakfast", icon: "sunrise", colorHex: "#F59E0B", category: .meals),
        "lunch": ActivityMapping(label: "Lunch", icon: "fork.knife", colorHex: "#10B981", category: .meals),
        "dinner": ActivityMapping(label: "Dinner", icon: "fork.knife", colorHex: "#8B5CF6", category: .meals),
        "meal": ActivityMapping(label: "Meal", icon: "fork.knife", colorHex: "#10B981", category: .meals),
        "eat": ActivityMapping(label: "Eat", icon: "fork.knife", colorHex: "#10B981", category: .meals),
        "coffee": ActivityMapping(label: "Coffee", icon: "cup.and.saucer", colorHex: "#92400E", category: .meals),
        "tea": ActivityMapping(label: "Tea", icon: "cup.and.saucer", colorHex: "#92400E", category: .meals),
        "snack": ActivityMapping(label: "Snack", icon: "fork.knife", colorHex: "#F59E0B", category: .meals),
        
        // Sleep & Wake
        "wake": ActivityMapping(label: "Wake Up", icon: "sunrise", colorHex: "#F59E0B", category: .sleep),
        "wake up": ActivityMapping(label: "Wake Up", icon: "sunrise", colorHex: "#F59E0B", category: .sleep),
        "sleep": ActivityMapping(label: "Sleep", icon: "moon", colorHex: "#6366F1", category: .sleep),
        "bedtime": ActivityMapping(label: "Bedtime", icon: "moon", colorHex: "#6366F1", category: .sleep),
        "nap": ActivityMapping(label: "Nap", icon: "moon", colorHex: "#6366F1", category: .sleep),
        
        // Personal & Daily Tasks
        "shower": ActivityMapping(label: "Shower", icon: "drop", colorHex: "#06B6D4", category: .personal),
        "bath": ActivityMapping(label: "Bath", icon: "drop", colorHex: "#06B6D4", category: .personal),
        "laundry": ActivityMapping(label: "Laundry", icon: "washer", colorHex: "#8B5CF6", category: .personal),
        "cleaning": ActivityMapping(label: "Cleaning", icon: "sparkles", colorHex: "#8B5CF6", category: .personal),
        "shopping": ActivityMapping(label: "Shopping", icon: "cart", colorHex: "#10B981", category: .personal),
        "grocery": ActivityMapping(label: "Grocery", icon: "cart", colorHex: "#10B981", category: .personal),
        "reading": ActivityMapping(label: "Reading", icon: "book", colorHex: "#8B5CF6", category: .personal),
        "study": ActivityMapping(label: "Study", icon: "book", colorHex: "#8B5CF6", category: .personal),
        "homework": ActivityMapping(label: "Homework", icon: "book", colorHex: "#8B5CF6", category: .personal),
        
        // Transportation
        "bus": ActivityMapping(label: "Bus", icon: "bus", colorHex: "#3B82F6", category: .personal),
        "train": ActivityMapping(label: "Train", icon: "tram", colorHex: "#3B82F6", category: .personal),
        "flight": ActivityMapping(label: "Flight", icon: "airplane", colorHex: "#3B82F6", category: .personal),
        "drive": ActivityMapping(label: "Drive", icon: "car", colorHex: "#3B82F6", category: .personal),
        
        // Entertainment
        "movie": ActivityMapping(label: "Movie", icon: "tv", colorHex: "#8B5CF6", category: .personal),
        "game": ActivityMapping(label: "Game", icon: "gamecontroller", colorHex: "#8B5CF6", category: .personal),
        "music": ActivityMapping(label: "Music", icon: "music.note", colorHex: "#8B5CF6", category: .personal),
        "party": ActivityMapping(label: "Party", icon: "party.popper", colorHex: "#EC4899", category: .personal),
        
        // General/Default
        "reminder": ActivityMapping(label: "Reminder", icon: "bell", colorHex: "#8B5CF6", category: .general),
        "alarm": ActivityMapping(label: "Alarm", icon: "alarm", colorHex: "#8B5CF6", category: .general),
        "ticker": ActivityMapping(label: "Ticker", icon: "alarm", colorHex: "#8B5CF6", category: .general)
    ]

    public init() {}

    public func mapActivity(from input: String) -> ActivityMapping {
        let lowercaseInput = input.lowercased()
        
        // Use NaturalLanguage framework for better text analysis
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = input
        
        // Find the best matching activity using semantic analysis
        if let semanticMapping = findSemanticMapping(from: input, tagger: tagger) {
            return semanticMapping
        }
        
        // Fallback to keyword matching with boundary awareness
        if let keywordMapping = findKeywordMapping(in: lowercaseInput) {
            return keywordMapping
        }
        
        // Try to extract a custom label from the input
        let customLabel = extractCustomLabelWithNL(from: input, tagger: tagger)
        
        // Default mapping
        return ActivityMapping(
            label: customLabel,
            icon: "alarm",
            colorHex: "#8B5CF6",
            category: .general
        )
    }
    
    private func findSemanticMapping(from input: String, tagger: NLTagger) -> ActivityMapping? {
        // Use NaturalLanguage to find semantic matches
        var bestMatch: ActivityMapping?
        var bestScore = 0.0
        
        for (keyword, mapping) in activityMappings {
            // Check for semantic similarity using word embeddings or simple word overlap
            let score = calculateSemanticScore(input: input, keyword: keyword)
            if score > bestScore && score > 0.3 { // Threshold for semantic similarity
                bestScore = score
                bestMatch = mapping
            }
        }
        
        return bestMatch
    }
    
    private func calculateSemanticScore(input: String, keyword: String) -> Double {
        let inputWords = Set(input.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let keywordWords = Set(keyword.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        // Calculate Jaccard similarity
        let intersection = inputWords.intersection(keywordWords)
        let union = inputWords.union(keywordWords)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }

    private func findKeywordMapping(in lowercaseInput: String) -> ActivityMapping? {
        var bestMatch: (mapping: ActivityMapping, priority: Int, score: Int)?

        for (keyword, mapping) in activityMappings {
            if keywordMatches(input: lowercaseInput, keyword: keyword) {
                let priority = categoryPriority(for: mapping.category)
                let score = keyword.count

                if let currentBest = bestMatch {
                    if priority > currentBest.priority || (priority == currentBest.priority && score > currentBest.score) {
                        bestMatch = (mapping, priority, score)
                    }
                } else {
                    bestMatch = (mapping, priority, score)
                }
            }
        }

        return bestMatch?.mapping
    }

    private func categoryPriority(for category: ActivityCategory) -> Int {
        switch category {
        case .general:
            return 0
        default:
            return 1
        }
    }

    private func keywordMatches(input: String, keyword: String) -> Bool {
        let keywordLowercased = keyword.lowercased()
        var searchRange = input.startIndex..<input.endIndex

        while let foundRange = input.range(of: keywordLowercased, options: [], range: searchRange) {
            if isWordBounded(input: input, range: foundRange) {
                return true
            }

            searchRange = foundRange.upperBound..<input.endIndex
        }

        return false
    }

    private func isWordBounded(input: String, range: Range<String.Index>) -> Bool {
        if range.lowerBound > input.startIndex {
            let before = input[input.index(before: range.lowerBound)]
            if before.isLetterOrNumber {
                return false
            }
        }

        if range.upperBound < input.endIndex {
            let after = input[range.upperBound]
            if after.isLetterOrNumber {
                return false
            }
        }

        return true
    }
    
    private func extractCustomLabelWithNL(from input: String, tagger: NLTagger) -> String {
        var meaningfulWords: [String] = []
        
        // Extract nouns and verbs using NaturalLanguage
        tagger.enumerateTags(in: input.startIndex..<input.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag {
                let word = String(input[range]).lowercased()

                if (tag == .noun || tag == .verb), !isTimeRelatedWord(word) {
                    meaningfulWords.append(word.capitalized)
                } else if (tag == .particle || tag == .adverb), word == "up", let last = meaningfulWords.last, last == "Follow" {
                    meaningfulWords[meaningfulWords.count - 1] = "Follow Up"
                }
            }
            return true
        }
        
        if !meaningfulWords.isEmpty {
            return meaningfulWords.joined(separator: " ")
        }
        
        // Fallback to simple extraction
        return extractCustomLabel(from: input)
    }
    
    private func isTimeRelatedWord(_ word: String) -> Bool {
        let timeWords: Set<String> = [
            "a", "an", "at", "am", "pm", "and", "every", "each", "daily", "tomorrow",
            "today", "next", "week", "weeks", "weekday", "weekdays", "weekend", "day",
            "days", "hour", "hours", "minute", "minutes", "second", "seconds", "with",
            "remind", "reminder", "me", "my", "to", "take", "have", "do", "go", "be",
            "alarm", "ticker", "time", "schedule", "monthly", "month", "months", "year",
            "yearly", "annually", "annual", "countdown", "before", "prior", "earlier",
            "ahead", "first", "second", "third", "fourth", "fifth", "starting", "monday", "tuesday",
            "wednesday", "thursday", "friday", "saturday", "sunday", "mon", "tue", "tues",
            "wed", "thu", "thur", "thurs", "fri", "sat", "sun", "january", "february",
            "march", "april", "may", "june", "july", "august", "september", "october",
            "november", "december"
        ]
        return timeWords.contains(word)
    }
    
    private func extractCustomLabel(from input: String) -> String {
        // Try to extract a meaningful label from the input
        let words = input.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
        
        // Remove common time-related words
        let timeWords: Set<String> = [
            "a", "an", "at", "am", "pm", "and", "every", "each", "daily", "tomorrow",
            "today", "next", "week", "weeks", "weekday", "weekdays", "weekend", "day",
            "days", "hour", "hours", "minute", "minutes", "second", "seconds", "with",
            "remind", "reminder", "me", "my", "to", "take", "have", "do", "go", "be",
            "starting", "from", "in", "about", "around", "set", "schedule", "reminded",
            "monthly", "month", "months", "year", "yearly", "annually", "annual",
            "countdown", "before", "prior", "earlier", "ahead", "first", "second", "third",
            "fourth", "fifth", "monday", "tuesday", "wednesday", "thursday", "friday",
            "saturday", "sunday", "mon", "tue", "tues", "wed", "thu", "thur", "thurs",
            "fri", "sat", "sun", "january", "february", "march", "april", "may", "june",
            "july", "august", "september", "october", "november", "december"
        ]
        let filteredWords = words.filter { !timeWords.contains($0) }
        
        if !filteredWords.isEmpty {
            // Capitalize first letter of each word
            var resultWords: [String] = []
            var index = 0

            while index < filteredWords.count {
                let word = filteredWords[index]
                if word == "follow", index + 1 < filteredWords.count, filteredWords[index + 1] == "up" {
                    resultWords.append("Follow Up")
                    index += 2
                    continue
                }

                resultWords.append(word.capitalized)
                index += 1
            }

            return resultWords.joined(separator: " ")
        }
        
        return "Ticker"
    }
    
    func getIconsForCategory(_ category: ActivityCategory) -> [String] {
        let categoryIcons: [ActivityCategory: [String]] = [
            .health: ["cross.case", "heart.fill", "waveform.path.ecg", "drop.fill"],
            .medication: ["pills", "cross.case", "syringe"],
            .exercise: ["figure.run", "figure.yoga", "figure.walk", "dumbbell", "bicycle", "figure.pool.swim"],
            .work: ["person.3", "phone", "presentation", "folder", "calendar.badge.clock"],
            .meals: ["fork.knife", "cup.and.saucer", "sunrise", "moon"],
            .sleep: ["moon", "sunrise", "bed.double"],
            .personal: ["book", "cart", "washer", "sparkles", "drop", "music.note", "tv", "gamecontroller"],
            .general: ["alarm", "bell", "clock", "timer"]
        ]
        
        return categoryIcons[category] ?? ["alarm"]
    }
    
    func getColorsForCategory(_ category: ActivityCategory) -> [String] {
        let categoryColors: [ActivityCategory: [String]] = [
            .health: ["#EF4444", "#F87171", "#FCA5A5"],
            .medication: ["#EF4444", "#F87171", "#FCA5A5"],
            .exercise: ["#FF6B35", "#84CC16", "#10B981", "#06B6D4"],
            .work: ["#3B82F6", "#60A5FA", "#93C5FD"],
            .meals: ["#F59E0B", "#10B981", "#8B5CF6", "#92400E"],
            .sleep: ["#6366F1", "#F59E0B", "#8B5CF6"],
            .personal: ["#8B5CF6", "#10B981", "#06B6D4", "#EC4899"],
            .general: ["#8B5CF6", "#6B7280", "#9CA3AF"]
        ]
        
        return categoryColors[category] ?? ["#8B5CF6"]
    }
}

private extension Character {
    var isLetterOrNumber: Bool {
        unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }
    }
}
