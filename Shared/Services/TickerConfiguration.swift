//
//  TickerConfiguration.swift
//  Ticker
//
//  Created by Mayank Gandhi on 27/10/25.
//

import Foundation
import FoundationModels

struct TickerConfiguration: Equatable {
    let label: String
    let time: TimeOfDay
    let date: Date
    let repeatOption: AITickerGenerator.RepeatOption
    let countdown: CountdownConfiguration?
    let icon: String
    let colorHex: String

    struct TimeOfDay: Equatable {
        let hour: Int
        let minute: Int
    }

    struct CountdownConfiguration: Equatable {
        let hours: Int
        let minutes: Int
        let seconds: Int
    }
}

// Foundation Models compatible configuration using only simple types
@Generable
struct AITickerConfigurationResponse: Equatable {
    @Guide(description: "A short, descriptive label for the activity or reminder (e.g., 'Morning Yoga', 'Take Medication', 'Team Meeting')")
    let label: String

    @Guide(description: "Hour in 24-hour format (0-23)")
    let hour: Int

    @Guide(description: "Minute (0-59)")
    let minute: Int

    @Guide(description: "Year (e.g., 2025). If not specified in the user's request, use the current year.")
    let year: Int?

    @Guide(description: "Month (1-12). If not specified in the user's request, use the current month.")
    let month: Int?

    @Guide(description: "Day of month (1-31). If not specified in the user's request, use today's day.")
    let day: Int?

    @Guide(.anyOf(["oneTime", "daily", "weekdays", "specificDays"]))
    let repeatPattern: String

    @Guide(description: "For specificDays pattern only: comma-separated weekday names (e.g., 'Monday,Wednesday,Friday'). Leave empty or omit for other patterns.")
    let repeatDays: String?

    @Guide(description: "Number of hours for countdown before alarm (0-23). Omit or use 0 if no countdown mentioned.")
    let countdownHours: Int?

    @Guide(description: "Number of minutes for countdown before alarm (0-59). Omit or use 0 if no countdown mentioned.")
    let countdownMinutes: Int?

    @Guide(description: "SF Symbol icon name that represents the activity (e.g., 'sunrise.fill', 'pills.fill', 'person.2.fill', 'dumbbell.fill')")
    let icon: String

    @Guide(description: "Hex color code for the ticker without # prefix (e.g., 'FF6B6B' for red, '4ECDC4' for teal)")
    let colorHex: String
}

