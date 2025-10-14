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
struct UpcomingAlarmPresentation: Identifiable {
    let id: UUID
    let displayName: String
    let icon: String
    let color: Color
    let nextAlarmTime: Date
    let scheduleType: ScheduleType
    let hour: Int
    let minute: Int

    enum ScheduleType {
        case oneTime
        case daily

        var badgeText: String {
            switch self {
            case .oneTime: return "Once"
            case .daily: return "Daily"
            }
        }

        var badgeColor: Color {
            switch self {
            case .oneTime: return Color(red: 0.055, green: 0.647, blue: 0.914)
            case .daily: return Color(red: 0.518, green: 0.800, blue: 0.086)
            }
        }
    }

    /// Dynamically formatted time until alarm
    func timeUntilAlarm(from currentDate: Date) -> String {
        let interval = nextAlarmTime.timeIntervalSince(currentDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
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
