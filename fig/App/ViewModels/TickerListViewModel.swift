//
//  TickerListViewModel.swift
//  fig
//
//  ViewModel for ContentView following MVVM architecture
//

import Foundation
import SwiftUI
import SwiftData
import TickerCore

@Observable
final class TickerListViewModel {
    
    // MARK: - Published Properties
    
    var displayAlarms: [Ticker] = []
    var searchText: String = ""
    
    // MARK: - Dependencies
    
    private let tickerService: TickerService
    private let modelContext: ModelContext
    
    // MARK: - Computed Properties
    
    var filteredAlarms: [Ticker] {
        guard !searchText.isEmpty else {
            return displayAlarms
        }
        
        let lowercasedSearch = searchText.lowercased()
        
        return displayAlarms.filter { ticker in
            // Search by label
            if ticker.label.lowercased().contains(lowercasedSearch) {
                return true
            }
            
            // Search by time
            if let schedule = ticker.schedule {
                let timeString: String
                switch schedule {
                case .oneTime(let date):
                    // Format as "HH:mm" for one-time alarms
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    timeString = formatter.string(from: date)
                    
                case .daily(let time), .weekdays(let time, _), .biweekly(let time, _), .monthly(_, let time), .yearly(_, _, let time):
                    // Format as "HH:mm" for time-based alarms
                    timeString = String(format: "%02d:%02d", time.hour, time.minute)
                    
                case .hourly:
                    // For hourly alarms, use a generic string
                    timeString = "hourly"
                    
                case .every(let interval, let unit, _):
                    // For every alarms, create searchable string with interval and unit
                    let unitName = interval == 1 ? unit.singularName : unit.displayName.lowercased()
                    timeString = "every \(interval) \(unitName)"
                }
                
                if timeString.contains(lowercasedSearch) {
                    return true
                }
            }
            
            return false
        }.sorted { ticker1, ticker2 in
            sortByScheduledTime(ticker1, ticker2)
        }
    }
    
    // MARK: - Initialization
    
    init(tickerService: TickerService, modelContext: ModelContext) {
        self.tickerService = tickerService
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    func loadAlarms() {
        displayAlarms = tickerService.getAlarmsWithMetadata(context: modelContext).sorted { ticker1, ticker2 in
            sortByScheduledTime(ticker1, ticker2)
        }
    }
    
    func deleteAlarms(at offsets: IndexSet) {
        TickerHaptics.warning()
        
        // Collect IDs first to avoid index issues
        let alarmsToDelete = offsets.map { displayAlarms[$0] }
        Task { @MainActor in
            // Delete each alarm
            for alarm in alarmsToDelete {
                try? await tickerService.cancelAlarm(id: alarm.id, context: modelContext)
            }
        }
        
        // Reload the list
        loadAlarms()
    }
    
    func toggleAlarmEnabled(_ ticker: Ticker) async {
        ticker.isEnabled.toggle()
        
        // Update in TickerService
        Task { @MainActor in
            if ticker.isEnabled {
                try? await tickerService.scheduleAlarm(from: ticker, context: modelContext)
            } else {
                try? await tickerService.cancelAlarm(id: ticker.id, context: modelContext)
            }
            loadAlarms()
        }
    }
    
    // MARK: - Private Methods
    
    private func sortByScheduledTime(_ ticker1: Ticker, _ ticker2: Ticker) -> Bool {
        // Extract time components for comparison
        guard let schedule1 = ticker1.schedule, let schedule2 = ticker2.schedule else {
            // If either ticker doesn't have a schedule, keep original order
            if ticker1.schedule != nil { return true }
            if ticker2.schedule != nil { return false }
            return false
        }
        
        let time1 = getComparableTime(from: schedule1)
        let time2 = getComparableTime(from: schedule2)
        
        // For one-time schedules, also compare dates
        if case .oneTime(let date1) = schedule1, case .oneTime(let date2) = schedule2 {
            // Sort by full date and time for one-time schedules
            return date1 < date2
        }
        
        // For mixed or daily schedules, just compare time of day
        return time1 < time2
    }
    
    private func getComparableTime(from schedule: TickerSchedule) -> TimeInterval {
        switch schedule {
        case .oneTime(let date):
            // Get the time portion of the date as seconds from midnight
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)
            let seconds = (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
            return TimeInterval(seconds)
            
        case .daily(let time), .weekdays(let time, _), .biweekly(let time, _), .monthly(_, let time), .yearly(_, _, let time):
            // Convert time to seconds from midnight
            let seconds = time.hour * 3600 + time.minute * 60
            return TimeInterval(seconds)
            
        case .hourly(_, let time):
            // For hourly alarms, use the time
            let seconds = time.hour * 3600 + time.minute * 60
            return TimeInterval(seconds)
            
        case .every(_, _, let time):
            // For every alarms, use the time for sorting
            let seconds = time.hour * 3600 + time.minute * 60
            return TimeInterval(seconds)
        }
    }
}
