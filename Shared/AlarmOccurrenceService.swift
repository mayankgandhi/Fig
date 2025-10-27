//
//  AlarmOccurrenceService.swift
//  fig
//
//  Centralized service for computing alarm occurrences
//  Eliminates duplicate computation between TodayViewModel and WidgetDataSharingService
//

import Foundation
import SwiftUI
import SwiftData

/// Centralized service for computing alarm occurrences
struct AlarmOccurrenceService {
    
    // MARK: - Public Methods
    
    /// Computes upcoming alarm occurrences within the specified time window
    /// - Parameters:
    ///   - context: SwiftData model context for fetching alarms
    ///   - withinHours: Time window in hours to search for upcoming alarms
    ///   - limit: Maximum number of alarms to return (nil for no limit)
    /// - Returns: Array of upcoming alarm presentations sorted by next alarm time
    static func computeOccurrences(
        context: ModelContext,
        withinHours: Int = 24,
        limit: Int? = nil
    ) async -> [UpcomingAlarmPresentation] {
        // Fetch all enabled alarms
        let descriptor = FetchDescriptor<Ticker>(
            predicate: #Predicate { $0.isEnabled },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let alarms = try? context.fetch(descriptor) else {
            return []
        }

        // Expand schedules to get upcoming dates
        let now = Date()
        let timeWindow = now.addingTimeInterval(Double(withinHours) * 60 * 60)
        let calendar = Calendar.current
        let expander = TickerScheduleExpander(calendar: calendar)

        var upcomingAlarms: [UpcomingAlarmPresentation] = []

        for alarm in alarms {
            guard let schedule = alarm.schedule else { continue }

            // Expand schedule
            let window = DateInterval(start: now, end: timeWindow)
            let expandedDates = expander.expandSchedule(schedule, within: window)

            // Limit to first 3 occurrences per alarm
            let limitedDates = Array(expandedDates)

            for alarmDate in limitedDates {
                let hour = calendar.component(.hour, from: alarmDate)
                let minute = calendar.component(.minute, from: alarmDate)

                let scheduleType: UpcomingAlarmPresentation.ScheduleType = {
                    switch schedule {
                    case .oneTime: return .oneTime
                    case .daily: return .daily
                    case .hourly(let interval, _): return .hourly(interval: interval)
                    case .weekdays(_, let days):
                        return .weekdays(days.map { $0.rawValue })
                    case .biweekly: return .biweekly
                    case .monthly: return .monthly
                    case .yearly: return .yearly
                    case .every(let interval, let unit, _):
                        let unitString: String
                        switch unit {
                        case .minutes: unitString = "minutes"
                        case .hours: unitString = "hours"
                        case .days: unitString = "days"
                        case .weeks: unitString = "weeks"
                        }
                        return .every(interval: interval, unit: unitString)
                    }
                }()

                let presentation = UpcomingAlarmPresentation(
                    baseAlarmId: alarm.id,
                    displayName: alarm.displayName,
                    icon: alarm.tickerData?.icon ?? "alarm",
                    color: extractColor(from: alarm),
                    nextAlarmTime: alarmDate,
                    scheduleType: scheduleType,
                    hour: hour,
                    minute: minute,
                    hasCountdown: alarm.countdown?.preAlert != nil,
                    tickerDataTitle: alarm.tickerData?.name
                )

                upcomingAlarms.append(presentation)
            }
        }

        // Sort by next alarm time
        upcomingAlarms.sort { $0.nextAlarmTime < $1.nextAlarmTime }

        // Apply limit
        if let limit = limit {
            return Array(upcomingAlarms.prefix(limit))
        }
        
        return upcomingAlarms
    }
    
    // MARK: - Private Helpers
    
    /// Extracts color from alarm with fallback hierarchy
    private static func extractColor(from alarm: Ticker) -> Color {
        // Try ticker data first
        if let colorHex = alarm.tickerData?.colorHex,
           let color = Color(hex: colorHex) {
            return color
        }

        // Try presentation tint
        if let tintHex = alarm.presentation.tintColorHex,
           let color = Color(hex: tintHex) {
            return color
        }

        // Default to accent
        return .accentColor
    }
}
