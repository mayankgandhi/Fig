//
//  Ticker.swift
//  fig
//
//  SwiftData model for persistent alarm storage
//

import Foundation
import SwiftData
import AlarmKit

// MARK: - Ticker Model

@Model
public final class Ticker {
    public var id: UUID
    public var label: String
    public var createdAt: Date
    public var isEnabled: Bool

    // Schedule - stored as JSON Data to support complex enum with arrays
    @Attribute(.externalStorage)
    private var scheduleData: Data?

    public var schedule: TickerSchedule? {
        get {
            guard let data = scheduleData else { return nil }
            return try? JSONDecoder().decode(TickerSchedule.self, from: data)
        }
        set {
            scheduleData = try? JSONEncoder().encode(newValue)
        }
    }

    // Countdown/Pre-alert
    public var countdown: TickerCountdown?

    // Presentation
    public var presentation: TickerPresentation

    // Sound
    public var soundName: String? // nil = system default, or custom sound file name

    // Template metadata
    public var tickerData: TickerData?

    // AlarmKit Integration
    public var generatedAlarmKitIDs: [UUID] = [] // Multiple alarm IDs for composite schedules

    // Alarm Regeneration
    public var lastRegenerationDate: Date? // When alarms were last regenerated
    public var lastRegenerationSuccess: Bool = false // Whether last regeneration succeeded
    public var nextScheduledRegeneration: Date? // When next regeneration should occur

    // Regeneration strategy - stored as JSON Data to support enum
    @Attribute(.externalStorage)
    private var regenerationStrategyData: Data?

    public var regenerationStrategy: AlarmGenerationStrategy {
        get {
            guard let data = regenerationStrategyData else {
                // Auto-detect strategy from schedule
                if let schedule = schedule {
                    return AlarmGenerationStrategy.determineStrategy(for: schedule)
                }
                return .mediumFrequency  // Default fallback
            }
            return (try? JSONDecoder().decode(AlarmGenerationStrategy.self, from: data)) ?? .mediumFrequency
        }
        set {
            regenerationStrategyData = try? JSONEncoder().encode(newValue)
        }
    }

    public init(
        id: UUID = UUID(),
        label: String,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init(),
        soundName: String? = nil,
        tickerData: TickerData? = nil,
        regenerationStrategy: AlarmGenerationStrategy? = nil
    ) {
        self.id = id
        self.label = label
        self.createdAt = Date.now
        self.isEnabled = isEnabled
        self.scheduleData = try? JSONEncoder().encode(schedule)
        self.countdown = countdown
        self.presentation = presentation
        self.soundName = soundName
        self.tickerData = tickerData
        self.generatedAlarmKitIDs = []

        // Regeneration properties
        self.lastRegenerationDate = nil
        self.lastRegenerationSuccess = false
        self.nextScheduledRegeneration = nil

        // Set regeneration strategy if provided, otherwise will auto-detect from schedule
        if let strategy = regenerationStrategy {
            self.regenerationStrategyData = try? JSONEncoder().encode(strategy)
        } else {
            self.regenerationStrategyData = nil
        }
    }

    public var displayName: String {
        label.isEmpty ? "Alarm" : label
    }

    public var icon: String {
        "alarm"
    }

    // MARK: - Computed Properties for Regeneration

    /// Check if this ticker needs alarm regeneration
    public var needsRegeneration: Bool {
        // Disabled tickers don't need regeneration
        guard isEnabled else { return false }

        // Never regenerated before
        guard let lastRegenDate = lastRegenerationDate else {
            return true
        }

        // Last regeneration failed
        guard lastRegenerationSuccess else {
            return true
        }

        // Check staleness threshold based on strategy
        let staleness = Date().timeIntervalSince(lastRegenDate)
        if staleness > regenerationStrategy.regenerationThreshold {
            return true
        }

        // Check if scheduled regeneration time has passed
        if let nextRegen = nextScheduledRegeneration, Date() >= nextRegen {
            return true
        }

        return false
    }

}

// MARK: - TickerSchedule

public enum TickerSchedule: Codable, Hashable {
    case oneTime(date: Date)
    case daily(time: TimeOfDay)
    case hourly(interval: Int, time: TimeOfDay)
    case every(interval: Int, unit: TimeUnit, time: TimeOfDay)
    case weekdays(time: TimeOfDay, days: Array<Weekday>)
    case biweekly(time: TimeOfDay, weekdays: Array<Weekday>)
    case monthly(day: MonthlyDay, time: TimeOfDay)
    case yearly(month: Int, day: Int, time: TimeOfDay)

    public struct TimeOfDay: Codable, Hashable {
        public var hour: Int // 0-23
        public var minute: Int // 0-59

        public init(hour: Int, minute: Int) {
            self.hour = hour
            self.minute = minute
        }

        public init(from date: Date) {
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            self.hour = components.hour ?? 0
            self.minute = components.minute ?? 0
        }
        
        public func addingTimeInterval(_ interval: TimeInterval) -> TimeOfDay {
            let totalMinutes = hour * 60 + minute
            let intervalMinutes = Int(interval / 60)
            let newTotalMinutes = totalMinutes + intervalMinutes
            
            // Handle day rollover - ensure we stay within 24-hour range
            let adjustedMinutes = ((newTotalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60)
            let newHour = adjustedMinutes / 60
            let newMinute = adjustedMinutes % 60
            
            return TimeOfDay(hour: newHour, minute: newMinute)
        }
    }

    public enum Weekday: Int, Codable, Hashable, CaseIterable {
        case sunday = 0
        case monday = 1
        case tuesday = 2
        case wednesday = 3
        case thursday = 4
        case friday = 5
        case saturday = 6
        
        var shortName: String {
            switch self {
                case .sunday: return "Sun"
                case .monday: return "Mon"
                case .tuesday: return "Tue"
                case .wednesday: return "Wed"
                case .thursday: return "Thu"
                case .friday: return "Fri"
                case .saturday: return "Sat"
            }
        }
    }

    public enum MonthlyDay: Codable, Hashable {
        case fixed(Int) // 1-31
        case firstWeekday(Weekday)
        case lastWeekday(Weekday)
        case firstOfMonth
        case lastOfMonth
    }

    public enum TimeUnit: String, Codable, Hashable, CaseIterable {
        case minutes = "Minutes"
        case hours = "Hours"
        case days = "Days"
        case weeks = "Weeks"

        public var displayName: String {
            rawValue
        }

        public var singularName: String {
            switch self {
            case .minutes: return "minute"
            case .hours: return "hour"
            case .days: return "day"
            case .weeks: return "week"
            }
        }
    }
}

// MARK: - Weekday Display Extensions

extension TickerSchedule {
    public var icon: String {
        switch self {
            case .oneTime: return "calendar"
            case .daily: return "repeat"
            case .hourly: return "clock"
            case .weekdays: return "calendar.badge.clock"
            case .biweekly: return "calendar.badge.clock"
            case .every: return "calendar.badge.clock"
            case .monthly: return "calendar.circle"
            case .yearly: return "calendar.badge.exclamationmark"
        }
    }
}

extension TickerSchedule.Weekday {
    public var localeWeekday: Locale.Weekday {
        switch self {
        case .sunday: return .sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        }
    }

    public var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    public var shortDisplayName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

// MARK: - TickerSchedule Display Extensions

public extension TickerSchedule {
    var displaySummary: String {
        switch self {
        case .oneTime(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)

        case .daily(let time):
            return "Daily at \(formatTime(time))"

        case .hourly(let interval, _):
            return "Every \(interval) hour\(interval == 1 ? "" : "s")"

        case .every(let interval, let unit, _):
            let unitName = interval == 1 ? unit.singularName : unit.displayName.lowercased()
            return "Every \(interval) \(unitName)"

        case .weekdays(let time, let days):
            let sortedDays = days.sorted { $0.rawValue < $1.rawValue }
            let dayNames = sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
            return "\(dayNames) at \(formatTime(time))"

        case .biweekly(let time, let weekdays):
            let sortedDays = weekdays.sorted { $0.rawValue < $1.rawValue }
            let dayNames = sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
            return "Biweekly \(dayNames) at \(formatTime(time))"

        case .monthly(let day, let time):
            let dayDesc: String
            switch day {
            case .fixed(let d):
                dayDesc = "Day \(d)"
            case .firstWeekday(let weekday):
                dayDesc = "First \(weekday.displayName)"
            case .lastWeekday(let weekday):
                dayDesc = "Last \(weekday.displayName)"
            case .firstOfMonth:
                dayDesc = "1st"
            case .lastOfMonth:
                dayDesc = "Last day"
            }
            return "Monthly \(dayDesc) at \(formatTime(time))"

        case .yearly(let month, let day, let time):
            let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return "Yearly \(monthNames[month - 1]) \(day) at \(formatTime(time))"
        }
    }

    private func formatTime(_ time: TimeOfDay) -> String {
        let hour = time.hour % 12 == 0 ? 12 : time.hour % 12
        let period = time.hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour, time.minute, period)
    }
}

// MARK: - TickerCountdown

public struct TickerCountdown: Codable, Hashable {
    public var preAlert: CountdownDuration?
    public var postAlert: PostAlertBehavior?
    
    public init(
        preAlert: CountdownDuration? = nil,
        postAlert: PostAlertBehavior? = nil
    ) {
        self.preAlert = preAlert
        self.postAlert = postAlert
    }

    public struct CountdownDuration: Codable, Hashable {
        public var hours: Int
        public var minutes: Int
        public var seconds: Int
        
        public init(hours: Int, minutes: Int, seconds: Int) {
            self.hours = hours
            self.minutes = minutes
            self.seconds = seconds
        }

        public var interval: TimeInterval {
            TimeInterval(hours * 3600 + minutes * 60 + seconds)
        }

        public static func fromInterval(_ interval: TimeInterval) -> CountdownDuration {
            let totalSeconds = Int(interval)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return CountdownDuration(hours: hours, minutes: minutes, seconds: seconds)
        }
    }

    public enum PostAlertBehavior: Codable, Hashable {
        case snooze(duration: CountdownDuration)
        case `repeat`(duration: CountdownDuration)
        case openApp

        // MARK: - Codable Conformance

        enum CodingKeys: String, CodingKey {
            case snooze
            case `repeat`
            case openApp
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Handle the case where the container is empty (corrupted data)
            if container.allKeys.isEmpty {
                // Default to nil by throwing a specific error that can be caught
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Empty PostAlertBehavior - treating as nil"
                    )
                )
            }

            // Decode based on which key is present
            if let duration = try? container.decode(CountdownDuration.self, forKey: .snooze) {
                self = .snooze(duration: duration)
            } else if let duration = try? container.decode(CountdownDuration.self, forKey: .repeat) {
                self = .repeat(duration: duration)
            } else if container.contains(.openApp) {
                self = .openApp
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Invalid PostAlertBehavior"
                    )
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .snooze(let duration):
                try container.encode(duration, forKey: .snooze)
            case .repeat(let duration):
                try container.encode(duration, forKey: .repeat)
            case .openApp:
                try container.encode(true, forKey: .openApp)
            }
        }
    }
}

// MARK: - Codable Conformance for TickerCountdown

extension TickerCountdown {
    enum CodingKeys: String, CodingKey {
        case preAlert
        case postAlert
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preAlert = try container.decodeIfPresent(CountdownDuration.self, forKey: .preAlert)

        // Safely decode postAlert, treating corrupted data as nil
        postAlert = try? container.decodeIfPresent(PostAlertBehavior.self, forKey: .postAlert)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(preAlert, forKey: .preAlert)
        try container.encodeIfPresent(postAlert, forKey: .postAlert)
    }
}

// MARK: - AlarmPresentation

public struct TickerPresentation: Codable, Hashable {
    public var tintColorHex: String?
    public var secondaryButtonType: SecondaryButtonType

    public enum SecondaryButtonType: String, Codable, Hashable {
        case none
        case countdown
        case openApp
    }

    public init(tintColorHex: String? = nil, secondaryButtonType: SecondaryButtonType = .openApp) {
        self.tintColorHex = tintColorHex
        self.secondaryButtonType = secondaryButtonType
    }
}

// MARK: - AlarmKit Conversion

extension Ticker {
    @available(iOS 26.0, *)
    public var alarmKitCountdownDuration: Alarm.CountdownDuration? {
        guard let countdown = countdown else { return nil }

        let preAlert = countdown.preAlert?.interval
        let postAlert: TimeInterval? = {
            switch countdown.postAlert {
            case .snooze(let duration), .repeat(let duration):
                return duration.interval
            case .openApp, .none:
                return nil
            }
        }()

        guard preAlert != nil || postAlert != nil else { return nil }
        return .init(preAlert: preAlert, postAlert: postAlert)
    }

    @available(iOS 26.0, *)
    public var alarmKitSchedule: Alarm.Schedule? {
        guard let schedule = schedule else { return nil }

        switch schedule {
        case .oneTime(let date):
            // If there's a countdown, schedule the alarm to start the countdown before the actual alarm time
            if let countdownDuration = countdown?.preAlert?.interval {
                let countdownStartDate = date.addingTimeInterval(-countdownDuration)
                return .fixed(countdownStartDate)
            }
            return .fixed(date)

        case .daily(let time):
            // If there's a countdown, adjust the time to start the countdown before the alarm time
            if let countdownDuration = countdown?.preAlert?.interval {
                let countdownStartTime = time.addingTimeInterval(-countdownDuration)
                let alarmTime = Alarm.Schedule.Relative.Time(hour: countdownStartTime.hour, minute: countdownStartTime.minute)
                return .relative(
                    .init(time: alarmTime, repeats: .weekly(TickerSchedule.Weekday.allCases.map{ $0.localeWeekday }))
                )
            } else {
                let alarmTime = Alarm.Schedule.Relative.Time(hour: time.hour, minute: time.minute)
                return .relative(
                    .init(time: alarmTime, repeats: .weekly(TickerSchedule.Weekday.allCases.map{ $0.localeWeekday }))
                )
            }

        default:
            // Composite schedules are expanded into multiple one-time alarms
            // by the TickerService, so they don't need direct AlarmKit mapping
            return nil
        }
    }

    @available(iOS 26.0, *)
    public var alarmKitSecondaryButtonBehavior: AlarmKit.AlarmPresentation.Alert.SecondaryButtonBehavior? {
        switch presentation.secondaryButtonType {
        case .none: return nil
        case .countdown: return .countdown
        case .openApp: return .custom
        }
    }
}

