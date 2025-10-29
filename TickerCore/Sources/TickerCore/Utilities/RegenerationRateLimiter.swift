//
//  RegenerationRateLimiter.swift
//  fig
//
//  Rate limiting for alarm regeneration to prevent storms
//  Enforces minimum interval between regeneration attempts
//

import Foundation

// MARK: - RegenerationRateLimiter

@Observable
public class RegenerationRateLimiter {
    /// Minimum time between regenerations for the same ticker (in seconds)
    private let minimumInterval: TimeInterval = 3600  // 1 hour

    /// Tracks last regeneration time for each ticker ID
    private var lastRegenerationTimes: [UUID: Date] = [:]

    /// Thread-safe access queue
    private let queue = DispatchQueue(label: "com.fig.regeneration.ratelimiter", attributes: .concurrent)

    // MARK: - Singleton

    public static let shared = RegenerationRateLimiter()

    private init() {}

    // MARK: - Rate Limiting

    /// Check if regeneration is allowed for a ticker
    /// - Parameters:
    ///   - ticker: The ticker to check
    ///   - force: If true, bypass rate limiting
    /// - Returns: True if regeneration is allowed
    public func canRegenerate(ticker: Ticker, force: Bool = false) -> Bool {
        // Always allow if forced
        if force {
            return true
        }

        return queue.sync {
            guard let lastTime = lastRegenerationTimes[ticker.id] else {
                // Never regenerated before
                return true
            }

            let timeSinceLastRegeneration = Date().timeIntervalSince(lastTime)
            return timeSinceLastRegeneration >= minimumInterval
        }
    }

    /// Record a regeneration attempt for a ticker
    /// - Parameter ticker: The ticker that was regenerated
    public func recordRegeneration(for ticker: Ticker) {
        queue.async(flags: .barrier) {
            self.lastRegenerationTimes[ticker.id] = Date()
        }
    }

    /// Get time remaining until regeneration is allowed again
    /// - Parameter ticker: The ticker to check
    /// - Returns: Time remaining in seconds, or 0 if regeneration is allowed
    public func timeUntilNextAllowedRegeneration(for ticker: Ticker) -> TimeInterval {
        return queue.sync {
            guard let lastTime = lastRegenerationTimes[ticker.id] else {
                return 0  // Never regenerated, so allowed now
            }

            let timeSinceLastRegeneration = Date().timeIntervalSince(lastTime)
            let remaining = minimumInterval - timeSinceLastRegeneration

            return max(0, remaining)
        }
    }

    /// Clear the regeneration history for a ticker
    /// Useful when a ticker is deleted or reset
    /// - Parameter tickerID: The ID of the ticker to clear
    public func clearHistory(for tickerID: UUID) {
        queue.async(flags: .barrier) {
            self.lastRegenerationTimes.removeValue(forKey: tickerID)
        }
    }

    /// Clear all regeneration history
    /// Useful for testing or debugging
    public func clearAllHistory() {
        queue.async(flags: .barrier) {
            self.lastRegenerationTimes.removeAll()
        }
    }

    // MARK: - Debug Information

    /// Get debug information about rate limiting status
    /// - Parameter ticker: The ticker to check
    /// - Returns: Human-readable status string
    public func debugStatus(for ticker: Ticker) -> String {
        let remaining = timeUntilNextAllowedRegeneration(for: ticker)

        if remaining == 0 {
            return "Ready for regeneration"
        } else if remaining < 60 {
            return "Rate limited for \(Int(remaining)) seconds"
        } else {
            let minutes = Int(remaining / 60)
            return "Rate limited for \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}
