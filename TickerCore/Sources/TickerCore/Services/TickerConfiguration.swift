//
//  TickerConfiguration.swift
//  Ticker
//
//  Created by Mayank Gandhi on 27/10/25.
//

import Foundation
import FoundationModels

public struct TickerConfiguration: Equatable {
    public let label: String
    public let time: TimeOfDay
    public let date: Date
    public let repeatOption: AITickerGenerator.RepeatOption
    public let countdown: CountdownConfiguration?
    public let icon: String
    public let colorHex: String

    public struct CountdownConfiguration: Equatable {
        public let hours: Int
        public let minutes: Int
        public let seconds: Int
        
        public init(hours: Int, minutes: Int, seconds: Int) {
            self.hours = hours
            self.minutes = minutes
            self.seconds = seconds
        }
    }
    
    public init(
        label: String,
        time: TimeOfDay,
        date: Date,
        repeatOption: AITickerGenerator.RepeatOption,
        countdown: CountdownConfiguration?,
        icon: String,
        colorHex: String
    ) {
        self.label = label
        self.time = time
        self.date = date
        self.repeatOption = repeatOption
        self.countdown = countdown
        self.icon = icon
        self.colorHex = colorHex
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

    @Guide(.anyOf(["oneTime", "daily", "weekdays", "specificDays", "hourly", "every", "biweekly", "monthly", "yearly"]))
    let repeatPattern: String

    @Guide(description: "For specificDays or biweekly pattern only: comma-separated weekday names (e.g., 'Monday,Wednesday,Friday'). Leave empty or omit for other patterns.")
    let repeatDays: String?

    @Guide(description: "For hourly or every pattern: interval number (e.g., 2 for 'every 2 hours', 15 for 'every 15 minutes'). Omit for other patterns.")
    let repeatInterval: Int?

    @Guide(description: "For every pattern only: time unit - one of 'Minutes', 'Hours', 'Days', 'Weeks'. Omit for other patterns.")
    let repeatUnit: String?

    @Guide(description: "For monthly pattern only: day specification - either a number (1-31) for fixed day, 'firstOfMonth', 'lastOfMonth', or 'firstMonday', 'lastFriday' etc. for weekday patterns. Omit for other patterns.")
    let monthlyDay: String?

    @Guide(description: "Number of hours for countdown before alarm (0-23). Omit or use 0 if no countdown mentioned.")
    let countdownHours: Int?

    @Guide(description: "Number of minutes for countdown before alarm (0-59). Omit or use 0 if no countdown mentioned.")
    let countdownMinutes: Int?

    @Guide(description: "SF Symbol icon name that represents the activity (e.g., 'sunrise.fill', 'pills.fill', 'person.2.fill', 'dumbbell.fill')")
    let icon: String

    @Guide(description: "Hex color code for the ticker without # prefix (e.g., 'FF6B6B' for red, '4ECDC4' for teal)")
    let colorHex: String
}

