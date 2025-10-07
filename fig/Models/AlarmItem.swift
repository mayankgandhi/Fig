//
//  AlarmItem.swift
//  fig
//
//  SwiftData model for persistent alarm storage
//

import Foundation
import SwiftData
import AlarmKit

@Model
final class AlarmItem {
    var id: UUID
    var label: String
    var createdAt: Date
    var isEnabled: Bool

    // Category
    var category: TickerCategory

    // Schedule
    var schedule: TickerSchedule?

    // Countdown/Pre-alert
    var countdown: TickerCountdown?

    // Presentation
    var presentation: TickerPresentation

    // AlarmKit Integration
    var alarmKitID: UUID?
    var lastTriggered: Date?

    init(
        id: UUID = UUID(),
        label: String,
        category: TickerCategory = .general(),
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.id = id
        self.label = label
        self.createdAt = Date.now
        self.isEnabled = isEnabled
        self.category = category
        self.schedule = schedule
        self.countdown = countdown
        self.presentation = presentation
    }
}

// MARK: - TickerCategory

enum TickerCategory: Codable, Hashable {
    case general(notes: String? = nil)
    case birthday(personName: String, notes: String? = nil)
    case billPayment(accountName: String, amount: Double? = nil, dueDay: Int? = nil, notes: String? = nil)
    case creditCard(cardName: String, amount: Double? = nil, dueDay: Int? = nil, notes: String? = nil)
    case subscription(serviceName: String, amount: Double? = nil, renewalDay: Int? = nil, notes: String? = nil)
    case appointment(location: String? = nil, notes: String? = nil)
    case medication(medicationName: String, dosage: String? = nil, notes: String? = nil)
    case custom(iconName: String? = nil, notes: String? = nil)

    var displayName: String {
        switch self {
        case .general: return "General"
        case .birthday: return "Birthday"
        case .billPayment: return "Bill Payment"
        case .creditCard: return "Credit Card"
        case .subscription: return "Subscription"
        case .appointment: return "Appointment"
        case .medication: return "Medication"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .general: return "alarm"
        case .birthday: return "gift"
        case .billPayment: return "dollarsign.circle"
        case .creditCard: return "creditcard"
        case .subscription: return "arrow.clockwise"
        case .appointment: return "calendar"
        case .medication: return "pills"
        case .custom(let iconName, _): return iconName ?? "star"
        }
    }
}

// MARK: - TickerSchedule

enum TickerSchedule: Codable, Hashable {
    case oneTime(date: Date)
    case daily(time: TimeOfDay)
//    case weekly(time: TimeOfDay, weekdays: [Weekday])
    case monthly(time: TimeOfDay, day: Int) // day: 1-31
    case yearly(month: Int, day: Int, time: TimeOfDay) // For birthdays, anniversaries

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

// MARK: - Computed Properties

extension AlarmItem {
    var displayLabel: String {
        if !label.isEmpty {
            return label
        }

        switch category {
        case .general:
            return "Alarm"
        case .birthday(let personName, _):
            return "\(personName)'s Birthday"
        case .billPayment(let accountName, _, _, _):
            return "\(accountName) Bill"
        case .creditCard(let cardName, _, _, _):
            return "\(cardName) Payment"
        case .subscription(let serviceName, _, _, _):
            return "\(serviceName) Subscription"
        case .appointment(let location, _):
            return location.map { "Appointment at \($0)" } ?? "Appointment"
        case .medication(let medicationName, _, _):
            return medicationName
        case .custom:
            return "Custom Alarm"
        }
    }
}

// MARK: - AlarmKit Conversion

extension AlarmItem {
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

//        case .weekly(let time, let weekdays):
//            let alarmTime = Alarm.Schedule.Relative.Time(hour: time.hour, minute: time.minute)
//            let localeWeekdays = weekdays.map { $0.localeWeekday }
//            return .relative(.init(time: alarmTime, repeats: .weekly(Array(localeWeekdays))))

        case .monthly(let time, _):
            // AlarmKit doesn't support monthly directly, use weekly for now
            let alarmTime = Alarm.Schedule.Relative.Time(hour: time.hour, minute: time.minute)
            return .relative(.init(time: alarmTime, repeats: .never))

        case .yearly(_, _, let time):
            // For yearly (birthdays), schedule as one-time or daily
            let alarmTime = Alarm.Schedule.Relative.Time(hour: time.hour, minute: time.minute)
            return .relative(.init(time: alarmTime, repeats: .never))
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
