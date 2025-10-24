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
struct UpcomingAlarmPresentation: Identifiable, Equatable, Codable {
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

    // MARK: - Codable Support

    enum CodingKeys: String, CodingKey {
        case id, baseAlarmId, displayName, icon, colorHex, nextAlarmTime
        case scheduleType, hour, minute, hasCountdown, tickerDataTitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        baseAlarmId = try container.decode(UUID.self, forKey: .baseAlarmId)
        displayName = try container.decode(String.self, forKey: .displayName)
        icon = try container.decode(String.self, forKey: .icon)

        // Decode color from hex string
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: colorHex) ?? .accentColor

        nextAlarmTime = try container.decode(Date.self, forKey: .nextAlarmTime)
        scheduleType = try container.decode(ScheduleType.self, forKey: .scheduleType)
        hour = try container.decode(Int.self, forKey: .hour)
        minute = try container.decode(Int.self, forKey: .minute)
        hasCountdown = try container.decode(Bool.self, forKey: .hasCountdown)
        tickerDataTitle = try container.decodeIfPresent(String.self, forKey: .tickerDataTitle)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(baseAlarmId, forKey: .baseAlarmId)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(icon, forKey: .icon)

        // Encode color as hex string
        try container.encode(color.toHex() ?? "#007AFF", forKey: .colorHex)

        try container.encode(nextAlarmTime, forKey: .nextAlarmTime)
        try container.encode(scheduleType, forKey: .scheduleType)
        try container.encode(hour, forKey: .hour)
        try container.encode(minute, forKey: .minute)
        try container.encode(hasCountdown, forKey: .hasCountdown)
        try container.encodeIfPresent(tickerDataTitle, forKey: .tickerDataTitle)
    }
    
    /// Calculated angle for clock face positioning (0-360 degrees)
    var angle: Double {
        let hour12 = hour % 12
        return Double(hour12) * 30.0 + Double(minute) * 0.5
    }
    
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

    enum ScheduleType: Equatable, Codable {
        case oneTime
        case daily
        case weekdays([Int]) // Array of weekday indices
        case hourly(interval: Int)
        case every(interval: Int, unit: String) // interval and unit name
        case biweekly
        case monthly
        case yearly

        enum CodingKeys: String, CodingKey {
            case type, weekdays, interval, unit
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "oneTime":
                self = .oneTime
            case "daily":
                self = .daily
            case "weekdays":
                let days = try container.decode([Int].self, forKey: .weekdays)
                self = .weekdays(days)
            case "hourly":
                let interval = try container.decode(Int.self, forKey: .interval)
                self = .hourly(interval: interval)
            case "every":
                let interval = try container.decode(Int.self, forKey: .interval)
                let unit = try container.decode(String.self, forKey: .unit)
                self = .every(interval: interval, unit: unit)
            case "biweekly":
                self = .biweekly
            case "monthly":
                self = .monthly
            case "yearly":
                self = .yearly
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .type,
                    in: container,
                    debugDescription: "Unknown schedule type: \(type)"
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .oneTime:
                try container.encode("oneTime", forKey: .type)
            case .daily:
                try container.encode("daily", forKey: .type)
            case .weekdays(let days):
                try container.encode("weekdays", forKey: .type)
                try container.encode(days, forKey: .weekdays)
            case .hourly(let interval):
                try container.encode("hourly", forKey: .type)
                try container.encode(interval, forKey: .interval)
            case .every(let interval, let unit):
                try container.encode("every", forKey: .type)
                try container.encode(interval, forKey: .interval)
                try container.encode(unit, forKey: .unit)
            case .biweekly:
                try container.encode("biweekly", forKey: .type)
            case .monthly:
                try container.encode("monthly", forKey: .type)
            case .yearly:
                try container.encode("yearly", forKey: .type)
            }
        }

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

}
