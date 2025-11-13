//
//  WidgetSubscriptionConfig.swift
//  TickerWidgets
//
//  Subscription service configuration for widget extension
//

import Gate
import SwiftUI

extension PremiumFeature {
    static let accountabilityWidgets = PremiumFeature(
        id: "accountability_widgets",
        title: "Widgets That Judge You",
        description: "Stay accountable with widgets that surface your progress everywhere.",
        icon: "rectangle.grid.2x2.fill"
    )
}

extension GateConfiguration {
    static var ticker: GateConfiguration {
        GateConfiguration(
            appName: "Ticker",
            premiumBrandName: "Ticker Pro",
            revenueCatAPIKey: "appl_nfxOwnGvDtrPbpmfRRcIyksfrgB",
            premiumFeatures: [
                .accountabilityWidgets,
            ],
            accentColor: .blue,
            premiumGradient: [
                Color.blue,
                Color.purple
            ]
        )
    }
}

enum WidgetSubscriptionConfig {
    /// Get or create a consistent user ID shared between app and widget extension
    private static func getUserID() -> String {
        let sharedDefaults = UserDefaults(suiteName: "group.m.fig")
        let key = "revenueCatUserID"

        if let existingID = sharedDefaults?.string(forKey: key) {
            return existingID
        }

        // Generate new ID and store it
        let newID = UUID().uuidString
        sharedDefaults?.set(newID, forKey: key)
        return newID
    }

    static func configure() {
        // Configure SubscriptionService for widget extension
        SubscriptionService.shared.configure(
            configuration: .ticker,
            userIDProvider: { getUserID() }
        )
    }
}

