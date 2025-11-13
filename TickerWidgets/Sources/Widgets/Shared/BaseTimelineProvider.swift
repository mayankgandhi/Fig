//
//  BaseTimelineProvider.swift
//  alarm
//
//  Base timeline provider with shared logic for all widget providers
//  Reduces code duplication across widget implementations
//

import WidgetKit
import SwiftUI
import TickerCore

/// Base timeline entry for widgets displaying upcoming alarms
struct AlarmTimelineEntry: TimelineEntry {
    let date: Date
    let upcomingAlarms: [UpcomingAlarmPresentation]
    let isPreview: Bool

    /// Convenience initializer for single alarm
    init(date: Date, nextAlarm: UpcomingAlarmPresentation?, isPreview: Bool = false) {
        self.date = date
        self.upcomingAlarms = nextAlarm.map { [$0] } ?? []
        self.isPreview = isPreview
    }

    /// Standard initializer for multiple alarms
    init(date: Date, upcomingAlarms: [UpcomingAlarmPresentation], isPreview: Bool = false) {
        self.date = date
        self.upcomingAlarms = upcomingAlarms
        self.isPreview = isPreview
    }
}

/// Shared timeline generation logic for alarm widgets
struct BaseTimelineProvider {

    // MARK: - Timeline Generation

    /// Generates a timeline with minute-by-minute updates
    /// - Parameters:
    ///   - context: Widget context
    ///   - completion: Completion handler with generated timeline
    ///   - timeWindowMinutes: Number of minutes to generate entries for
    ///   - alarmTimeWindowHours: Time window in hours to fetch upcoming alarms
    ///   - alarmLimit: Maximum number of alarms to fetch (nil for no limit)
    static func generateTimeline(
        in context: Any,
        completion: @escaping (Timeline<AlarmTimelineEntry>) -> Void,
        timeWindowMinutes: Int = 60,
        alarmTimeWindowHours: Int = 24,
        alarmLimit: Int? = nil
    ) {
        Task {
            let calendar = Calendar.current
            let currentDate = Date()

            // Calculate the start of the next minute
            let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
            guard let currentMinute = calendar.date(from: currentComponents),
                  let nextMinute = calendar.date(byAdding: .minute, value: 1, to: currentMinute) else {
                let entry = AlarmTimelineEntry(date: currentDate, upcomingAlarms: [])
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
                return
            }

            // Fetch upcoming alarms
            let upcomingAlarms = await WidgetDataFetcher.fetchUpcomingAlarms(
                limit: alarmLimit,
                withinHours: alarmTimeWindowHours
            )

            // Generate timeline entries for the specified time window, updating every minute
            // Each entry filters alarms based on its own date to remove stale alarms
            var entries: [AlarmTimelineEntry] = []
            for minuteOffset in stride(from: 0, through: timeWindowMinutes, by: 1) {
                let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: currentMinute)!

                // Filter alarms that are still in the future for this entry's date
                let filteredAlarms = upcomingAlarms.filter { $0.nextAlarmTime > entryDate }

                let entry = AlarmTimelineEntry(date: entryDate, upcomingAlarms: filteredAlarms)
                entries.append(entry)
            }

            // Calculate smart refresh date: next alarm fire time
            // This ensures widgets update soon after an alarm fires
            let refreshPolicy: TimelineReloadPolicy
            if let nextAlarmTime = upcomingAlarms.first?.nextAlarmTime {
                refreshPolicy = .after(nextAlarmTime)
            } else {
                // No upcoming alarms, use default policy
                refreshPolicy = .atEnd
            }

            let timeline = Timeline(entries: entries, policy: refreshPolicy)
            completion(timeline)
        }
    }

    /// Generates a timeline for widgets showing only the next alarm
    /// - Parameters:
    ///   - context: Widget context
    ///   - completion: Completion handler with generated timeline
    ///   - timeWindowMinutes: Number of minutes to generate entries for
    ///   - alarmTimeWindowHours: Time window in hours to search for next alarm
    static func generateNextAlarmTimeline(
        in context: Any,
        completion: @escaping (Timeline<AlarmTimelineEntry>) -> Void,
        timeWindowMinutes: Int = 30,
        alarmTimeWindowHours: Int = 24
    ) {
        Task {
            let calendar = Calendar.current
            let currentDate = Date()

            // Calculate the start of the next minute
            let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
            guard let currentMinute = calendar.date(from: currentComponents),
                  let nextMinute = calendar.date(byAdding: .minute, value: 1, to: currentMinute) else {
                let entry = AlarmTimelineEntry(date: currentDate, nextAlarm: nil)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
                return
            }

            // Fetch next alarm
            let nextAlarm = await WidgetDataFetcher.fetchNextAlarm(withinHours: alarmTimeWindowHours)

            // Generate timeline entries for the specified time window, updating every minute
            // Each entry filters alarm based on its own date to remove stale alarm
            var entries: [AlarmTimelineEntry] = []
            for minuteOffset in stride(from: 0, through: timeWindowMinutes, by: 1) {
                let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: currentMinute)!

                // Only show alarm if it's still in the future for this entry's date
                let filteredAlarm: UpcomingAlarmPresentation? = {
                    guard let alarm = nextAlarm else { return nil }
                    return alarm.nextAlarmTime > entryDate ? alarm : nil
                }()

                let entry = AlarmTimelineEntry(date: entryDate, nextAlarm: filteredAlarm)
                entries.append(entry)
            }

            // Calculate smart refresh date: next alarm fire time
            // This ensures widgets update soon after an alarm fires
            let refreshPolicy: TimelineReloadPolicy
            if let nextAlarmTime = nextAlarm?.nextAlarmTime {
                refreshPolicy = .after(nextAlarmTime)
            } else {
                // No upcoming alarms, use default policy
                refreshPolicy = .atEnd
            }

            let timeline = Timeline(entries: entries, policy: refreshPolicy)
            completion(timeline)
        }
    }

    // MARK: - Placeholder & Snapshot

    /// Creates a placeholder entry for widgets
    /// - Returns: Timeline entry with dummy data for rich preview
    static func createPlaceholder() -> AlarmTimelineEntry {
        AlarmTimelineEntry(date: Date(), upcomingAlarms: createDummyAlarms(), isPreview: true)
    }

    /// Creates a snapshot entry for widgets
    /// - Returns: Timeline entry with dummy data for rich preview
    static func createSnapshot() -> AlarmTimelineEntry {
        AlarmTimelineEntry(date: Date(), upcomingAlarms: createDummyAlarms(), isPreview: true)
    }
    
    /// Creates dummy alarm data for rich widget previews
    /// - Returns: Array of sample alarms with diverse examples
    private static func createDummyAlarms() -> [UpcomingAlarmPresentation] {
        let now = Date()
        return [
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Morning Workout",
                icon: "figure.run",
                color: .orange,
                nextAlarmTime: now.addingTimeInterval(7200), // 2 hours
                scheduleType: .daily,
                hour: 7,
                minute: 0,
                hasCountdown: true,
                tickerDataTitle: "Fitness"
            ),
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Team Standup",
                icon: "person.3.fill",
                color: .blue,
                nextAlarmTime: now.addingTimeInterval(14400), // 4 hours
                scheduleType: .weekdays([1, 2, 3, 4, 5]),
                hour: 10,
                minute: 0,
                hasCountdown: false,
                tickerDataTitle: nil
            ),
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Lunch Break",
                icon: "fork.knife",
                color: .green,
                nextAlarmTime: now.addingTimeInterval(21600), // 6 hours
                scheduleType: .daily,
                hour: 12,
                minute: 30,
                hasCountdown: false,
                tickerDataTitle: nil
            ),
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Afternoon Coffee",
                icon: "cup.and.saucer.fill",
                color: .brown,
                nextAlarmTime: now.addingTimeInterval(28800), // 8 hours
                scheduleType: .daily,
                hour: 15,
                minute: 0,
                hasCountdown: false,
                tickerDataTitle: nil
            ),
        ]
    }
}
