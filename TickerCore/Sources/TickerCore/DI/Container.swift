//
//  Container.swift
//  TickerCore
//
//  Factory dependency injection container for all services
//

import Foundation
import Factory
import SwiftData
import AlarmKit

// MARK: - Container Extension

public extension Container {

    // MARK: - AlarmKit Services

    var alarmManager: Factory<AlarmManager> {
        self { AlarmManager.shared }
            .singleton
    }

    var alarmConfigurationBuilder: Factory<AlarmConfigurationBuilderProtocol> {
        self { AlarmConfigurationBuilder() }
        // Pure transformation functions - no state, no need for singleton
    }

    var alarmStateManager: Factory<AlarmStateManagerProtocol> {
        self { AlarmStateManager() }
            .singleton
    }

    var alarmSynchronizationService: Factory<AlarmSynchronizationServiceProtocol> {
        self { AlarmSynchronizationService() }
            .singleton
    }

    var alarmRegenerationService: Factory<AlarmRegenerationServiceProtocol> {
        self { AlarmRegenerationService() }
            .singleton
    }

    // MARK: - Core Services

    var tickerService: Factory<TickerService> {
        self { TickerService() }
            .singleton
    }

    var tickerCollectionService: Factory<TickerCollectionService> {
        self { TickerCollectionService() }
            .singleton
    }

    // MARK: - AI Services

    var aiTickerGenerator: Factory<AITickerGenerator> {
        self { @MainActor in
            AITickerGenerator()
        }
        .singleton
    }

    var aiSessionManager: Factory<AISessionManager> {
        self { @MainActor in
            AISessionManager.shared
        }
        .singleton
    }

    var foundationModelsParser: Factory<FoundationModelsParser> {
        self { FoundationModelsParser() }
        // Stateless session creator - no need for singleton
    }

    // MARK: - Data Services

    var modelContextObserver: Factory<ModelContextObserver> {
        self { @MainActor in
            ModelContextObserver()
        }
        .singleton
    }

    var widgetDataFetcher: Factory<WidgetDataFetcher> {
        self { WidgetDataFetcher() }
            .singleton
    }

    // MARK: - Utilities

    var tickerScheduleExpander: Factory<TickerScheduleExpander> {
        self { TickerScheduleExpander() }
        // Pure schedule expansion logic - no state, no need for singleton
    }

    var regenerationRateLimiter: Factory<RegenerationRateLimiter> {
        self { RegenerationRateLimiter.shared }
            .singleton
    }

    var tickerConfigurationParser: Factory<TickerConfigurationParser> {
        self { TickerConfigurationParser() }
        // Stateless parsing operations - no need for singleton
    }

    // MARK: - Setup

    /// Initialize the Factory container with all dependencies
    /// Call this at app launch before any services are used
    static func setupDependencies() {
        // Registrations are lazy by default
        // This method can be used for any special initialization
        print("✅ Factory container initialized")
    }
}
