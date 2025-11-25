//
//  TimeOfDay.swift
//  TickerCore
//
//  Created by Mayank Gandhi on 24/11/25.
//

import Foundation

public struct TimeOfDay: Codable, Hashable, Sendable {
    
    public var hour: Int // 0-23
    public var minute: Int // 0-59
    
    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
    
    public init(from date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        self.hour = components.hour ?? 0
        self.minute = components.minute ?? 0
    }
    
    public func addingTimeInterval(_ interval: TimeInterval) -> TimeOfDay {
        let totalMinutes = hour * 60 + minute
        let intervalMinutes = Int(interval / 60)
        let newTotalMinutes = totalMinutes + intervalMinutes

        // Handle day rollover - ensure we stay within 24-hour range
        let adjustedMinutes = ((newTotalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60)
        let newHour = adjustedMinutes / 60
        let newMinute = adjustedMinutes % 60

        return TimeOfDay(hour: newHour, minute: newMinute)
    }

    public func formatted(as style: TimeOfDayFormatStyle) -> String {
        let components = DateComponents(hour: hour, minute: minute)
        guard let date = Calendar.current.date(from: components) else {
            return "\(hour):\(String(format: "%02d", minute))"
        }

        switch style {
        case .hourMinute:
            return date.formatted(date: .omitted, time: .shortened)
        case .twentyFourHour:
            return String(format: "%02d:%02d", hour, minute)
        }
    }
}

public enum TimeOfDayFormatStyle {
    case hourMinute     // e.g., "9:30 AM"
    case twentyFourHour // e.g., "09:30"
}
