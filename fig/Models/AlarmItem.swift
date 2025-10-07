//
//  AlarmItem.swift
//  fig
//
//  SwiftData model for persistent alarm storage
//

import Foundation
import SwiftData
import AlarmKit

// MARK: - Base AlarmItem Class

@Model
class AlarmItem {
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

    // AlarmKit Integration
    var alarmKitID: UUID?
    var lastTriggered: Date?

    init(
        id: UUID = UUID(),
        label: String,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.id = id
        self.label = label
        self.createdAt = Date.now
        self.isEnabled = isEnabled
        self.schedule = schedule
        self.countdown = countdown
        self.presentation = presentation
    }

    // To be overridden by subclasses
    var displayName: String { label.isEmpty ? "Alarm" : label }
    var icon: String { "alarm" }
    var categoryName: String { "General" }
}

// MARK: - Category Subclasses

@Model
final class GeneralAlarm: AlarmItem {
    var notes: String?

    init(
        id: UUID = UUID(),
        label: String,
        notes: String? = nil,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.notes = notes
        super.init(
            id: id,
            label: label,
            isEnabled: isEnabled,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation
        )
    }

    override var categoryName: String { "General" }
}

@Model
final class BirthdayAlarm: AlarmItem {
    var personName: String
    var notes: String?

    init(
        id: UUID = UUID(),
        label: String,
        personName: String,
        notes: String? = nil,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.personName = personName
        self.notes = notes
        super.init(
            id: id,
            label: label,
            isEnabled: isEnabled,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation
        )
    }

    override var displayName: String {
        label.isEmpty ? "\(personName)'s Birthday" : label
    }

    override var icon: String { "gift" }
    override var categoryName: String { "Birthday" }
}

@Model
final class BillPaymentAlarm: AlarmItem {
    var accountName: String
    var amount: Double?
    var dueDay: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        label: String,
        accountName: String,
        amount: Double? = nil,
        dueDay: Int? = nil,
        notes: String? = nil,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.accountName = accountName
        self.amount = amount
        self.dueDay = dueDay
        self.notes = notes
        super.init(
            id: id,
            label: label,
            isEnabled: isEnabled,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation
        )
    }

    override var displayName: String {
        label.isEmpty ? "\(accountName) Bill" : label
    }

    override var icon: String { "dollarsign.circle" }
    override var categoryName: String { "Bill Payment" }
}

@Model
final class CreditCardAlarm: AlarmItem {
    var cardName: String
    var amount: Double?
    var dueDay: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        label: String,
        cardName: String,
        amount: Double? = nil,
        dueDay: Int? = nil,
        notes: String? = nil,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.cardName = cardName
        self.amount = amount
        self.dueDay = dueDay
        self.notes = notes
        super.init(
            id: id,
            label: label,
            isEnabled: isEnabled,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation
        )
    }

    override var displayName: String {
        label.isEmpty ? "\(cardName) Payment" : label
    }

    override var icon: String { "creditcard" }
    override var categoryName: String { "Credit Card" }
}

@Model
final class SubscriptionAlarm: AlarmItem {
    var serviceName: String
    var amount: Double?
    var renewalDay: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        label: String,
        serviceName: String,
        amount: Double? = nil,
        renewalDay: Int? = nil,
        notes: String? = nil,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.serviceName = serviceName
        self.amount = amount
        self.renewalDay = renewalDay
        self.notes = notes
        super.init(
            id: id,
            label: label,
            isEnabled: isEnabled,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation
        )
    }

    override var displayName: String {
        label.isEmpty ? "\(serviceName) Subscription" : label
    }

    override var icon: String { "arrow.clockwise" }
    override var categoryName: String { "Subscription" }
}

@Model
final class AppointmentAlarm: AlarmItem {
    var location: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        label: String,
        location: String? = nil,
        notes: String? = nil,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.location = location
        self.notes = notes
        super.init(
            id: id,
            label: label,
            isEnabled: isEnabled,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation
        )
    }

    override var displayName: String {
        if !label.isEmpty { return label }
        return location.map { "Appointment at \($0)" } ?? "Appointment"
    }

    override var icon: String { "calendar" }
    override var categoryName: String { "Appointment" }
}

@Model
final class MedicationAlarm: AlarmItem {
    var medicationName: String
    var dosage: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        label: String,
        medicationName: String,
        dosage: String? = nil,
        notes: String? = nil,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.medicationName = medicationName
        self.dosage = dosage
        self.notes = notes
        super.init(
            id: id,
            label: label,
            isEnabled: isEnabled,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation
        )
    }

    override var displayName: String {
        label.isEmpty ? medicationName : label
    }

    override var icon: String { "pills" }
    override var categoryName: String { "Medication" }
}

@Model
final class CustomAlarm: AlarmItem {
    var iconName: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        label: String,
        iconName: String? = nil,
        notes: String? = nil,
        isEnabled: Bool = true,
        schedule: TickerSchedule? = nil,
        countdown: TickerCountdown? = nil,
        presentation: TickerPresentation = .init()
    ) {
        self.iconName = iconName
        self.notes = notes
        super.init(
            id: id,
            label: label,
            isEnabled: isEnabled,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation
        )
    }

    override var displayName: String {
        label.isEmpty ? "Custom Alarm" : label
    }

    override var icon: String { iconName ?? "star" }
    override var categoryName: String { "Custom" }
}

// MARK: - TickerSchedule

enum TickerSchedule: Codable, Hashable {
    case oneTime(date: Date)
    case daily(time: TimeOfDay)
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
