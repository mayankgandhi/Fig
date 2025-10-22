//
//  AlarmDetailTimeSection.swift
//  fig
//
//  Time section component for AlarmDetailView showing time and schedule info
//

import SwiftUI

struct AlarmDetailTimeSection: View {
    let alarm: Ticker
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: TickerSpacing.xs) {
            if let schedule = alarm.schedule {
                Text(timeString(for: schedule))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                HStack(spacing: TickerSpacing.xxs) {
                    Image(systemName: schedule.icon)
                        .font(.system(size: 12))
                    Text(scheduleTypeLabel(for: schedule))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TickerSpacing.md)
        .background(TickerColor.surface(for: colorScheme).opacity(0.5))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
    }
    
    // MARK: - Helper Methods
    
    private func timeString(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime(let date):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)

        case .daily(let time, _), .weekdays(let time, _, _), .biweekly(let time, _, _), .monthly(_, let time, _), .yearly(_, _, let time, _):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            var components = DateComponents()
            components.hour = time.hour
            components.minute = time.minute
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return "\(time.hour):\(String(format: "%02d", time.minute))"

        case .hourly:
            // For hourly schedules, show a generic time indicator
            return "Hourly"

        case .every(let interval, let unit, let startTime, _):
            // For short intervals (minutes/hours), show start time
            // For longer intervals (days/weeks), show interval description
            switch unit {
            case .minutes, .hours:
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return formatter.string(from: startTime)
            case .days, .weeks:
                let unitName = interval == 1 ? unit.singularName : unit.displayName.lowercased()
                return "Every \(interval) \(unitName)"
            }
        }
    }

    private func scheduleTypeLabel(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime: return "One-time ticker"
        case .daily: return "Daily ticker"
        case .hourly: return "Hourly ticker"
        case .every: return "Every Ticker"
        case .weekdays: return "Weekly ticker"
        case .biweekly: return "Biweekly ticker"
        case .monthly: return "Monthly ticker"
        case .yearly: return "Yearly ticker"
        }
    }
}

// MARK: - Preview

#Preview {
    AlarmDetailTimeSection(
        alarm: Ticker(
            label: "Morning Workout",
            isEnabled: true,
            schedule: .daily(
                time: TickerSchedule.TimeOfDay(hour: 6, minute: 30),
                startDate: .now
            )
        )
    )
}
