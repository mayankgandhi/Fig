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
    var notes: String = ""
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
        notes = alarm.notes ?? ""
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
    }

    private func dateFromTime(_ time: TickerSchedule.TimeOfDay) -> Date {
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Validation
    var isValid: Bool {
        // Must have a label or schedule
        !label.isEmpty || scheduleType != nil
    }

    // MARK: - Save Alarm
    func saveAlarm(context: ModelContext) throws {
        let schedule = buildSchedule()
        let countdown = buildCountdown()
        let presentation = buildPresentation()

        if let existing = existingAlarm {
            // Update existing alarm
            existing.label = label
            existing.notes = notes.isEmpty ? nil : notes
            existing.schedule = schedule
            existing.countdown = countdown
            existing.presentation = presentation
            existing.isEnabled = isEnabled
        } else {
            // Create new alarm
            let alarm = AlarmItem(
                label: label,
                isEnabled: isEnabled,
                notes: notes.isEmpty ? nil : notes,
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
}
