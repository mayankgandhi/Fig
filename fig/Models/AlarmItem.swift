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
final class Ticker {
    var id: UUID
    var label: String
    var createdAt: Date
    var isEnabled: Bool

    // Schedule
    var schedule: TickerSchedule?

    // Countdown/Pre-alert
    var countdown: TickerCountdown?

    // Presentation
    var presentation: TickerPresentation

    // Category/Template metadata
    var tickerData: TickerData?

    // AlarmKit Integration
    var alarmKitID: UUID?

    init(
        id: UUID = UUID(),
        label: String,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init(),
        tickerData: TickerData? = nil
    ) {
        self.id = id
        self.label = label
        self.createdAt = Date.now
        self.isEnabled = isEnabled
        self.schedule = schedule
        self.countdown = countdown
        self.presentation = presentation
        self.tickerData = tickerData
    }

    var displayName: String {
        label.isEmpty ? "Alarm" : label
    }

    var icon: String {
        "alarm"
    }
}

// MARK: - TickerSchedule

enum TickerSchedule: Codable, Hashable {
    case oneTime(date: Date)
    case daily(time: TimeOfDay)

    struct TimeOfDay: Codable, Hashable {
        var hour: Int // 0-23
        var minute: Int // 0-59

        init(hour: Int, minute: Int) {
            self.hour = hour
            self.minute = minute
        }

        init(from date: Date) {
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            self.hour = components.hour ?? 0
            self.minute = components.minute ?? 0
        }
    }

    enum Weekday: Int, Codable, Hashable, CaseIterable {
        case sunday = 0
        case monday = 1
        case tuesday = 2
        case wednesday = 3
        case thursday = 4
        case friday = 5
        case saturday = 6

        var localeWeekday: Locale.Weekday {
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
    }
}

// MARK: - TickerCountdown

struct TickerCountdown: Codable, Hashable {
    var preAlert: CountdownDuration?
    var postAlert: PostAlertBehavior?

    struct CountdownDuration: Codable, Hashable {
        var hours: Int
        var minutes: Int
        var seconds: Int

        var interval: TimeInterval {
            TimeInterval(hours * 3600 + minutes * 60 + seconds)
        }

        static func fromInterval(_ interval: TimeInterval) -> CountdownDuration {
            let totalSeconds = Int(interval)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return CountdownDuration(hours: hours, minutes: minutes, seconds: seconds)
        }
    }

    enum PostAlertBehavior: Codable, Hashable {
        case snooze(duration: CountdownDuration)
        case `repeat`(duration: CountdownDuration)
        case openApp

        // MARK: - Codable Conformance

        enum CodingKeys: String, CodingKey {
            case snooze
            case `repeat`
            case openApp
        }

        init(from decoder: Decoder) throws {
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

        func encode(to encoder: Encoder) throws {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preAlert = try container.decodeIfPresent(CountdownDuration.self, forKey: .preAlert)

        // Safely decode postAlert, treating corrupted data as nil
        postAlert = try? container.decodeIfPresent(PostAlertBehavior.self, forKey: .postAlert)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(preAlert, forKey: .preAlert)
        try container.encodeIfPresent(postAlert, forKey: .postAlert)
    }
}

// MARK: - AlarmPresentation

struct TickerPresentation: Codable, Hashable {
    var tintColorHex: String?
    var secondaryButtonType: SecondaryButtonType

    enum SecondaryButtonType: String, Codable, Hashable {
        case none
        case countdown
        case openApp
    }

    init(tintColorHex: String? = nil, secondaryButtonType: SecondaryButtonType = .none) {
        self.tintColorHex = tintColorHex
        self.secondaryButtonType = secondaryButtonType
    }
}

// MARK: - AlarmKit Conversion

extension Ticker {
    var alarmKitCountdownDuration: Alarm.CountdownDuration? {
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

    var alarmKitSchedule: Alarm.Schedule? {
        guard let schedule = schedule else { return nil }

        switch schedule {
        case .oneTime(let date):
            return .fixed(date)

        case .daily(let time):
            let alarmTime = Alarm.Schedule.Relative.Time(hour: time.hour, minute: time.minute)
            return .relative(
                .init(time: alarmTime, repeats: .weekly(TickerSchedule.Weekday.allCases.map{ $0.localeWeekday }))
            )
        }
    }

    var alarmKitSecondaryButtonBehavior: AlarmKit.AlarmPresentation.Alert.SecondaryButtonBehavior? {
        switch presentation.secondaryButtonType {
        case .none: return nil
        case .countdown: return .countdown
        case .openApp: return .custom
        }
    }
}
