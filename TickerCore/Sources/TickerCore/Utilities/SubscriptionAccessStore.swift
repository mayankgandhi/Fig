//
//  SubscriptionAccessStore.swift
//  TickerCore
//
//  Persists the user’s premium access state in the shared App Group so
//  extensions (widgets, live activities, etc.) can read a consistent view
//  without having to re-fetch entitlements synchronously.
//

import Foundation

public enum SubscriptionAccessStore {
    private static let appGroupIdentifier = "group.m.fig"
    private static let statusKey = "subscription.isSubscribed"
    private static let lastUpdatedKey = "subscription.lastUpdated"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    /// Persist the latest subscription entitlement state.
    /// - Parameters:
    ///   - isSubscribed: Current entitlement result.
    ///   - timestamp: Optional timestamp for debugging/analytics.
    public static func setIsSubscribed(_ isSubscribed: Bool, timestamp: Date = Date()) {
        let defaults = sharedDefaults
        defaults.set(isSubscribed, forKey: statusKey)
        defaults.set(timestamp, forKey: lastUpdatedKey)
    }

    /// Read the last known entitlement state saved by the main app or extensions.
    /// - Returns: `true` if the cached value indicates the user is subscribed.
    public static func isUserSubscribed() -> Bool {
        sharedDefaults.bool(forKey: statusKey)
    }

    /// Read the timestamp for the last persisted entitlement update.
    public static func lastUpdatedDate() -> Date? {
        sharedDefaults.object(forKey: lastUpdatedKey) as? Date
    }
}

