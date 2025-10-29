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
import TickerCore
// MARK: - TodayViewModel

@Observable
final class TodayViewModel {

    // MARK: - Dependencies

    private let tickerService: TickerService
    private let alarmStateManager: AlarmStateManagerProtocol
    private let modelContext: ModelContext
    private let calendar: Calendar

    // MARK: - Cached State (computed off main thread, stored for fast access)
    private(set) var upcomingAlarms: [UpcomingAlarmPresentation] = []
    private(set) var upcomingAlarmsForClock: [UpcomingAlarmPresentation] = []
    
    /// Number of upcoming alarms
    var upcomingAlarmsCount: Int {
        upcomingAlarms.count
    }

    /// Whether there are any upcoming alarms
    var hasUpcomingAlarms: Bool {
        !upcomingAlarms.isEmpty
    }

    // MARK: - Initialization

    init(
        tickerService: TickerService,
        alarmStateManager: AlarmStateManagerProtocol,
        modelContext: ModelContext,
        calendar: Calendar = .current
    ) {
        self.tickerService = tickerService
        self.alarmStateManager = alarmStateManager
        self.modelContext = modelContext
        self.calendar = calendar
    }

    // MARK: - Public Methods

    /// Refreshes upcoming alarms (call this when alarms change)
    /// Computation happens off main thread for better performance
    /// Uses AlarmStateManager as single source of truth
    func refreshAlarms() async {
        let now = Date()
        let timeWindow = now.addingTimeInterval(24 * 60 * 60)

        // Get all tickers from AlarmStateManager (single source of truth)
        let allTickers = alarmStateManager.getAllTickers()
        print("📊 TodayViewModel: Found \(allTickers.count) total tickers from AlarmStateManager")

        // Debug: Print all tickers
        for ticker in allTickers {
            print("   📋 Ticker: '\(ticker.label)' (ID: \(ticker.id))")
            print("      - Enabled: \(ticker.isEnabled)")
            print("      - Schedule: \(String(describing: ticker.schedule))")
            print("      - Generated AlarmKit IDs: \(ticker.generatedAlarmKitIDs.count)")
        }

        // Filter for enabled alarms
        let enabledTickers = allTickers.filter { $0.isEnabled }
        print("📊 TodayViewModel: \(enabledTickers.count) enabled tickers")

        // Expand schedules to get upcoming dates
        let expander = TickerScheduleExpander(calendar: calendar)
        var upcomingOccurrences: [UpcomingAlarmPresentation] = []

        for ticker in enabledTickers {
            guard let schedule = ticker.schedule else {
                print("⚠️ TodayViewModel: Ticker '\(ticker.label)' has no schedule, skipping")
                continue
            }

            print("🔍 TodayViewModel: Expanding schedule for '\(ticker.label)': \(schedule)")

            // Expand schedule within time window
            let window = DateInterval(start: now, end: timeWindow)
            let expandedDates = expander.expandSchedule(schedule, within: window)
            print("   → Found \(expandedDates.count) occurrences in next 24 hours")

            for alarmDate in expandedDates {
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
                    baseAlarmId: ticker.id,
                    displayName: ticker.displayName,
                    icon: ticker.tickerData?.icon ?? "alarm",
                    color: extractColor(from: ticker),
                    nextAlarmTime: alarmDate,
                    scheduleType: scheduleType,
                    hour: hour,
                    minute: minute,
                    hasCountdown: ticker.countdown?.preAlert != nil,
                    tickerDataTitle: ticker.tickerData?.name
                )

                upcomingOccurrences.append(presentation)
            }
        }

        // Filter to only future occurrences and sort
        let sortedOccurrences = upcomingOccurrences
            .filter { $0.nextAlarmTime > now }
            .sorted { $0.nextAlarmTime < $1.nextAlarmTime }

        print("✅ TodayViewModel: Total upcoming occurrences: \(sortedOccurrences.count)")

        // Compute clock alarms: filter to next 12 hours
        let twelveHoursFromNow = calendar.date(byAdding: .hour, value: 12, to: now) ?? now
        let clockAlarms = sortedOccurrences.filter { occurrence in
            occurrence.nextAlarmTime > now && occurrence.nextAlarmTime <= twelveHoursFromNow
        }

        print("✅ TodayViewModel: Clock alarms (next 12 hours): \(clockAlarms.count)")

        // Update state on main thread
        await MainActor.run {
            self.upcomingAlarms = sortedOccurrences
            self.upcomingAlarmsForClock = clockAlarms
            print("✅ TodayViewModel: State updated - upcomingAlarms: \(self.upcomingAlarms.count), clockAlarms: \(self.upcomingAlarmsForClock.count)")
        }
    }

    // MARK: - Helper Methods

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
