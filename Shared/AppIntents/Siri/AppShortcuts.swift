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
                "Set a ${applicationName} for 8am tomorrow morning to wake up",
                "Create my morning ${applicationName}",
                "Set a ${applicationName}",
                "Add a wake-up ${applicationName}",
                "Create ${applicationName}",
                "Set ${applicationName} alarm",
                "Make a ${applicationName}",
                "Set a gentle ${applicationName} for 7am",
                "Create a bedtime ${applicationName} with nature sounds"
            ],
            shortTitle: "Create Ticker",
            systemImageName: "alarm"
        )
    }
}
