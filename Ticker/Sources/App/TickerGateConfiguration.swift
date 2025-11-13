import SwiftUI
import Gate
import TickerCore

extension PremiumFeature {
    static let aiAlarmCreation = PremiumFeature(
        id: "ai_alarm_creation",
        title: "AI-Powered Alarm Creation",
        description: "Describe alarms in plain language and let Ticker build them for you.",
        instruction: "Tickers can be added manually in the Scheduled Tab, Tap on + button and add a Ticker directly",
        icon: "sparkles"
    )

    static let lockScreenCountdowns = PremiumFeature(
        id: "lock_screen_countdowns",
        title: "Countdowns on Lock Screen + Dynamic Island",
        description: "Keep countdowns visible on your Lock Screen and Dynamic Island.",
        icon: "iphone"
    )

    static let unlimitedCustomSchedules = PremiumFeature(
        id: "unlimited_custom_schedules",
        title: "Unlimited Alarms + Custom Schedules",
        description: "Stack unlimited alarms with fully customizable routines.",
        icon: "alarm.fill"
    )

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
                .aiAlarmCreation,
                .lockScreenCountdowns,
                .unlimitedCustomSchedules,
                .accountabilityWidgets,
            ],
            accentColor: TickerColor.primary,
            premiumGradient: [
                TickerColor.primary,
                TickerColor.accent
            ],
            confirmationTitle: "Welcome to Ticker Pro!"
        )
    }
}
