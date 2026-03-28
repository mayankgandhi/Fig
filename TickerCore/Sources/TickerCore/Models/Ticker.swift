//
//  Ticker.swift
//  fig
//
//  SwiftData model for persistent alarm storage
//

import Foundation
import SwiftData
import AlarmKit
import SwiftUI

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
    public var generatedAlarmKitIDs: [UUID] = [] // Multiple alarm IDs for ticker collection schedules

    // TickerCollection Relationship (optional - only set if this is a child ticker)
    public var parentTickerCollection: TickerCollection?

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

// MARK: - TickerCountdown

public struct TickerCountdown: Codable, Hashable {
    /// Default post-alert (ringing) duration: 5 minutes
    public static let defaultPostAlertInterval: TimeInterval = 300

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
    
    public var tintColor: Color {
        guard let tintColorHex else {
            return TickerColor.primary
        }
        return Color(hex: tintColorHex) ?? TickerColor.primary
    }

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
        let postAlert: TimeInterval = {
            switch countdown.postAlert {
            case .snooze(let duration), .repeat(let duration):
                return duration.interval
            case .openApp, .none:
                return TickerCountdown.defaultPostAlertInterval
            }
        }()

        guard preAlert != nil else { return nil }
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
            // Collection schedules are expanded into multiple one-time alarms
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

