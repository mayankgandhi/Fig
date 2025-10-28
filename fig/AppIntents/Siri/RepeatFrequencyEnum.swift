//
//  RepeatFrequencyEnum.swift
//  fig
//
//  Enum for repeat frequency parameter in Siri intents
//

import Foundation
import AppIntents

/// Enum representing different repeat frequencies for ticker creation
enum RepeatFrequencyEnum: String, CaseIterable, AppEnum {
    case oneTime = "oneTime"
    case daily = "daily"
    case weekdays = "weekdays"
    case weekends = "weekends"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Repeat Frequency"
    }
    
    static var caseDisplayRepresentations: [RepeatFrequencyEnum: DisplayRepresentation] {
        [
            .oneTime: "One Time",
            .daily: "Daily",
            .weekdays: "Weekdays",
            .weekends: "Weekends"
        ]
    }
    
    /// Convert to TickerSchedule
    func toTickerSchedule(time: TickerSchedule.TimeOfDay) -> TickerSchedule {
        switch self {
        case .oneTime:
            // For one-time, we'll need the actual date - this will be handled in the intent
            let calendar = Calendar.current
            let today = Date()
            var components = calendar.dateComponents([.year, .month, .day], from: today)
            components.hour = time.hour
            components.minute = time.minute
            let date = calendar.date(from: components) ?? today
            return .oneTime(date: date)
            
        case .daily:
            return .daily(time: time)
            
        case .weekdays:
            return .weekdays(
                time: time,
                days: [.monday, .tuesday, .wednesday, .thursday, .friday]
            )
            
        case .weekends:
            return .weekdays(
                time: time,
                days: [.saturday, .sunday]
            )
        }
    }
}
