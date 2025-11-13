//
//  TodayViewModel.swift
//  fig
//
//  ViewModel for TodayClockView using MVVM architecture
//  Handles all business logic for upcoming alarm display and clock visualization
//

import Foundation
import SwiftUI
import TickerCore

// MARK: - TodayViewModel

@Observable
final class TodayViewModel {

    // MARK: - Dependencies

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

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Public Methods

    /// Refreshes upcoming alarms (call this when alarms change)
    /// Uses WidgetDataFetcher for consistent data fetching
    func refreshAlarms() async {
        // Fetch all upcoming alarms for next 24 hours using WidgetDataFetcher
        let upcomingAlarms = await WidgetDataFetcher.fetchUpcomingAlarms(limit: nil, withinHours: 24)

        print("✅ TodayViewModel: Fetched \(upcomingAlarms.count) upcoming alarms from WidgetDataFetcher")

        // Compute clock alarms: filter to next 12 hours
        let now = Date()
        let twelveHoursFromNow = calendar.date(byAdding: .hour, value: 12, to: now) ?? now
        let clockAlarms = upcomingAlarms.filter { occurrence in
            occurrence.nextAlarmTime > now && occurrence.nextAlarmTime <= twelveHoursFromNow
        }

        print("✅ TodayViewModel: Clock alarms (next 12 hours): \(clockAlarms.count)")

        // Update state on main thread
        await MainActor.run {
            self.upcomingAlarms = upcomingAlarms
            self.upcomingAlarmsForClock = clockAlarms
            print("✅ TodayViewModel: State updated - upcomingAlarms: \(self.upcomingAlarms.count), clockAlarms: \(self.upcomingAlarmsForClock.count)")
        }
    }

}
