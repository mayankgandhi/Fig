//
//  Container+OpenAI.swift
//  Ticker
//
//  Container extension for OpenAI service registration
//

import Foundation
import Factory
import Telemetry

extension Container {
    // MARK: - OpenAI Service
    
    var openAITickerService: Factory<OpenAITickerService> {
        self {
            // Fetch OpenAI API key from PostHog feature flag
            // Using a semaphore to make async call synchronous for Factory resolution
            let semaphore = DispatchSemaphore(value: 0)
            var apiKey: String?
            
            Task {
                apiKey = await TelemetryService.shared.getFeatureFlagPayloadString(key: "openai-api-key")
                semaphore.signal()
            }
            
            semaphore.wait()
            
            guard let apiKey = apiKey, !apiKey.isEmpty else {
                fatalError("Failed to retrieve OpenAI API key from PostHog feature flag 'openai_api_key'")
            }
            
            return OpenAITickerService(apiKey: apiKey)
        }
        .singleton
    }
}

