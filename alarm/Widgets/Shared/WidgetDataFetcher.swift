//
//  WidgetDataFetcher.swift
//  alarm
//
//  Centralized data fetching service for all widgets
//  Provides SwiftData access to alarm data via App Groups
//

import SwiftUI
import SwiftData

/// Centralized service for fetching alarm data in widgets
struct WidgetDataFetcher {

    // MARK: - Public Methods

    /// Fetches upcoming alarms within the specified time window
    /// - Parameters:
    ///   - limit: Maximum number of alarms to return (nil for no limit)
    ///   - withinHours: Time window in hours to search for upcoming alarms
    /// - Returns: Array of upcoming alarm presentations sorted by next alarm time
    static func fetchUpcomingAlarms(limit: Int? = nil, withinHours: Int = 24) async -> [UpcomingAlarmPresentation] {
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

        // Filter for upcoming alarms within the specified time window
        let now = Date()
        let timeWindow = now.addingTimeInterval(Double(withinHours) * 60 * 60)
        let calendar = Calendar.current

        var upcomingAlarms = alarms.compactMap { alarm -> UpcomingAlarmPresentation? in
            guard let schedule = alarm.schedule else { return nil }

            let nextAlarmTime: Date

            switch schedule {
            case .oneTime(let date):
                guard date >= now && date <= timeWindow else { return nil }
                nextAlarmTime = date

            case .daily(let time, _):
                let nextOccurrence = getNextOccurrence(for: time, from: now, calendar: calendar)
                guard nextOccurrence <= timeWindow else { return nil }
                nextAlarmTime = nextOccurrence

            case .hourly, .weekdays, .biweekly, .monthly, .yearly, .every:
                // For composite schedules, skip in widgets for simplicity
                return nil
            }

            let hour = calendar.component(.hour, from: nextAlarmTime)
            let minute = calendar.component(.minute, from: nextAlarmTime)

            let scheduleType: UpcomingAlarmPresentation.ScheduleType = {
                switch schedule {
                case .oneTime: return .oneTime
                case .daily: return .daily
                default: return .oneTime
                }
            }()

            return UpcomingAlarmPresentation(
                baseAlarmId: alarm.id,
                displayName: alarm.displayName,
                icon: alarm.tickerData?.icon ?? "alarm",
                color: extractColor(from: alarm),
                nextAlarmTime: nextAlarmTime,
                scheduleType: scheduleType,
                hour: hour,
                minute: minute,
                hasCountdown: alarm.countdown?.preAlert != nil,
                tickerDataTitle: alarm.tickerData?.name
            )
        }
        .sorted { $0.nextAlarmTime < $1.nextAlarmTime }

        // Apply limit if specified
        if let limit = limit {
            upcomingAlarms = Array(upcomingAlarms.prefix(limit))
        }

        return upcomingAlarms
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

    /// Calculates the next occurrence of a daily alarm
    /// - Parameters:
    ///   - time: Time of day for the alarm
    ///   - date: Reference date to calculate from
    ///   - calendar: Calendar to use for calculations
    /// - Returns: Next occurrence date
    private static func getNextOccurrence(for time: TickerSchedule.TimeOfDay, from date: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0

        guard let todayOccurrence = calendar.date(from: components) else {
            return date
        }

        // If today's occurrence has passed, return tomorrow's
        if todayOccurrence <= date {
            return calendar.date(byAdding: .day, value: 1, to: todayOccurrence) ?? todayOccurrence
        }

        return todayOccurrence
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
