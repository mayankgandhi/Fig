//
//  AlarmSuggestionProvider.swift
//  fig
//
//  Provider for donating ticker creation actions to SiriKit
//

import Foundation
import AppIntents
import SwiftData

/// Provider that donates ticker creation actions to SiriKit for learning
@MainActor
class AlarmSuggestionProvider {
    
    static let shared = AlarmSuggestionProvider()
    
    private init() {}
    
    /// Donate a ticker creation action to SiriKit
    func donateTickerCreation(
        time: Date,
        label: String,
        repeatFrequency: RepeatFrequencyEnum = .oneTime,
        icon: String? = nil,
        colorHex: String? = nil,
        soundName: String? = nil
    ) {
        let intent = CreateAlarmIntent(
            time: time,
            label: label,
            repeatFrequency: repeatFrequency,
            icon: icon,
            colorHex: colorHex,
            soundName: soundName
        )
        
        // Donate using AppIntents framework
        Task {
            do {
                try await intent.donate()
                print("✅ Donated ticker creation to SiriKit")
            } catch {
                print("⚠️ Failed to donate ticker creation: \(error)")
            }
        }
    }
    
    /// Donate an AI-generated ticker creation action
    func donateAITickerCreation(
        naturalLanguageInput: String,
        resultingTicker: Ticker
    ) {
        // Create intent with the natural language input as label for context
        let intent = CreateAlarmIntent(
            time: Date(), // Will be overridden by actual ticker time
            label: naturalLanguageInput,
            repeatFrequency: .oneTime
        )
        
        // Donate using AppIntents framework
        Task {
            do {
                try await intent.donate()
                print("✅ Donated AI ticker creation to SiriKit")
            } catch {
                print("⚠️ Failed to donate AI ticker creation: \(error)")
            }
        }
    }
    
    /// Donate contextual suggestions based on user patterns
    func donateContextualSuggestions() {
        // Donate common patterns
        let commonPatterns = [
            ("Morning Wake Up", 7, 0, RepeatFrequencyEnum.weekdays, "sunrise", "#FF6B6B", "Gentle"),
            ("Bedtime", 22, 0, RepeatFrequencyEnum.daily, "moon", "#4ECDC4", "Nature"),
            ("Exercise", 6, 0, RepeatFrequencyEnum.weekdays, "figure.run", "#96CEB4", "Bells"),
            ("Medication", 9, 0, RepeatFrequencyEnum.daily, "pills", "#45B7D1", "Chimes"),
            ("Coffee Break", 10, 30, RepeatFrequencyEnum.weekdays, "cup.and.saucer", "#FFEAA7", "Ocean")
        ]
        
        for (label, hour, minute, frequency, icon, color, sound) in commonPatterns {
            let calendar = Calendar.current
            let today = Date()
            if let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
                donateTickerCreation(
                    time: time,
                    label: label,
                    repeatFrequency: frequency,
                    icon: icon,
                    colorHex: color,
                    soundName: sound
                )
            }
        }
    }
    
    /// Analyze user's ticker patterns and donate personalized suggestions
    func analyzeAndDonatePatterns(context: ModelContext) {
        Task {
            do {
                let descriptor = FetchDescriptor<Ticker>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                let recentTickers = try context.fetch(descriptor)
                
                // Analyze patterns in recent tickers
                let patterns = analyzeTickerPatterns(tickers: recentTickers)
                
                // Donate personalized suggestions
                for pattern in patterns {
                    donateTickerCreation(
                        time: pattern.time,
                        label: pattern.label,
                        repeatFrequency: pattern.frequency,
                        icon: pattern.icon,
                        colorHex: pattern.colorHex
                    )
                }
                
            } catch {
                print("⚠️ Failed to analyze ticker patterns: \(error)")
            }
        }
    }
    
    // MARK: - Pattern Analysis
    
    private func analyzeTickerPatterns(tickers: [Ticker]) -> [TickerPattern] {
        var patterns: [TickerPattern] = []
        
        // Group by time patterns
        let timeGroups = Dictionary(grouping: tickers) { ticker in
            ticker.schedule?.displaySummary ?? "Unknown"
        }
        
        // Find most common patterns
        for (scheduleSummary, tickers) in timeGroups {
            if tickers.count >= 2 { // Only suggest patterns used multiple times
                let mostCommonTicker = tickers.first!
                let time = extractTimeFromSchedule(mostCommonTicker.schedule)
                
                patterns.append(TickerPattern(
                    time: time,
                    label: mostCommonTicker.displayName,
                    frequency: determineFrequency(from: mostCommonTicker.schedule),
                    icon: mostCommonTicker.tickerData?.icon,
                    colorHex: mostCommonTicker.tickerData?.colorHex,
                    soundName: mostCommonTicker.soundName
                ))
            }
        }
        
        return patterns
    }
    
    private func extractTimeFromSchedule(_ schedule: TickerSchedule?) -> Date {
        guard let schedule = schedule else { return Date() }
        
        let calendar = Calendar.current
        let today = Date()
        
        switch schedule {
        case .oneTime(let date):
            return date
        case .daily(let time), .weekdays(let time, _), .biweekly(let time, _):
            return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: today) ?? today
        case .hourly(let interval, let time):
            return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: today) ?? today
        case .every(let interval, let unit, let time):
            return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: today) ?? today
        case .monthly(let day, let time):
            return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: today) ?? today
        case .yearly(let month, let day, let time):
            return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: today) ?? today
        }
    }
    
    private func determineFrequency(from schedule: TickerSchedule?) -> RepeatFrequencyEnum {
        guard let schedule = schedule else { return .oneTime }
        
        switch schedule {
        case .oneTime:
            return .oneTime
        case .daily:
            return .daily
        case .weekdays:
            return .weekdays
        case .biweekly:
            return .weekdays // Map biweekly to weekdays for simplicity
        case .hourly, .every, .monthly, .yearly:
            return .daily // Default to daily for complex schedules
        }
    }
}

// MARK: - Supporting Types

struct TickerPattern {
    let time: Date
    let label: String
    let frequency: RepeatFrequencyEnum
    let icon: String?
    let colorHex: String?
    let soundName: String?
}
