//
//  OpenAITickerService.swift
//  fig
//
//  Service for generating ticker configurations using OpenAI's API
//

import Foundation
import OpenAI

/// Service that uses OpenAI to generate ticker configurations from natural language
public final class OpenAITickerService {
    private let client: OpenAI

    /// Initialize the service with an API key
    /// - Parameter apiKey: OpenAI API key
    public init(apiKey: String) {
        self.client = OpenAI(apiToken: apiKey)
    }

    /// Generate a ticker configuration from natural language prompt
    /// - Parameter prompt: Natural language description of the alarm
    /// - Returns: A configured `LLKTickerConfig` ready to be converted to a `Ticker`
    /// - Throws: Any errors from the OpenAI API or parsing
    public func generateTickerConfig(from prompt: String) async throws -> LLKTickerConfig {
        // Build the chat messages
        let systemMessage = ChatQuery.ChatCompletionMessageParam.system(
            ChatQuery.ChatCompletionMessageParam.SystemMessageParam(
                content: ChatQuery.ChatCompletionMessageParam.TextContent.textContent(
            """
            You are a helpful assistant that creates alarm/ticker configurations from natural language.
            Parse the user's request and extract all relevant alarm details including time, date, repeat pattern, countdown, icon, and color.
            Always respond with a valid JSON object matching the provided schema.
            
            For Label:
            - Keep the label short and concise
            
            For dates:
            - Use Date format "yyyy-MM-dd'T'HH:mm:ss"
            - If not specified, use today's date with the specified time
            - Compute date appropriately if mentioned terms like tomorrow, next week, etc
            
            For repeat patterns:
            - oneTime: Single alarm, no repetition
            - daily: Every day at the same time
            - weekdays: Specific days of the week (weekdays array: 0=Sunday, 1=Monday, etc.)
            - hourly: Every N hours (requires interval)
            - every: Custom interval (requires interval and unit: Minutes, Hours, Days, Weeks)
            - biweekly: Every two weeks on specific days (requires weekdays array)
            - monthly: Monthly on specific day (requires monthlyDay configuration)
            - yearly: Once per year (requires month and day)
            
            For icons:
            - Use SF Symbol names (e.g., "sunrise.fill", "pills.fill")
            - Choose icons that match the activity
            
            For colors:
            - Provide hex color codes without # prefix
            - Choose colors that match the activity mood
            """
                )
            )
        )
        
        let userMessage = ChatQuery.ChatCompletionMessageParam.user(ChatQuery.ChatCompletionMessageParam.UserMessageParam(
            content: .string(prompt)
        )) 
        

        // Create the structured output request
        let query = ChatQuery(
            messages: [systemMessage, userMessage],
            model: .gpt4_1_mini,
            responseFormat: .jsonSchema(
                .init(
                    name: "ticker_configuration",
                    schema: .derivedJsonSchema(LLKTickerConfig.self),
                    strict: true
                )
            )
        )

        // Execute the API call
        let result = try await client.chats(query: query)

        // Extract the response content
        guard let responseContent = result.choices.first?.message.content else {
            throw OpenAIServiceError.noResponse
        }
        
        // Parse the JSON string into LLKTickerConfig
        guard let jsonData = responseContent.data(using: .utf8) else {
            throw OpenAIServiceError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let config = try decoder.decode(LLKTickerConfig.self, from: jsonData)
            dump(config)
            return config
        } catch {
            dump(error)
            throw OpenAIServiceError.decodingFailed(error)
        }
    }

}

// MARK: - OpenAIServiceError

public enum OpenAIServiceError: LocalizedError {
    case noResponse
    case invalidResponse
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response received from OpenAI"
        case .invalidResponse:
            return "Invalid response format from OpenAI"
        case .decodingFailed(let error):
            return "Failed to decode ticker configuration: \(error.localizedDescription)"
        }
    }
}
