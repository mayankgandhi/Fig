//
//  RegenerationRateLimiter.swift
//  fig
//
//  Rate limiting for alarm regeneration to prevent storms
//  Enforces minimum interval between regeneration attempts
//

import Foundation

// MARK: - RegenerationRateLimiter

/// Process-wide rate limiter for alarm regeneration.
///
/// Two problems with the previous implementation:
///
/// 1. `recordRegeneration` wrote through `queue.async(flags: .barrier)`, so the
///    write had not necessarily landed when a different thread called
///    `canRegenerate` — the limiter could be bypassed exactly when regeneration
///    triggers fire close together, which is the case it exists to handle.
/// 2. Its API took `Ticker`, a non-Sendable SwiftData model, and captured it in
///    a `@Sendable` closure that ran on a background queue. SwiftData models are
///    bound to the context that created them.
///
/// It now keys off `UUID` and takes the lock synchronously for reads and writes.
public final class RegenerationRateLimiter: @unchecked Sendable {

    /// Minimum time between regenerations for the same ticker (in seconds)
    private let minimumInterval: TimeInterval = 3600  // 1 hour

    /// Tracks last regeneration time for each ticker ID
    private var lastRegenerationTimes: [UUID: Date] = [:]

    private let lock = NSLock()

    // MARK: - Singleton

    public static let shared = RegenerationRateLimiter()

    private init() {}

    // MARK: - Rate Limiting

    /// Check if regeneration is allowed for a ticker.
    public func canRegenerate(tickerID: UUID, force: Bool = false) -> Bool {
        if force { return true }

        lock.lock(); defer { lock.unlock() }
        guard let lastTime = lastRegenerationTimes[tickerID] else {
            return true  // Never regenerated before
        }
        return Date().timeIntervalSince(lastTime) >= minimumInterval
    }

    /// Record a regeneration attempt. Synchronous: the next `canRegenerate` on
    /// any thread must observe it.
    public func recordRegeneration(for tickerID: UUID) {
        lock.lock(); defer { lock.unlock() }
        lastRegenerationTimes[tickerID] = Date()
    }

    /// Time remaining until regeneration is allowed again, or 0 if allowed now.
    public func timeUntilNextAllowedRegeneration(for tickerID: UUID) -> TimeInterval {
        lock.lock(); defer { lock.unlock() }
        guard let lastTime = lastRegenerationTimes[tickerID] else { return 0 }
        return max(0, minimumInterval - Date().timeIntervalSince(lastTime))
    }

    /// Clear the regeneration history for a ticker.
    public func clearHistory(for tickerID: UUID) {
        lock.lock(); defer { lock.unlock() }
        lastRegenerationTimes.removeValue(forKey: tickerID)
    }

    /// Clear all regeneration history. Useful for testing.
    public func clearAllHistory() {
        lock.lock(); defer { lock.unlock() }
        lastRegenerationTimes.removeAll()
    }

    // MARK: - Debug Information

    public func debugStatus(for tickerID: UUID) -> String {
        let remaining = timeUntilNextAllowedRegeneration(for: tickerID)

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
