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
    /// Default repeat/snooze countdown applied after an alert: 5 minutes.
    ///
    /// This is NOT the ringing duration — that is controlled by the system and
    /// cannot be configured. The old name and comment ("post-alert (ringing)
    /// duration") described behaviour AlarmKit does not have.
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

    /// The one predicate that decides whether this ticker has a countdown, used
    /// by both the presentation and the countdown duration.
    ///
    /// These used to disagree: `AlarmConfigurationBuilder.buildPresentation`
    /// gated on `countdown != nil` while `alarmKitCountdownDuration` gated on
    /// `countdown.preAlert != nil`. A ticker with a countdown but no pre-alert
    /// therefore handed AlarmKit a countdown *presentation* with a nil countdown
    /// *duration* — and, if the user picked the Repeat button, a `.countdown`
    /// secondary behavior with nothing to count.
    public var hasPreAlertCountdown: Bool {
        countdown?.preAlert != nil
    }

    @available(iOS 26.0, *)
    public var alarmKitCountdownDuration: Alarm.CountdownDuration? {
        guard let countdown = countdown else { return nil }

        let preAlert = countdown.preAlert?.interval

        // `postAlert` is the repeat/snooze countdown that runs *after* the alert.
        // It is not the ring duration — AlarmKit controls how long an alarm rings
        // and it is not configurable.
        let postAlert: TimeInterval? = {
            switch countdown.postAlert {
            case .snooze(let duration), .repeat(let duration):
                return duration.interval
            case .openApp:
                return TickerCountdown.defaultPostAlertInterval
            case .none:
                return nil
            }
        }()

        // Previously `guard preAlert != nil` discarded `postAlert` entirely for
        // any alarm without a pre-alert, so the snooze interval never reached
        // AlarmKit.
        guard preAlert != nil || postAlert != nil else { return nil }
        return .init(preAlert: preAlert, postAlert: postAlert)
    }

    /// True when AlarmKit can express this schedule natively, so it needs no
    /// expansion into disposable one-time alarms.
    ///
    /// This is the single source of truth for "is this a simple schedule?".
    /// Four separate copies of that question used to exist — two private
    /// `isSimpleSchedule` helpers plus the implicit ones inside
    /// `alarmKitSchedule` and `AlarmRegenerationService.queryCurrentAlarms` —
    /// and they could disagree.
    @available(iOS 26.0, *)
    public var usesNativeAlarmKitSchedule: Bool {
        alarmKitSchedule != nil
    }

    @available(iOS 26.0, *)
    public var alarmKitSchedule: Alarm.Schedule? {
        guard let schedule = schedule else { return nil }

        let preAlert = countdown?.preAlert?.interval

        switch schedule {
        case .oneTime(let date):
            // With a pre-alert, the alarm has to start counting down early.
            if let preAlert {
                return .fixed(date.addingTimeInterval(-preAlert))
            }
            return .fixed(date)

        case .daily(let time):
            return Ticker.relativeSchedule(
                time: time,
                days: TickerSchedule.Weekday.allCases,
                preAlertInterval: preAlert
            )

        case .weekdays(let time, let days):
            // AlarmKit's `Recurrence.weekly` takes an arbitrary weekday set, so
            // "Mon-Fri at 7am" maps natively and does not need the regeneration
            // pipeline at all. This case used to fall through to `default` and
            // return nil, which put the single most common alarm in the product
            // onto the expansion path — and therefore at the mercy of a
            // background task that was never scheduled.
            guard !days.isEmpty else { return nil }
            return Ticker.relativeSchedule(
                time: time,
                days: days,
                preAlertInterval: preAlert
            )

        case .hourly, .every, .biweekly, .monthly, .yearly:
            // Genuinely inexpressible in AlarmKit; expanded into one-time alarms
            // by AlarmRegenerationService.
            return nil
        }
    }

    /// Builds a weekly relative schedule, rotating the weekday set when the
    /// pre-alert pushes the start time back across midnight.
    ///
    /// Example: `.weekdays(00:30, [.monday])` with a 60-minute pre-alert must
    /// start at 23:30 on **Sunday**. Mapping the weekdays straight through would
    /// produce 23:30 on Monday and alert on Tuesday — a full day late, every week.
    @available(iOS 26.0, *)
    static func relativeSchedule(
        time: TimeOfDay,
        days: [TickerSchedule.Weekday],
        preAlertInterval: TimeInterval?
    ) -> Alarm.Schedule {
        let minutesInDay = 24 * 60
        let preAlertMinutes = Int((preAlertInterval ?? 0) / 60)
        let rawMinutes = time.hour * 60 + time.minute - preAlertMinutes

        // Floored division so negatives roll back a whole day.
        let dayOffset = Int(floor(Double(rawMinutes) / Double(minutesInDay)))
        let normalizedMinutes = ((rawMinutes % minutesInDay) + minutesInDay) % minutesInDay

        let startTime = Alarm.Schedule.Relative.Time(
            hour: normalizedMinutes / 60,
            minute: normalizedMinutes % 60
        )

        let rotatedDays: [Locale.Weekday] = days.map { day in
            let shifted = (((day.rawValue + dayOffset) % 7) + 7) % 7
            return (TickerSchedule.Weekday(rawValue: shifted) ?? day).localeWeekday
        }

        return .relative(.init(time: startTime, repeats: .weekly(rotatedDays)))
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

