//
//  AlarmDetailOptionsSection.swift
//  fig
//
//  Options section component for AlarmDetailView showing alarm options as pills
//

import SwiftUI

struct AlarmDetailOptionsSection: View {
    let alarm: Ticker
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.lg) {
            // Enhanced pill layout with improved spacing and alignment
            FlowLayout(spacing: TickerSpacing.md) {
                // Calendar/Date option
                if let schedule = alarm.schedule {
                    TickerPill(
                        icon: "calendar.badge.clock",
                        title: dateDisplayText(for: schedule),
                        hasValue: true,
                        size: .standard
                    )
                }

                // Repeat option
                if let schedule = alarm.schedule {
                    TickerPill(
                        icon: "repeat",
                        title: repeatDisplayText(for: schedule),
                        hasValue: true,
                        size: .standard
                    )
                }

                // Label option
                TickerPill(
                    icon: "tag",
                    title: alarm.label,
                    hasValue: !alarm.label.isEmpty,
                    size: .standard
                )

                // Countdown option
                if let countdown = alarm.countdown?.preAlert {
                    TickerPill(
                        icon: "timer",
                        title: formatCountdown(countdown),
                        hasValue: true,
                        size: .standard
                    )
                }
                
                // Icon option with selected color
                if let tickerData = alarm.tickerData {
                    TickerPill(
                        icon: tickerData.icon ?? "clock",
                        title: "Icon",
                        hasValue: true,
                        size: .standard,
                        iconTintColor: tickerData.colorHex != nil ? Color(hex: tickerData.colorHex!) : TickerColor.primary
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TickerSpacing.md)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hasAnyActiveOptions)
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasAnyActiveOptions: Bool {
        alarm.schedule != nil || !alarm.label.isEmpty || alarm.countdown?.preAlert != nil || alarm.tickerData != nil
    }
    
    private var activeOptionsCount: Int {
        var count = 0
        if alarm.schedule != nil { count += 1 }
        if !alarm.label.isEmpty { count += 1 }
        if alarm.countdown?.preAlert != nil { count += 1 }
        if alarm.tickerData != nil { count += 1 }
        return count
    }
    
    // MARK: - Helper Methods
    
    private func dateDisplayText(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime(let date):
            return date.formatted(date: .abbreviated, time: .omitted)
        case .daily:
            return "Every day"
        case .hourly(let interval, _, _):
            return "Every \(interval)h"
        case .weekdays(_, let days):
            let sortedDays = days.sorted { $0.rawValue < $1.rawValue }
            return sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
        case .biweekly(_, let weekdays):
            let sortedDays = weekdays.sorted { $0.rawValue < $1.rawValue }
            return "Biweekly " + sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
        case .monthly(let day, _):
            switch day {
            case .fixed(let d): return "Day \(d)"
            case .firstWeekday(let weekday): return "First \(weekday.shortDisplayName)"
            case .lastWeekday(let weekday): return "Last \(weekday.shortDisplayName)"
            case .firstOfMonth: return "1st of month"
            case .lastOfMonth: return "Last of month"
            }
        case .yearly(let month, let day, _):
            let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return "\(monthNames[month - 1]) \(day)"

        case .every(let interval, let unit, _, _):
            let unitName = interval == 1 ? unit.singularName : unit.displayName.lowercased()
            return "Every \(interval) \(unitName)"
        }
    }

    private func repeatDisplayText(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime:
            return "Once"
        case .daily:
            return "Daily"
        case .hourly:
            return "Hourly"
        case .every:
            return "Every"
        case .weekdays:
            return "Weekdays"
        case .biweekly:
            return "Biweekly"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }

    private func formatCountdown(_ countdown: TickerCountdown.CountdownDuration) -> String {
        var parts: [String] = []

        if countdown.hours > 0 {
            parts.append("\(countdown.hours)h")
        }
        if countdown.minutes > 0 {
            parts.append("\(countdown.minutes)m")
        }
        if countdown.seconds > 0 {
            parts.append("\(countdown.seconds)s")
        }

        return parts.isEmpty ? "0s" : parts.joined(separator: " ")
    }
}

// MARK: - Preview

#Preview {
    AlarmDetailOptionsSection(
        alarm: Ticker(
            label: "Morning Workout",
            isEnabled: true,
            schedule: .daily(
                time: TickerSchedule.TimeOfDay(hour: 6, minute: 30)
            ),
            countdown: TickerCountdown(
                preAlert: TickerCountdown.CountdownDuration(hours: 0, minutes: 5, seconds: 0),
                postAlert: nil
            )
        )
    )
    .padding()
}
