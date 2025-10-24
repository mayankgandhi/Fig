//
//  UpcomingAlarmPresentation.swift
//  fig
//
//  View-ready representation of an upcoming alarm with pre-calculated values
//  Shared between main app and widget extension
//

import Foundation
import SwiftUI

// MARK: - Presentation Model

/// View-ready representation of an upcoming alarm with pre-calculated values
struct UpcomingAlarmPresentation: Identifiable, Equatable {
    let id: UUID
    let baseAlarmId: UUID
    let displayName: String
    let icon: String
    let color: Color
    let nextAlarmTime: Date
    let scheduleType: ScheduleType
    let hour: Int
    let minute: Int

    // Optional metadata
    let hasCountdown: Bool
    let tickerDataTitle: String?
    
    /// Initialize with unique ID generation
    init(baseAlarmId: UUID, displayName: String, icon: String, color: Color, nextAlarmTime: Date, scheduleType: ScheduleType, hour: Int, minute: Int, hasCountdown: Bool, tickerDataTitle: String?) {
        self.baseAlarmId = baseAlarmId
        self.displayName = displayName
        self.icon = icon
        self.color = color
        self.nextAlarmTime = nextAlarmTime
        self.scheduleType = scheduleType
        self.hour = hour
        self.minute = minute
        self.hasCountdown = hasCountdown
        self.tickerDataTitle = tickerDataTitle
        
        // Generate unique ID by combining baseAlarmId and nextAlarmTime
        let combinedString = "\(baseAlarmId.uuidString)-\(nextAlarmTime.timeIntervalSince1970)"
        self.id = UUID(uuidString: combinedString) ?? UUID()
    }

    enum ScheduleType: Equatable {
        case oneTime
        case daily
        case weekdays([Int]) // Array of weekday indices
        case hourly(interval: Int)
        case every(interval: Int, unit: String) // interval and unit name
        case biweekly
        case monthly
        case yearly

        var badgeText: String {
            switch self {
            case .oneTime: return "Once"
            case .daily: return "Daily"
            case .weekdays(let days):
                if days.count == 7 { return "Daily" }
                if days.count == 5 && !days.contains(0) && !days.contains(6) { return "Weekdays" }
                if days.count == 2 && days.contains(0) && days.contains(6) { return "Weekend" }
                return "\(days.count) days"
            case .hourly(let interval): return "\(interval)h"
            case .every(let interval, let unit):
                // Show compact format: "30m", "2d", "1w"
                let unitAbbrev: String
                switch unit.lowercased() {
                case "minutes": unitAbbrev = "m"
                case "hours": unitAbbrev = "h"
                case "days": unitAbbrev = "d"
                case "weeks": unitAbbrev = "w"
                default: unitAbbrev = String(unit.prefix(1))
                }
                return "\(interval)\(unitAbbrev)"
            case .biweekly: return "Biweekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }

        var badgeColor: Color {
            switch self {
            case .oneTime: return Color(red: 0.055, green: 0.647, blue: 0.914) // Blue
            case .daily: return Color(red: 0.518, green: 0.800, blue: 0.086) // Green
            case .weekdays: return Color(red: 0.400, green: 0.600, blue: 0.800) // Light blue
            case .hourly: return Color(red: 0.800, green: 0.400, blue: 0.200) // Orange
            case .every: return Color(red: 0.200, green: 0.800, blue: 0.800) // Cyan
            case .biweekly: return Color(red: 0.600, green: 0.400, blue: 0.800) // Purple
            case .monthly: return Color(red: 0.900, green: 0.600, blue: 0.200) // Amber
            case .yearly: return Color(red: 0.800, green: 0.200, blue: 0.400) // Pink
            }
        }
    }

    /// Dynamically formatted time until alarm
    func timeUntilAlarm(from currentDate: Date) -> String {
        let interval = nextAlarmTime.timeIntervalSince(currentDate)
        let totalSeconds = Int(interval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            // Show days and hours for alarms more than 24h away
            if hours > 0 {
                return "in \(days)d \(hours)h"
            } else {
                return "in \(days)d"
            }
        } else if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "in \(minutes)m"
        } else {
            return "now"
        }
    }

    /// Clock angle for visualization (0° at 12, 90° at 3, 180° at 6, 270° at 9)
    var angle: Double {
        // Convert to 12-hour format for display
        let hour12 = hour % 12
        // Calculate angle: Each hour = 30°, each minute = 0.5°
        return Double(hour12) * 30.0 + Double(minute) * 0.5
    }
}
