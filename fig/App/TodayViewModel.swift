//
//  TodayViewModel.swift
//  fig
//
//  ViewModel for TodayClockView using MVVM architecture
//  Handles all business logic for upcoming alarm display and clock visualization
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Presentation Model

/// View-ready representation of an upcoming alarm with pre-calculated values
struct UpcomingAlarmPresentation: Identifiable {
    let id: UUID
    let displayName: String
    let icon: String
    let color: Color
    let nextAlarmTime: Date
    let scheduleType: ScheduleType

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
            case .oneTime: return TickerColors.scheduled
            case .daily: return TickerColors.running
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
}

// MARK: - TodayViewModel

@Observable
final class TodayViewModel {

    // MARK: - Dependencies

    private let alarmService: AlarmService
    private let modelContext: ModelContext
    private let calendar: Calendar

    // MARK: - Computed Properties

    /// All enabled alarms from AlarmService
    private var allEnabledAlarms: [Ticker] {
        alarmService.getAlarmsWithMetadata(context: modelContext).filter { $0.isEnabled }
    }

    /// Alarms scheduled within the next 12 hours, sorted by time
    var upcomingAlarms: [UpcomingAlarmPresentation] {
        let now = Date()
        let next12Hours = now.addingTimeInterval(12 * 60 * 60)

        return allEnabledAlarms
            .filter { alarm in
                guard let schedule = alarm.schedule else { return false }

                switch schedule {
                case .oneTime(let date):
                    return date >= now && date <= next12Hours

                case .daily(let time):
                    let nextOccurrence = getNextOccurrence(for: time, from: now)
                    return nextOccurrence <= next12Hours
                }
            }
            .sorted { alarm1, alarm2 in
                let time1 = getNextAlarmTime(for: alarm1, from: now)
                let time2 = getNextAlarmTime(for: alarm2, from: now)
                return time1 < time2
            }
            .map { createPresentation(from: $0, currentTime: now) }
    }

    /// Clock events for visualization
    var clockEvents: [ClockView.TimeBlock] {
        upcomingAlarms.map { presentation in
            ClockView.TimeBlock(
                id: presentation.id,
                city: presentation.displayName,
                hour: calendar.component(.hour, from: presentation.nextAlarmTime),
                minute: calendar.component(.minute, from: presentation.nextAlarmTime),
                color: presentation.color
            )
        }
    }

    /// Number of upcoming alarms
    var upcomingAlarmsCount: Int {
        upcomingAlarms.count
    }

    /// Whether there are any upcoming alarms
    var hasUpcomingAlarms: Bool {
        !upcomingAlarms.isEmpty
    }

    // MARK: - Initialization

    init(alarmService: AlarmService, modelContext: ModelContext, calendar: Calendar = .current) {
        self.alarmService = alarmService
        self.modelContext = modelContext
        self.calendar = calendar
    }

    // MARK: - Presentation Model Creation

    private func createPresentation(from alarm: Ticker, currentTime: Date) -> UpcomingAlarmPresentation {
        let nextTime = getNextAlarmTime(for: alarm, from: currentTime)
        let scheduleType: UpcomingAlarmPresentation.ScheduleType = {
            guard let schedule = alarm.schedule else { return .oneTime }
            switch schedule {
            case .oneTime: return .oneTime
            case .daily: return .daily
            }
        }()

        return UpcomingAlarmPresentation(
            id: alarm.id,
            displayName: alarm.displayName,
            icon: alarm.tickerData?.icon ?? "alarm",
            color: extractColor(from: alarm),
            nextAlarmTime: nextTime,
            scheduleType: scheduleType
        )
    }

    // MARK: - Helper Methods

    /// Calculates the next occurrence of a daily alarm time
    private func getNextOccurrence(for time: TickerSchedule.TimeOfDay, from date: Date) -> Date {
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

    /// Gets the next alarm time for any alarm type
    private func getNextAlarmTime(for alarm: Ticker, from date: Date) -> Date {
        guard let schedule = alarm.schedule else { return Date.distantFuture }

        switch schedule {
        case .oneTime(let alarmDate):
            return alarmDate
        case .daily(let time):
            return getNextOccurrence(for: time, from: date)
        }
    }

    /// Extracts display color from alarm with fallback hierarchy
    private func extractColor(from alarm: Ticker) -> Color {
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
