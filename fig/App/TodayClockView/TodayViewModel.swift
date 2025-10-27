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

// MARK: - TodayViewModel

@Observable
final class TodayViewModel {

    // MARK: - Dependencies

    private let tickerService: TickerService
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

    init(tickerService: TickerService, modelContext: ModelContext, calendar: Calendar = .current) {
        self.tickerService = tickerService
        self.modelContext = modelContext
        self.calendar = calendar
    }

    // MARK: - Public Methods
    
    /// Refreshes upcoming alarms (call this when alarms change)
    /// Computation happens off main thread for better performance
    func refreshAlarms() async {
        let now = Date()
        let twentyFourHoursFromNow = Date().addingTimeInterval(24*60*60)

        // Get all upcoming occurrences using centralized service
        let allOccurrences = await AlarmOccurrenceService.computeOccurrences(
            context: modelContext,
            withinHours: 24,
            limit: nil
        )
        
        // Filter to only future occurrences
        let sortedOccurrences = allOccurrences.filter { $0.nextAlarmTime > now }
            .sorted { $0.nextAlarmTime < $1.nextAlarmTime }

        // Compute clock alarms: just filter sortedOccurrences to next 12 hours
        let twelveHoursFromNow = calendar.date(byAdding: .hour, value: 12, to: now) ?? now
        
        let clockAlarms = sortedOccurrences.filter { occurrence in
            occurrence.nextAlarmTime > now && occurrence.nextAlarmTime <= twelveHoursFromNow
        }

        // Update state on main thread
        await MainActor.run {
            self.upcomingAlarms = sortedOccurrences
            self.upcomingAlarmsForClock = clockAlarms
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
