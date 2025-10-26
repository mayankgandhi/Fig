//
//  AlarmGenerationStrategy.swift
//  fig
//
//  Defines frequency-based alarm generation strategies
//  Different strategies optimize for different recurrence patterns
//

import Foundation

// MARK: - AlarmGenerationStrategy

enum AlarmGenerationStrategy: Codable, Equatable, Hashable {
    case highFrequency    // Every 5-30 minutes
    case mediumFrequency  // Hourly or every few hours
    case lowFrequency     // Daily or less frequent

    // MARK: - Window Duration

    /// Duration of the generation window
    var windowDuration: TimeInterval {
        switch self {
        case .highFrequency:
            return 24 * 3600  // 24 hours for high-frequency
        case .mediumFrequency:
            return 48 * 3600  // 48 hours for medium-frequency
        case .lowFrequency:
            return 7 * 24 * 3600  // 7 days for low-frequency
        }
    }

    // MARK: - Max Alarms

    /// Maximum number of alarms to generate (prevents overwhelming the system)
    var maxAlarms: Int? {
        switch self {
        case .highFrequency:
            return 100  // Cap high-frequency at 100 alarms
        case .mediumFrequency:
            return nil  // Unlimited for medium-frequency
        case .lowFrequency:
            return nil  // Unlimited for low-frequency
        }
    }

    // MARK: - Regeneration Threshold

    /// How much time before window end should trigger regeneration
    /// This creates a buffer zone to ensure continuous coverage
    var regenerationThreshold: TimeInterval {
        switch self {
        case .highFrequency:
            return 12 * 3600  // Regenerate when < 12 hours remain
        case .mediumFrequency:
            return 24 * 3600  // Regenerate when < 24 hours remain
        case .lowFrequency:
            return 3 * 24 * 3600  // Regenerate when < 3 days remain
        }
    }

    // MARK: - Minimum Alarm Count Threshold

    /// Minimum number of pending alarms before triggering regeneration
    var minimumAlarmCount: Int {
        switch self {
        case .highFrequency:
            return 20  // Regenerate if < 20 alarms for high-frequency
        case .mediumFrequency:
            return 12  // Regenerate if < 12 alarms for medium-frequency
        case .lowFrequency:
            return 3   // Regenerate if < 3 alarms for low-frequency
        }
    }

    // MARK: - Strategy Detection

    /// Automatically determine the appropriate strategy based on a schedule
    static func determineStrategy(for schedule: TickerSchedule) -> AlarmGenerationStrategy {
        switch schedule {
        case .oneTime:
            return .lowFrequency  // One-time alarms don't recur

        case .daily:
            return .lowFrequency  // Once per day

        case .hourly(let interval, _, _):
            if interval == 1 {
                return .mediumFrequency  // Every hour
            } else if interval <= 3 {
                return .mediumFrequency  // Every 2-3 hours
            } else {
                return .lowFrequency  // Every 4+ hours
            }

        case .every(let interval, let unit, _, _):
            switch unit {
            case .minutes:
                if interval <= 30 {
                    return .highFrequency  // Every 5-30 minutes
                } else {
                    return .mediumFrequency  // Every 31+ minutes
                }
            case .hours:
                if interval == 1 {
                    return .mediumFrequency  // Every hour
                } else if interval <= 3 {
                    return .mediumFrequency  // Every 2-3 hours
                } else {
                    return .lowFrequency  // Every 4+ hours
                }
            case .days:
                return .lowFrequency  // Daily or multi-day
            case .weeks:
                return .lowFrequency  // Weekly or multi-week
            }

        case .weekdays:
            return .lowFrequency  // Specific days of the week

        case .biweekly:
            return .lowFrequency  // Every two weeks

        case .monthly:
            return .lowFrequency  // Monthly

        case .yearly:
            return .lowFrequency  // Yearly
        }
    }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .highFrequency:
            return "High Frequency"
        case .mediumFrequency:
            return "Medium Frequency"
        case .lowFrequency:
            return "Low Frequency"
        }
    }

    var description: String {
        switch self {
        case .highFrequency:
            return "Every 5-30 minutes (24h window, max 100 alarms)"
        case .mediumFrequency:
            return "Hourly (48h window, unlimited)"
        case .lowFrequency:
            return "Daily or less (7-day window, unlimited)"
        }
    }
}
