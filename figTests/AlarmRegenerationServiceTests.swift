//
//  AlarmRegenerationServiceTests.swift
//  figTests
//
//  Unit tests for AlarmRegenerationService
//  Tests diff calculation, rate limiting, health monitoring, and regeneration logic
//

import XCTest
import SwiftData
@testable import Ticker

final class AlarmRegenerationServiceTests: XCTestCase {
    var service: AlarmRegenerationService!
    var rateLimiter: RegenerationRateLimiter!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()

        // Create in-memory model container for testing
        let schema = Schema([Ticker.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)

        // Initialize services
        rateLimiter = RegenerationRateLimiter.shared
        service = AlarmRegenerationService(rateLimiter: rateLimiter)

        // Clear rate limiter history
        rateLimiter.clearAllHistory()
    }

    override func tearDown() {
        service = nil
        rateLimiter = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Rate Limiting Tests

    func testRateLimiting_AllowsFirstRegeneration() {
        let ticker = createTestTicker()

        // First regeneration should be allowed
        let canRegenerate = rateLimiter.canRegenerate(ticker: ticker, force: false)
        XCTAssertTrue(canRegenerate, "First regeneration should be allowed")
    }

    func testRateLimiting_BlocksImmediateRegeneration() {
        let ticker = createTestTicker()

        // Record a regeneration
        rateLimiter.recordRegeneration(for: ticker)

        // Immediate regeneration should be blocked
        let canRegenerate = rateLimiter.canRegenerate(ticker: ticker, force: false)
        XCTAssertFalse(canRegenerate, "Immediate regeneration should be blocked")
    }

    func testRateLimiting_AllowsForceRegeneration() {
        let ticker = createTestTicker()

        // Record a regeneration
        rateLimiter.recordRegeneration(for: ticker)

        // Force regeneration should bypass rate limiting
        let canRegenerate = rateLimiter.canRegenerate(ticker: ticker, force: true)
        XCTAssertTrue(canRegenerate, "Force regeneration should bypass rate limiting")
    }

    func testRateLimiting_TimeRemainingCalculation() {
        let ticker = createTestTicker()

        // Record a regeneration
        rateLimiter.recordRegeneration(for: ticker)

        // Check time remaining
        let timeRemaining = rateLimiter.timeUntilNextAllowedRegeneration(for: ticker)
        XCTAssertGreaterThan(timeRemaining, 0, "Should have time remaining")
        XCTAssertLessThanOrEqual(timeRemaining, 3600, "Should be less than 1 hour")
    }

    func testRateLimiting_ClearHistory() {
        let ticker = createTestTicker()

        // Record a regeneration
        rateLimiter.recordRegeneration(for: ticker)
        XCTAssertFalse(rateLimiter.canRegenerate(ticker: ticker, force: false))

        // Clear history
        rateLimiter.clearHistory(for: ticker.id)

        // Should now be allowed
        XCTAssertTrue(rateLimiter.canRegenerate(ticker: ticker, force: false))
    }

    // MARK: - Health Calculation Tests

    func testHealthCalculation_InitialState() {
        let ticker = createTestTicker()
        let health = ticker.alarmHealthStatus

        XCTAssertEqual(health.status, .critical, "Initial ticker should have critical health")
        XCTAssertNil(health.lastRegenerationDate, "Should have no last regeneration date")
        XCTAssertFalse(health.lastRegenerationSuccess, "Should have no successful regeneration")
        XCTAssertEqual(health.activeAlarmCount, 0, "Should have no active alarms")
    }

    func testHealthCalculation_HealthyState() {
        let ticker = createTestTicker()

        // Simulate successful regeneration
        ticker.lastRegenerationDate = Date()
        ticker.lastRegenerationSuccess = true
        ticker.generatedAlarmKitIDs = [UUID(), UUID(), UUID()]

        let health = ticker.alarmHealthStatus

        XCTAssertEqual(health.status, .healthy, "Should be healthy after successful regeneration")
        XCTAssertEqual(health.activeAlarmCount, 3, "Should have 3 active alarms")
    }

    func testHealthCalculation_WarningState() {
        let ticker = createTestTicker()

        // Simulate stale regeneration (25 hours ago)
        ticker.lastRegenerationDate = Date().addingTimeInterval(-25 * 3600)
        ticker.lastRegenerationSuccess = true
        ticker.generatedAlarmKitIDs = [UUID(), UUID()]

        let health = ticker.alarmHealthStatus

        XCTAssertEqual(health.status, .warning, "Should be warning when stale > 24h")
        XCTAssertGreaterThan(health.staleness, 24 * 3600, "Staleness should be > 24 hours")
    }

    func testHealthCalculation_CriticalState_Failed() {
        let ticker = createTestTicker()

        // Simulate failed regeneration
        ticker.lastRegenerationDate = Date()
        ticker.lastRegenerationSuccess = false
        ticker.generatedAlarmKitIDs = []

        let health = ticker.alarmHealthStatus

        XCTAssertEqual(health.status, .critical, "Should be critical when regeneration failed")
    }

    func testHealthCalculation_CriticalState_NoAlarms() {
        let ticker = createTestTicker()

        // Simulate successful regeneration but no alarms
        ticker.lastRegenerationDate = Date()
        ticker.lastRegenerationSuccess = true
        ticker.generatedAlarmKitIDs = []

        let health = ticker.alarmHealthStatus

        XCTAssertEqual(health.status, .critical, "Should be critical when no alarms scheduled")
    }

    // MARK: - Regeneration Decision Tests

    func testShouldRegenerate_NeverRegenerated() {
        let ticker = createTestTicker()
        ticker.isEnabled = true
        ticker.lastRegenerationDate = nil

        let shouldRegenerate = service.shouldRegenerate(ticker: ticker)

        XCTAssertTrue(shouldRegenerate, "Should regenerate if never regenerated before")
    }

    func testShouldRegenerate_LastRegenerationFailed() {
        let ticker = createTestTicker()
        ticker.isEnabled = true
        ticker.lastRegenerationDate = Date()
        ticker.lastRegenerationSuccess = false

        let shouldRegenerate = service.shouldRegenerate(ticker: ticker)

        XCTAssertTrue(shouldRegenerate, "Should regenerate if last regeneration failed")
    }

    func testShouldRegenerate_Stale() {
        let ticker = createTestTicker()
        ticker.isEnabled = true
        ticker.lastRegenerationDate = Date().addingTimeInterval(-25 * 3600) // 25 hours ago
        ticker.lastRegenerationSuccess = true

        let shouldRegenerate = service.shouldRegenerate(ticker: ticker)

        XCTAssertTrue(shouldRegenerate, "Should regenerate if stale > regeneration threshold")
    }

    func testShouldRegenerate_ScheduledTimeReached() {
        let ticker = createTestTicker()
        ticker.isEnabled = true
        ticker.lastRegenerationDate = Date()
        ticker.lastRegenerationSuccess = true
        ticker.nextScheduledRegeneration = Date().addingTimeInterval(-60) // 1 minute ago

        let shouldRegenerate = service.shouldRegenerate(ticker: ticker)

        XCTAssertTrue(shouldRegenerate, "Should regenerate if scheduled regeneration time passed")
    }

    func testShouldRegenerate_DisabledTicker() {
        let ticker = createTestTicker()
        ticker.isEnabled = false
        ticker.lastRegenerationDate = nil

        let shouldRegenerate = service.shouldRegenerate(ticker: ticker)

        XCTAssertFalse(shouldRegenerate, "Should not regenerate disabled tickers")
    }

    func testShouldRegenerate_RecentlyRegenerated() {
        let ticker = createTestTicker()
        ticker.isEnabled = true
        ticker.lastRegenerationDate = Date().addingTimeInterval(-300) // 5 minutes ago
        ticker.lastRegenerationSuccess = true
        ticker.nextScheduledRegeneration = Date().addingTimeInterval(24 * 3600) // Tomorrow

        let shouldRegenerate = service.shouldRegenerate(ticker: ticker)

        XCTAssertFalse(shouldRegenerate, "Should not regenerate if recently regenerated and healthy")
    }

    // MARK: - Strategy Detection Tests

    func testStrategyDetection_HighFrequency() {
        let schedule = TickerSchedule.every(interval: 10, unit: .minutes, time: TickerSchedule.TimeOfDay(hour: 9, minute: 0))
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .highFrequency, "10-minute interval should be high frequency")
    }

    func testStrategyDetection_MediumFrequency() {
        let schedule = TickerSchedule.hourly(interval: 1, time: TickerSchedule.TimeOfDay(hour: 9, minute: 0))
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .mediumFrequency, "Hourly interval should be medium frequency")
    }

    func testStrategyDetection_LowFrequency() {
        let time = TickerSchedule.TimeOfDay(hour: 9, minute: 0)
        let schedule = TickerSchedule.daily(time: time)
        let strategy = AlarmGenerationStrategy.determineStrategy(for: schedule)

        XCTAssertEqual(strategy, .lowFrequency, "Daily alarm should be low frequency")
    }

    // MARK: - AlarmHealth Utility Tests

    func testAlarmHealth_StatusMessages() {
        // Healthy
        let healthy = AlarmHealth.healthy(alarmCount: 5)
        XCTAssertEqual(healthy.statusMessage, "All alarms are up to date")

        // Failed
        let failed = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: false,
            activeAlarmCount: 0
        )
        XCTAssertEqual(failed.statusMessage, "Last alarm update failed")

        // Never regenerated
        let initial = AlarmHealth.initial()
        XCTAssertEqual(initial.statusMessage, "Alarms need to be configured")
    }

    func testAlarmHealth_LastUpdatedDescription() {
        // Just now
        let justNow = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )
        XCTAssertEqual(justNow.lastUpdatedDescription, "Just now")

        // Minutes ago
        let minutesAgo = AlarmHealth(
            lastRegenerationDate: Date().addingTimeInterval(-5 * 60),
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )
        XCTAssertTrue(minutesAgo.lastUpdatedDescription.contains("minute"))

        // Hours ago
        let hoursAgo = AlarmHealth(
            lastRegenerationDate: Date().addingTimeInterval(-2 * 3600),
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )
        XCTAssertTrue(hoursAgo.lastUpdatedDescription.contains("hour"))

        // Days ago
        let daysAgo = AlarmHealth(
            lastRegenerationDate: Date().addingTimeInterval(-25 * 3600),
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )
        XCTAssertTrue(daysAgo.lastUpdatedDescription.contains("day"))
    }

    // MARK: - Integration Tests

    func testRegenerationWorkflow_EndToEnd() async throws {
        let ticker = createTestTicker()
        ticker.isEnabled = true
        ticker.schedule = .daily(time: .init(hour: 9, minute: 0))

        modelContext.insert(ticker)
        try modelContext.save()

        // Initial state: should need regeneration
        XCTAssertTrue(ticker.needsRegeneration, "New ticker should need regeneration")
        XCTAssertEqual(ticker.alarmHealthStatus.status, .critical)

        // Note: We can't fully test regeneration without mocking AlarmKit
        // But we can verify the decision logic works correctly
        XCTAssertTrue(service.shouldRegenerate(ticker: ticker))
        XCTAssertTrue(rateLimiter.canRegenerate(ticker: ticker, force: false))
    }

    // MARK: - Helper Methods

    private func createTestTicker() -> Ticker {
        return Ticker(
            id: UUID(),
            label: "Test Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            countdown: nil,
            presentation: .init(),
            tickerData: nil
        )
    }
}
