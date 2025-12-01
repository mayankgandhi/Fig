//
//  WidgetDataFetcher.swift
//  alarm
//
//  Centralized data fetching service for all widgets
//  Uses AlarmKit as the source of truth for active alarms
//

import SwiftUI
import SwiftData
import AlarmKit
import Factory

/// Centralized service for fetching alarm data in widgets
public struct WidgetDataFetcher {

    // MARK: - Public Methods

    /// Fetches upcoming alarms within the specified time window
    /// Uses AlarmKit as the source of truth for active alarms, then matches to Ticker objects
    /// - Parameters:
    ///   - limit: Maximum number of alarms to return (nil for no limit)
    ///   - withinHours: Time window in hours to search for upcoming alarms
    /// - Returns: Array of upcoming alarm presentations sorted by next alarm time
    /// - Note: Runs on background thread for widget performance
    public static func fetchUpcomingAlarms(limit: Int? = nil, withinHours: Int = 24) async -> [UpcomingAlarmPresentation] {
        // Explicitly run on background thread to avoid blocking widget rendering
        return await Task.detached(priority: .userInitiated) {
            // 1. Get AlarmKit services (source of truth)
            let alarmManager = Container.shared.alarmManager()
            let stateManager = Container.shared.alarmStateManager()
            
            // 2. Query active alarms from AlarmKit
            let alarmKitAlarms: [Alarm]
            do {
                alarmKitAlarms = try stateManager.queryAlarmKit(alarmManager: alarmManager)
            } catch {
                // Log error with more context for debugging
                print("❌ WidgetDataFetcher: Failed to query AlarmKit: \(error)")
                print("   → Error type: \(type(of: error))")
                print("   → Error description: \(error.localizedDescription)")
                // Return empty array - AlarmKit is source of truth, no fallback
                return []
            }
            
            // 3. Filter alarms to next 24 hours based on alertingTime
            let now = Date()
            let timeWindowEnd = now.addingTimeInterval(Double(withinHours) * 60 * 60)
            // Use consistent calendar instance to avoid timezone changes during execution
            let calendar = Calendar.current
            
            let upcomingAlarmKitAlarms = alarmKitAlarms.compactMap { alarm -> (Alarm, Date)? in
                guard let alertingTime = alarm.alertingTime else {
                    return nil
                }
                // Include alarms at or after current time and within the time window
                // Using >= to include alarms exactly at current moment
                guard alertingTime >= now && alertingTime <= timeWindowEnd else {
                    return nil
                }
                return (alarm, alertingTime)
            }
            
            // 4. Fetch Tickers from SwiftData to get presentation data
            guard let context = createModelContext() else {
                return []
            }
            
            let descriptor = FetchDescriptor<Ticker>()
            guard let allTickers = try? context.fetch(descriptor) else {
                return []
            }
            
            // 5. Build mapping from AlarmKit alarm IDs to Ticker objects
            // Similar to AlarmSynchronizationService mapping logic
            var alarmKitIDsToTicker: [UUID: Ticker] = [:]
            
            // Map main ticker IDs
            for ticker in allTickers {
                alarmKitIDsToTicker[ticker.id] = ticker
            }
            
            // Map generated alarm IDs (for collection schedules)
            for ticker in allTickers {
                for generatedID in ticker.generatedAlarmKitIDs {
                    // Warn if we're overwriting an existing mapping (shouldn't happen with unique UUIDs)
                    if let existingTicker = alarmKitIDsToTicker[generatedID], existingTicker.id != ticker.id {
                        print("⚠️ WidgetDataFetcher: Generated ID \(generatedID) already mapped to different ticker")
                        print("   → Existing: \(existingTicker.id) (\(existingTicker.displayName))")
                        print("   → New: \(ticker.id) (\(ticker.displayName))")
                    }
                    alarmKitIDsToTicker[generatedID] = ticker
                }
            }
            
            // 6. Create presentations by matching AlarmKit alarms to Tickers
            var upcomingAlarms: [UpcomingAlarmPresentation] = []
            
            for (alarm, alertingTime) in upcomingAlarmKitAlarms {
                // Find the matching Ticker
                guard let ticker = alarmKitIDsToTicker[alarm.id] else {
                    // Skip alarms that don't have a matching Ticker
                    continue
                }
                
                // Only include alarms from enabled tickers
                guard ticker.isEnabled else {
                    continue
                }
                
                // Calculate actual alarm time (accounting for countdown)
                // When a countdown exists, AlarmKit schedules at countdown start time,
                // but we want to display the actual alarm time
                let actualAlarmTime: Date
                if let countdownDuration = ticker.countdown?.preAlert?.interval {
                    // Add countdown duration back to get the actual alarm time
                    actualAlarmTime = alertingTime.addingTimeInterval(countdownDuration)
                } else {
                    actualAlarmTime = alertingTime
                }
                
                // Extract time components from actual alarm time
                let hour = calendar.component(.hour, from: actualAlarmTime)
                let minute = calendar.component(.minute, from: actualAlarmTime)
                
                // Map schedule type from Ticker's schedule
                let scheduleType: UpcomingAlarmPresentation.ScheduleType = {
                    guard let schedule = ticker.schedule else {
                        return .oneTime // Default fallback
                    }
                    
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
                    nextAlarmTime: actualAlarmTime,
                    scheduleType: scheduleType,
                    hour: hour,
                    minute: minute,
                    hasCountdown: ticker.countdown?.preAlert != nil,
                    tickerDataTitle: ticker.tickerData?.name
                )
                
                upcomingAlarms.append(presentation)
            }
            
            // 7. Sort by next alarm time
            upcomingAlarms.sort { $0.nextAlarmTime < $1.nextAlarmTime }
            
            // 8. Apply limit if specified
            if let limit = limit {
                upcomingAlarms = Array(upcomingAlarms.prefix(limit))
            }
            
            return upcomingAlarms
        }.value
    }

    /// Fetches the next upcoming alarm
    /// - Parameter withinHours: Time window in hours to search
    /// - Returns: Next alarm presentation or nil if no alarms found
    public static func fetchNextAlarm(withinHours: Int = 24) async -> UpcomingAlarmPresentation? {
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
