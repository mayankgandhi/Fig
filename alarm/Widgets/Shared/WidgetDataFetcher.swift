//
//  WidgetDataFetcher.swift
//  alarm
//
//  Centralized data fetching service for all widgets
//  Provides SwiftData access to alarm data via App Groups
//

import SwiftUI
import SwiftData
import TickerCore

/// Centralized service for fetching alarm data in widgets
struct WidgetDataFetcher {

    // MARK: - Public Methods

    /// Fetches upcoming alarms within the specified time window
    /// - Parameters:
    ///   - limit: Maximum number of alarms to return (nil for no limit)
    ///   - withinHours: Time window in hours to search for upcoming alarms
    /// - Returns: Array of upcoming alarm presentations sorted by next alarm time
    /// - Note: Runs on background thread for widget performance
    static func fetchUpcomingAlarms(limit: Int? = nil, withinHours: Int = 24) async -> [UpcomingAlarmPresentation] {
        // Explicitly run on background thread to avoid blocking widget rendering
        return await Task.detached(priority: .userInitiated) {
            guard let context = createModelContext() else {
                return []
            }

            // Fetch all enabled alarms
            let descriptor = FetchDescriptor<Ticker>(
                predicate: #Predicate { $0.isEnabled },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )

            guard let alarms = try? context.fetch(descriptor) else {
                return []
            }

        // Expand schedules to get upcoming dates using TickerScheduleExpander
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

        // Filter out past alarms (critical for removing triggered alarms)
        upcomingAlarms = upcomingAlarms.filter { $0.nextAlarmTime > now }

        // Sort by next alarm time
        upcomingAlarms.sort { $0.nextAlarmTime < $1.nextAlarmTime }

        // Apply limit if specified
        if let limit = limit {
            upcomingAlarms = Array(upcomingAlarms.prefix(limit))
        }

        return upcomingAlarms
        }.value
    }

    /// Fetches the next upcoming alarm
    /// - Parameter withinHours: Time window in hours to search
    /// - Returns: Next alarm presentation or nil if no alarms found
    static func fetchNextAlarm(withinHours: Int = 24) async -> UpcomingAlarmPresentation? {
        let alarms = await fetchUpcomingAlarms(limit: 1, withinHours: withinHours)
        return alarms.first
    }

    // MARK: - Private Helpers

    /// Creates a ModelContext with App Groups support
    /// - Returns: ModelContext configured for shared container access, or nil on failure
    private static func createModelContext() -> ModelContext? {
        let schema = Schema([Ticker.self])

        // Try to use shared container first, fallback to local if not available
        let modelConfiguration: ModelConfiguration
        if let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.m.fig") {
            modelConfiguration = ModelConfiguration(schema: schema, url: sharedURL.appendingPathComponent("Ticker.sqlite"))
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        guard let modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            return nil
        }

        return ModelContext(modelContainer)
    }


    /// Extracts color from alarm data with fallback logic
    /// - Parameter alarm: Alarm to extract color from
    /// - Returns: Color for the alarm
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
