//
//  WidgetPremiumAccessResolver.swift
//  TickerWidgets
//
//  Centralizes the logic for determining whether widget content should be
//  gated behind the Pro paywall. The resolver uses the live subscription
//  service when available and falls back to the cached App Group value so
//  paid users continue to see content even before entitlements finish loading.
//

import Gate
import TickerCore

enum WidgetPremiumAccessResolver {
    static func hasAccess(for entry: AlarmTimelineEntry) -> Bool {
        if entry.isPreview {
            return true
        }

        if SubscriptionService.shared.isSubscribed {
            return true
        }

        return SubscriptionAccessStore.isUserSubscribed()
    }
}

