//
//  RegenerationRateLimiterTests.swift
//  TickerCoreTests
//
//  Comprehensive tests for RegenerationRateLimiter
//

import XCTest
@testable import TickerCore

final class RegenerationRateLimiterTests: XCTestCase {

    var limiter: RegenerationRateLimiter!

    override func setUp() {
        super.setUp()
        limiter = RegenerationRateLimiter.shared
        // Clear all history before each test
        limiter.clearAllHistory()
        // Give it a moment to process the async clear
        Thread.sleep(forTimeInterval: 0.1)
    }

    override func tearDown() {
        limiter.clearAllHistory()
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let limiter1 = RegenerationRateLimiter.shared
        let limiter2 = RegenerationRateLimiter.shared

        XCTAssertTrue(limiter1 === limiter2, "Shared should return the same instance")
    }

    // MARK: - First Regeneration Tests

    func testCanRegenerateFirstTime() {
        let ticker = createTestTicker()

        let canRegenerate = limiter.canRegenerate(ticker: ticker)

        XCTAssertTrue(canRegenerate, "Should allow first regeneration")
    }

    func testTimeUntilNextAllowedRegenerationFirstTime() {
        let ticker = createTestTicker()

        let timeRemaining = limiter.timeUntilNextAllowedRegeneration(for: ticker)

        XCTAssertEqual(timeRemaining, 0, "Should have no wait time for first regeneration")
    }

    // MARK: - Rate Limiting Tests

    func testCannotRegenerateImmediately() {
        let ticker = createTestTicker()

        limiter.recordRegeneration(for: ticker)
        Thread.sleep(forTimeInterval: 0.1) // Wait for async operation

        let canRegenerate = limiter.canRegenerate(ticker: ticker)

        XCTAssertFalse(canRegenerate, "Should not allow immediate regeneration")
    }

    func testTimeRemainingAfterRegeneration() {
        let ticker = createTestTicker()

        limiter.recordRegeneration(for: ticker)
        Thread.sleep(forTimeInterval: 0.1) // Wait for async operation

        let timeRemaining = limiter.timeUntilNextAllowedRegeneration(for: ticker)

        XCTAssertGreaterThan(timeRemaining, 0, "Should have wait time after regeneration")
        XCTAssertLessThanOrEqual(timeRemaining, 3600, "Wait time should not exceed 1 hour")
    }

    // MARK: - Force Regeneration Tests

    func testForceRegenerationBypasses RateLimit() {
        let ticker = createTestTicker()

        limiter.recordRegeneration(for: ticker)
        Thread.sleep(forTimeInterval: 0.1)

        let canRegenerate = limiter.canRegenerate(ticker: ticker, force: true)

        XCTAssertTrue(canRegenerate, "Force flag should bypass rate limiting")
    }

    // MARK: - Multiple Tickers Tests

    func testDifferentTickersRateLimitedSeparately() {
        let ticker1 = createTestTicker()
        let ticker2 = createTestTicker()

        limiter.recordRegeneration(for: ticker1)
        Thread.sleep(forTimeInterval: 0.1)

        let canRegenerate1 = limiter.canRegenerate(ticker: ticker1)
        let canRegenerate2 = limiter.canRegenerate(ticker: ticker2)

        XCTAssertFalse(canRegenerate1, "Ticker1 should be rate limited")
        XCTAssertTrue(canRegenerate2, "Ticker2 should not be rate limited")
    }

    // MARK: - History Clearing Tests

    func testClearHistoryForSpecificTicker() {
        let ticker = createTestTicker()

        limiter.recordRegeneration(for: ticker)
        Thread.sleep(forTimeInterval: 0.1)

        limiter.clearHistory(for: ticker.id)
        Thread.sleep(forTimeInterval: 0.1)

        let canRegenerate = limiter.canRegenerate(ticker: ticker)

        XCTAssertTrue(canRegenerate, "Should allow regeneration after clearing history")
    }

    func testClearAllHistory() {
        let ticker1 = createTestTicker()
        let ticker2 = createTestTicker()

        limiter.recordRegeneration(for: ticker1)
        limiter.recordRegeneration(for: ticker2)
        Thread.sleep(forTimeInterval: 0.1)

        limiter.clearAllHistory()
        Thread.sleep(forTimeInterval: 0.1)

        let canRegenerate1 = limiter.canRegenerate(ticker: ticker1)
        let canRegenerate2 = limiter.canRegenerate(ticker: ticker2)

        XCTAssertTrue(canRegenerate1, "Ticker1 should allow regeneration after clearing all")
        XCTAssertTrue(canRegenerate2, "Ticker2 should allow regeneration after clearing all")
    }

    // MARK: - Debug Status Tests

    func testDebugStatusReady() {
        let ticker = createTestTicker()

        let status = limiter.debugStatus(for: ticker)

        XCTAssertEqual(status, "Ready for regeneration")
    }

    func testDebugStatusRateLimited() {
        let ticker = createTestTicker()

        limiter.recordRegeneration(for: ticker)
        Thread.sleep(forTimeInterval: 0.1)

        let status = limiter.debugStatus(for: ticker)

        XCTAssertTrue(status.contains("Rate limited"), "Status should indicate rate limiting")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess() {
        let ticker = createTestTicker()
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 100

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = limiter.canRegenerate(ticker: ticker)
            limiter.recordRegeneration(for: ticker)
            _ = limiter.timeUntilNextAllowedRegeneration(for: ticker)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        // If we get here without crashing, thread safety is working
    }

    // MARK: - Helper Methods

    private func createTestTicker() -> Ticker {
        return Ticker(
            label: "Test Ticker",
            tickerData: TickerData(
                schedule: .fixed(Date()),
                sound: .default,
                countdown: nil,
                tint: .orange,
                message: nil,
                isVibrationEnabled: true
            )
        )
    }
}
