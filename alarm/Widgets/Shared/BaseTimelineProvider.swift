//
//  BaseTimelineProvider.swift
//  alarm
//
//  Base timeline provider with shared logic for all widget providers
//  Reduces code duplication across widget implementations
//

import WidgetKit
import SwiftUI

/// Base timeline entry for widgets displaying upcoming alarms
struct AlarmTimelineEntry: TimelineEntry {
    let date: Date
    let upcomingAlarms: [UpcomingAlarmPresentation]

    /// Convenience initializer for single alarm
    init(date: Date, nextAlarm: UpcomingAlarmPresentation?) {
        self.date = date
        self.upcomingAlarms = nextAlarm.map { [$0] } ?? []
    }

    /// Standard initializer for multiple alarms
    init(date: Date, upcomingAlarms: [UpcomingAlarmPresentation]) {
        self.date = date
        self.upcomingAlarms = upcomingAlarms
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
            var entries: [AlarmTimelineEntry] = []
            for minuteOffset in stride(from: 0, through: timeWindowMinutes, by: 1) {
                let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: nextMinute)!
                let entry = AlarmTimelineEntry(date: entryDate, upcomingAlarms: upcomingAlarms)
                entries.append(entry)
            }

            // Update policy: Refresh after the last entry
            let timeline = Timeline(entries: entries, policy: .atEnd)
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
            var entries: [AlarmTimelineEntry] = []
            for minuteOffset in stride(from: 0, through: timeWindowMinutes, by: 1) {
                let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: nextMinute)!
                let entry = AlarmTimelineEntry(date: entryDate, nextAlarm: nextAlarm)
                entries.append(entry)
            }

            // Update policy: Refresh after the last entry
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }

    // MARK: - Placeholder & Snapshot

    /// Creates a placeholder entry for widgets
    /// - Returns: Empty timeline entry
    static func createPlaceholder() -> AlarmTimelineEntry {
        AlarmTimelineEntry(date: Date(), upcomingAlarms: [])
    }

    /// Creates a snapshot entry for widgets
    /// - Returns: Empty timeline entry
    static func createSnapshot() -> AlarmTimelineEntry {
        AlarmTimelineEntry(date: Date(), upcomingAlarms: [])
    }
}
