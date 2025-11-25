//
//  CompositeConfiguration.swift
//  TickerCore
//
//  Created by Claude Code
//

import Foundation

/// Configuration data for different composite ticker types
public enum CompositeConfiguration: Codable, Sendable {
    case sleepSchedule(SleepScheduleConfiguration)
    // Future: case medicationSchedule(MedicationConfiguration)
    // Future: case mealPlan(MealPlanConfiguration)
}

/// Configuration for sleep schedule composite tickers
public struct SleepScheduleConfiguration: Codable, Sendable {
    public var bedtime: TimeOfDay
    public var wakeTime: TimeOfDay
    public var sleepGoalHours: Double

    public init(bedtime: TimeOfDay, wakeTime: TimeOfDay, sleepGoalHours: Double = 8.0) {
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.sleepGoalHours = sleepGoalHours
    }

    /// Calculate sleep duration in hours
    public var sleepDuration: Double {
        let bedtimeMinutes = bedtime.hour * 60 + bedtime.minute
        let wakeMinutes = wakeTime.hour * 60 + wakeTime.minute

        var duration: Int
        if wakeMinutes >= bedtimeMinutes {
            // Same day (e.g., 10 AM bedtime, 6 PM wake - unusual but supported)
            duration = wakeMinutes - bedtimeMinutes
        } else {
            // Crosses midnight (normal case: 10 PM bedtime, 6 AM wake)
            duration = (24 * 60) - bedtimeMinutes + wakeMinutes
        }

        return Double(duration) / 60.0
    }

    /// Check if sleep duration meets the goal
    public var meetsGoal: Bool {
        return sleepDuration >= sleepGoalHours
    }

    /// Formatted sleep duration string (e.g., "7 hr 25 min")
    public var formattedDuration: String {
        let totalMinutes = Int(sleepDuration * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours) hr"
        } else {
            return "\(hours) hr \(minutes) min"
        }
    }
}
