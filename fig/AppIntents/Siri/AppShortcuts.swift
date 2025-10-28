//
//  AppShortcuts.swift
//  fig
//
//  App Shortcuts configuration for Siri voice commands
//

import AppIntents

/// App Shortcuts configuration for Ticker
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateAlarmIntent(),
            phrases: [
                "Set a ticker for 8am tomorrow morning to wake up",
                "Create my morning ticker",
                "Set a ticker",
                "Add a wake-up ticker",
                "Create ticker",
                "Set ticker alarm",
                "Make a ticker",
                "Set a gentle ticker for 7am",
                "Create a bedtime ticker with nature sounds"
            ],
            shortTitle: "Create Ticker",
            systemImageName: "alarm"
        )
    }
}
