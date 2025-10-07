//
//  AlarmEditorViewModel.swift
//  fig
//
//  Observable view model for alarm editing
//

import Foundation
import SwiftUI
import SwiftData
import AlarmKit

@Observable
class AlarmEditorViewModel {
    // MARK: - Basic Properties
    var label: String = ""
    var selectedCategory: TickerCategory = .general()
    var tintColorHex: String = "#FF6B6B"
    var isEnabled: Bool = true

    // MARK: - Schedule Properties
    var scheduleType: ScheduleType?
    var selectedDate: Date? = Date()
    var selectedTime: Date? = Date()
    var selectedWeekdays: Array<TickerSchedule.Weekday> = []
    var monthlyDay: Int = 1
    var yearlyMonth: Int = 1
    var yearlyDay: Int = 1

    // MARK: - Countdown Properties
    var preAlertEnabled: Bool = false
    var preAlertHours: Int = 0
    var preAlertMinutes: Int = 15
    var preAlertSeconds: Int = 0

    // MARK: - Post-Alert Properties
    var postAlertType: PostAlertType?
    var postAlertHours: Int = 0
    var postAlertMinutes: Int = 5
    var postAlertSeconds: Int = 0

    // MARK: - Category-Specific Properties
    var personName: String = ""
    var accountName: String = ""
    var amount: String = ""
    var location: String = ""
    var medicationName: String = ""
    var dosage: String = ""
    var notes: String = ""
    var customIcon: String = "star"

    // MARK: - Existing Alarm (for editing)
    private var existingAlarm: AlarmItem?

    // MARK: - Enums
    enum ScheduleType: String, CaseIterable, CustomStringConvertible {
        case oneTime = "One Time"
        case daily = "Daily"
//        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"

        var description: String { rawValue }
    }

    enum PostAlertType: String, CaseIterable, CustomStringConvertible {
        case none = "None"
        case snooze = "Snooze"
        case `repeat` = "Repeat"
        case openApp = "Open App"

        var description: String { rawValue }
    }

    // MARK: - Initialization
    init(alarm: AlarmItem? = nil) {
        self.existingAlarm = alarm
        if let alarm = alarm {
            loadFromAlarm(alarm)
        }
    }

    // MARK: - Load from Existing Alarm
    private func loadFromAlarm(_ alarm: AlarmItem) {
        label = alarm.label
        selectedCategory = alarm.category
        tintColorHex = alarm.presentation.tintColorHex ?? "#FF6B6B"
        isEnabled = alarm.isEnabled

        // Load schedule
        if let schedule = alarm.schedule {
            switch schedule {
            case .oneTime(let date):
                scheduleType = .oneTime
                selectedDate = date
            case .daily(let time):
                scheduleType = .daily
                selectedTime = dateFromTime(time)
//            case .weekly(let time, let weekdays):
//                scheduleType = .weekly
//                selectedTime = dateFromTime(time)
//                selectedWeekdays = weekdays
            case .monthly(let time, let day):
                scheduleType = .monthly
                selectedTime = dateFromTime(time)
                monthlyDay = day
            case .yearly(let month, let day, let time):
                scheduleType = .yearly
                selectedTime = dateFromTime(time)
                yearlyMonth = month
                yearlyDay = day
            }
        }

        // Load countdown
        if let countdown = alarm.countdown {
            if let preAlert = countdown.preAlert {
                preAlertEnabled = true
                preAlertHours = preAlert.hours
                preAlertMinutes = preAlert.minutes
                preAlertSeconds = preAlert.seconds
            }

            if let postAlert = countdown.postAlert {
                switch postAlert {
                case .snooze(let duration):
                    postAlertType = .snooze
                    postAlertHours = duration.hours
                    postAlertMinutes = duration.minutes
                    postAlertSeconds = duration.seconds
                case .repeat(let duration):
                    postAlertType = .repeat
                    postAlertHours = duration.hours
                    postAlertMinutes = duration.minutes
                    postAlertSeconds = duration.seconds
                case .openApp:
                    postAlertType = .openApp
                }
            }
        }

        // Load category-specific properties
        loadCategorySpecificProperties(from: alarm.category)
    }

    private func loadCategorySpecificProperties(from category: TickerCategory) {
        switch category {
        case .general(let notes):
            self.notes = notes ?? ""
        case .birthday(let personName, let notes):
            self.personName = personName
            self.notes = notes ?? ""
        case .billPayment(let accountName, let amount, _, let notes),
             .creditCard(let accountName, let amount, _, let notes),
             .subscription(let accountName, let amount, _, let notes):
            self.accountName = accountName
            self.amount = amount.map { String($0) } ?? ""
            self.notes = notes ?? ""
        case .appointment(let location, let notes):
            self.location = location ?? ""
            self.notes = notes ?? ""
        case .medication(let medicationName, let dosage, let notes):
            self.medicationName = medicationName
            self.dosage = dosage ?? ""
            self.notes = notes ?? ""
        case .custom(let iconName, let notes):
            self.customIcon = iconName ?? "star"
            self.notes = notes ?? ""
        }
    }

    private func dateFromTime(_ time: TickerSchedule.TimeOfDay) -> Date {
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Validation
    var isValid: Bool {
        // Must have a schedule or pre-alert
        guard scheduleType != .oneTime || preAlertEnabled else { return false }

        // Validate category-specific requirements
        switch getCategoryType() {
        case "Birthday":
            return !personName.isEmpty
        case "Bill Payment", "Credit Card", "Subscription":
            return !accountName.isEmpty
        case "Medication":
            return !medicationName.isEmpty
        default:
            return true
        }
    }

    // MARK: - Save Alarm
    func saveAlarm(context: ModelContext) throws {
        let schedule = buildSchedule()
        let countdown = buildCountdown()
        let category = buildCategory()
        let presentation = buildPresentation()

        if let existing = existingAlarm {
            // Update existing alarm
            existing.label = label
            existing.category = category
            existing.schedule = schedule
            existing.countdown = countdown
            existing.presentation = presentation
            existing.isEnabled = isEnabled
        } else {
            // Create new alarm
            let alarm = AlarmItem(
                label: label,
                category: category,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
            context.insert(alarm)
        }

        try context.save()
    }

    // MARK: - Build Components
    private func buildSchedule() -> TickerSchedule? {
        guard let selectedTime else { return nil }
        let time = TickerSchedule.TimeOfDay(from: selectedTime)

        switch scheduleType {
        case .oneTime:
            guard let selectedDate else { return nil }
            return .oneTime(date: selectedDate)
        case .daily:
            return .daily(time: time)
//        case .weekly:
//            guard !selectedWeekdays.isEmpty else { return nil }
//            return .weekly(time: time, weekdays: selectedWeekdays)
        case .monthly:
            return .monthly(time: time, day: monthlyDay)
        case .yearly:
            return .yearly(month: yearlyMonth, day: yearlyDay, time: time)
        case .none: return nil
        }
    }

    private func buildCountdown() -> TickerCountdown? {
        var preAlert: TickerCountdown.CountdownDuration?
        var postAlert: TickerCountdown.PostAlertBehavior?

        if preAlertEnabled {
            preAlert = TickerCountdown.CountdownDuration(
                hours: preAlertHours,
                minutes: preAlertMinutes,
                seconds: preAlertSeconds
            )
        }

        switch postAlertType {
        case nil, .some(.none):
            postAlert = nil
        case .snooze:
            postAlert = .snooze(duration: TickerCountdown.CountdownDuration(
                hours: postAlertHours,
                minutes: postAlertMinutes,
                seconds: postAlertSeconds
            ))
        case .repeat:
            postAlert = .repeat(duration: TickerCountdown.CountdownDuration(
                hours: postAlertHours,
                minutes: postAlertMinutes,
                seconds: postAlertSeconds
            ))
        case .openApp:
            postAlert = .openApp
        }

        guard preAlert != nil || postAlert != nil else { return nil }
        return TickerCountdown(preAlert: preAlert, postAlert: postAlert)
    }

    private func buildCategory() -> TickerCategory {
        let categoryType = getCategoryType()
        let notesValue = notes.isEmpty ? nil : notes

        switch categoryType {
        case "General":
            return .general(notes: notesValue)
        case "Birthday":
            return .birthday(personName: personName, notes: notesValue)
        case "Bill Payment":
            return .billPayment(
                accountName: accountName,
                amount: Double(amount),
                dueDay: scheduleType == .monthly ? monthlyDay : nil,
                notes: notesValue
            )
        case "Credit Card":
            return .creditCard(
                cardName: accountName,
                amount: Double(amount),
                dueDay: scheduleType == .monthly ? monthlyDay : nil,
                notes: notesValue
            )
        case "Subscription":
            return .subscription(
                serviceName: accountName,
                amount: Double(amount),
                renewalDay: scheduleType == .monthly ? monthlyDay : nil,
                notes: notesValue
            )
        case "Appointment":
            return .appointment(location: location.isEmpty ? nil : location, notes: notesValue)
        case "Medication":
            return .medication(
                medicationName: medicationName,
                dosage: dosage.isEmpty ? nil : dosage,
                notes: notesValue
            )
        case "Custom":
            return .custom(iconName: customIcon.isEmpty ? nil : customIcon, notes: notesValue)
        default:
            return .general(notes: notesValue)
        }
    }

    private func buildPresentation() -> TickerPresentation {
        let secondaryButtonType: TickerPresentation.SecondaryButtonType = switch postAlertType {
        case nil: .none
        case .snooze, .repeat: .countdown
        case .openApp: .openApp
        case .some(.none): .none
        }

        return TickerPresentation(
            tintColorHex: tintColorHex,
            secondaryButtonType: secondaryButtonType
        )
    }

    // MARK: - Helpers
    func getCategoryType() -> String {
        switch selectedCategory {
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

    func updateCategory(_ categoryType: String) {
        switch categoryType {
        case "General": selectedCategory = .general()
        case "Birthday": selectedCategory = .birthday(personName: personName, notes: nil)
        case "Bill Payment": selectedCategory = .billPayment(accountName: accountName, amount: nil, dueDay: nil, notes: nil)
        case "Credit Card": selectedCategory = .creditCard(cardName: accountName, amount: nil, dueDay: nil, notes: nil)
        case "Subscription": selectedCategory = .subscription(serviceName: accountName, amount: nil, renewalDay: nil, notes: nil)
        case "Appointment": selectedCategory = .appointment(location: nil, notes: nil)
        case "Medication": selectedCategory = .medication(medicationName: medicationName, dosage: nil, notes: nil)
        case "Custom": selectedCategory = .custom(iconName: nil, notes: nil)
        default: selectedCategory = .general()
        }
    }
}
