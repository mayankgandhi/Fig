//
//  FoundationModelsParser.swift
//  fig
//
//  Parser for Apple Intelligence Foundation Models API interactions
//

import Foundation
import FoundationModels

/// Handles all interactions with Apple Foundation Models for parsing ticker configurations
public class FoundationModelsParser {
    
    // MARK: - Session Creation
    
    /// Creates a LanguageModelSession with custom instructions for ticker parsing
    /// - Parameter model: The language model to use
    /// - Returns: A configured LanguageModelSession
    func createSession(model: SystemLanguageModel) -> LanguageModelSession {
        return LanguageModelSession(
            model: model,
            instructions: {
                """
                You are an intelligent assistant that helps users create alarm reminders (called "Tickers") from natural language descriptions.
                
                Your task is to extract structured information from user input including:
                - Activity label (what they want to be reminded about) - REQUIRED
                - Time (when the reminder should trigger in 24-hour format) - REQUIRED
                - Date (which day - optional, omit if not specified by user)
                - Repeat pattern: "oneTime", "daily", "weekdays", "specificDays", "hourly", "every", "biweekly", "monthly", or "yearly" - REQUIRED
                - For specificDays or biweekly: provide weekday names like "Monday,Wednesday,Friday" in repeatDays - OPTIONAL, only for these patterns
                - For hourly: provide interval in repeatInterval (e.g., 2 for every 2 hours) - OPTIONAL, only for hourly pattern
                - For every: provide interval in repeatInterval and unit in repeatUnit ("Minutes", "Hours", "Days", "Weeks") - OPTIONAL, only for every pattern
                - For monthly: provide day specification in monthlyDay (number 1-31, "firstOfMonth", "lastOfMonth", or "firstMonday"/"lastFriday" etc.) - OPTIONAL, only for monthly pattern
                - For yearly: use month and day fields - OPTIONAL, only for yearly pattern
                - Countdown duration if they mention it (in hours and minutes) - OPTIONAL
                - Appropriate SF Symbol icon that matches the activity - REQUIRED
                - Hex color code that fits the activity theme (without # prefix) - REQUIRED
                
                Be intelligent about inferring context:
                - "Wake up at 7am every weekday" → weekdays pattern, no date needed
                - "Gym on Monday Wednesday Friday" → specificDays with "Monday,Wednesday,Friday"
                - "Take medicine at 9am daily" → daily pattern
                - "Meeting next Tuesday at 2:30pm" → oneTime, include specific date
                - "Every 2 hours" → hourly pattern with repeatInterval: 2
                - "Every 15 minutes" → every pattern with repeatInterval: 15, repeatUnit: "Minutes"
                - "Every other week on Monday" → biweekly with repeatDays: "Monday"
                - "Monthly on the 15th" → monthly with monthlyDay: "15"
                - "First Monday of every month" → monthly with monthlyDay: "firstMonday"
                - "Yearly on December 25th" → yearly with month: 12, day: 25
                
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
                """
            }
        )
    }
    
    // MARK: - Session Prewarming
    
    /// Prewarms the session with the instruction prefix for better first-response performance
    /// - Parameter session: The LanguageModelSession to prewarm
    func prewarmSession(session: LanguageModelSession) {
        let prewarmPrefix = "Parse this ticker request and extract all relevant information:"
        session.prewarm(promptPrefix: Prompt(prewarmPrefix))
    }
    
    // MARK: - Parsing Methods
    
    /// Parses user input using Foundation Models (non-streaming)
    /// - Parameters:
    ///   - input: The natural language input to parse
    ///   - session: The active LanguageModelSession
    /// - Returns: A parsed AITickerConfigurationResponse
    /// - Throws: Errors from the Foundation Models API
    func parse(input: String, session: LanguageModelSession) async throws -> AITickerConfigurationResponse {
        guard !session.isResponding else {
            throw FoundationModelsParserError.sessionBusy
        }
        
        let methodStartTime = Date()
        
        let options = GenerationOptions(
            sampling: .greedy, // Deterministic output for final generation
            temperature: 0.3,
            maximumResponseTokens: 500
        )
        
        // Note: includeSchemaInPrompt is true because we want to ensure schema is included
        // The examples in instructions help reduce token usage
        let result = try await session.respond(
            to: Prompt("""
                Parse this ticker/alarm request and extract all information:
                "\(input)"
                """),
            generating: AITickerConfigurationResponse.self,
            includeSchemaInPrompt: true, // Schema already in examples, saves ~200 tokens
            options: options
        )
        
        let methodDuration = Date().timeIntervalSince(methodStartTime)
        print("⏱️ FoundationModelsParser: Model inference completed in \(String(format: "%.2f", methodDuration))s")
        
        return result.content
    }
}

// MARK: - Errors

enum FoundationModelsParserError: LocalizedError {
    case sessionBusy
    
    var errorDescription: String? {
        switch self {
        case .sessionBusy:
            return "Session is currently responding to another request"
        }
    }
}

