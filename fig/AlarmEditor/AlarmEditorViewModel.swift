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
    var selectedCategoryType: String = "General"
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
        selectedCategoryType = alarm.categoryName
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
        loadCategorySpecificProperties(from: alarm)
    }

    private func loadCategorySpecificProperties(from alarm: AlarmItem) {
        if let general = alarm as? GeneralAlarm {
            notes = general.notes ?? ""
        } else if let birthday = alarm as? BirthdayAlarm {
            personName = birthday.personName
            notes = birthday.notes ?? ""
        } else if let billPayment = alarm as? BillPaymentAlarm {
            accountName = billPayment.accountName
            amount = billPayment.amount.map { String($0) } ?? ""
            notes = billPayment.notes ?? ""
        } else if let creditCard = alarm as? CreditCardAlarm {
            accountName = creditCard.cardName
            amount = creditCard.amount.map { String($0) } ?? ""
            notes = creditCard.notes ?? ""
        } else if let subscription = alarm as? SubscriptionAlarm {
            accountName = subscription.serviceName
            amount = subscription.amount.map { String($0) } ?? ""
            notes = subscription.notes ?? ""
        } else if let appointment = alarm as? AppointmentAlarm {
            location = appointment.location ?? ""
            notes = appointment.notes ?? ""
        } else if let medication = alarm as? MedicationAlarm {
            medicationName = medication.medicationName
            dosage = medication.dosage ?? ""
            notes = medication.notes ?? ""
        } else if let custom = alarm as? CustomAlarm {
            customIcon = custom.iconName ?? "star"
            notes = custom.notes ?? ""
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
        switch selectedCategoryType {
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
        let presentation = buildPresentation()

        if let existing = existingAlarm {
            // Update existing alarm (need to replace with new instance if type changed)
            if existing.categoryName != selectedCategoryType {
                // Category changed - need to create new alarm of different type
                context.delete(existing)
                let newAlarm = createNewAlarm(
                    schedule: schedule,
                    countdown: countdown,
                    presentation: presentation
                )
                context.insert(newAlarm)
            } else {
                // Same category - update in place
                existing.label = label
                existing.schedule = schedule
                existing.countdown = countdown
                existing.presentation = presentation
                existing.isEnabled = isEnabled
                updateCategorySpecificProperties(for: existing)
            }
        } else {
            // Create new alarm
            let alarm = createNewAlarm(
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
            context.insert(alarm)
        }

        try context.save()
    }

    private func createNewAlarm(
        schedule: TickerSchedule?,
        countdown: TickerCountdown?,
        presentation: TickerPresentation
    ) -> AlarmItem {
        let notesValue = notes.isEmpty ? nil : notes

        switch selectedCategoryType {
        case "General":
            return GeneralAlarm(
                label: label,
                notes: notesValue,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
        case "Birthday":
            return BirthdayAlarm(
                label: label,
                personName: personName,
                notes: notesValue,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
        case "Bill Payment":
            return BillPaymentAlarm(
                label: label,
                accountName: accountName,
                amount: Double(amount),
                dueDay: scheduleType == .monthly ? monthlyDay : nil,
                notes: notesValue,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
        case "Credit Card":
            return CreditCardAlarm(
                label: label,
                cardName: accountName,
                amount: Double(amount),
                dueDay: scheduleType == .monthly ? monthlyDay : nil,
                notes: notesValue,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
        case "Subscription":
            return SubscriptionAlarm(
                label: label,
                serviceName: accountName,
                amount: Double(amount),
                renewalDay: scheduleType == .monthly ? monthlyDay : nil,
                notes: notesValue,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
        case "Appointment":
            return AppointmentAlarm(
                label: label,
                location: location.isEmpty ? nil : location,
                notes: notesValue,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
        case "Medication":
            return MedicationAlarm(
                label: label,
                medicationName: medicationName,
                dosage: dosage.isEmpty ? nil : dosage,
                notes: notesValue,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
        case "Custom":
            return CustomAlarm(
                label: label,
                iconName: customIcon.isEmpty ? nil : customIcon,
                notes: notesValue,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
        default:
            return GeneralAlarm(
                label: label,
                notes: notesValue,
                isEnabled: isEnabled,
                schedule: schedule,
                countdown: countdown,
                presentation: presentation
            )
        }
    }

    private func updateCategorySpecificProperties(for alarm: AlarmItem) {
        let notesValue = notes.isEmpty ? nil : notes

        if let general = alarm as? GeneralAlarm {
            general.notes = notesValue
        } else if let birthday = alarm as? BirthdayAlarm {
            birthday.personName = personName
            birthday.notes = notesValue
        } else if let billPayment = alarm as? BillPaymentAlarm {
            billPayment.accountName = accountName
            billPayment.amount = Double(amount)
            billPayment.dueDay = scheduleType == .monthly ? monthlyDay : nil
            billPayment.notes = notesValue
        } else if let creditCard = alarm as? CreditCardAlarm {
            creditCard.cardName = accountName
            creditCard.amount = Double(amount)
            creditCard.dueDay = scheduleType == .monthly ? monthlyDay : nil
            creditCard.notes = notesValue
        } else if let subscription = alarm as? SubscriptionAlarm {
            subscription.serviceName = accountName
            subscription.amount = Double(amount)
            subscription.renewalDay = scheduleType == .monthly ? monthlyDay : nil
            subscription.notes = notesValue
        } else if let appointment = alarm as? AppointmentAlarm {
            appointment.location = location.isEmpty ? nil : location
            appointment.notes = notesValue
        } else if let medication = alarm as? MedicationAlarm {
            medication.medicationName = medicationName
            medication.dosage = dosage.isEmpty ? nil : dosage
            medication.notes = notesValue
        } else if let custom = alarm as? CustomAlarm {
            custom.iconName = customIcon.isEmpty ? nil : customIcon
            custom.notes = notesValue
        }
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
        selectedCategoryType
    }

    func updateCategory(_ categoryType: String) {
        selectedCategoryType = categoryType
    }
}
