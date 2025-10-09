/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that displays an individual alarm cell in the list.
*/

import SwiftUI

struct AlarmCell: View {

    let alarmItem: Ticker
    @Environment(AlarmService.self) private var alarmService
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: TickerSpacing.md) {
            // Leading: Category icon with colored background
            categoryIconView

            // Main content area
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                // Primary: Alarm label
                Text(alarmItem.label)
                    .cabinetTitle3()
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                // Secondary: Category name
                if let tickerData = alarmItem.tickerData, let name = tickerData.name {
                    Text(name)
                        .cabinetSubheadline()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                }

                // Tertiary: Schedule info
                scheduleInfoView
                    .cabinetFootnote()
                    .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
            }

            Spacer()

            // Trailing: Time and status
            VStack(alignment: .trailing, spacing: TickerSpacing.xs) {
                // Time display (large and prominent)
                if let schedule = alarmItem.schedule {
                    scheduleText(for: schedule)
                    .cabinetTitle3()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                } else if let countdown = alarmItem.countdown?.preAlert {
                    Text(formatDuration(countdown.interval))
                        .cabinetHeadline()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                }

                // Status tag
                tag
            }
        }
        .padding(.vertical, TickerSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            TickerHaptics.selection()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var categoryIconView: some View {
        if let tickerData = alarmItem.tickerData, let icon = tickerData.icon {
            ZStack {
                Circle()
                    .fill(Color(hex: tickerData.colorHex ?? "") ?? TickerColors.scheduled)
                    .opacity(0.15)
                    .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color(hex: tickerData.colorHex ?? "") ?? TickerColors.scheduled)
            }
        } else {
            ZStack {
                Circle()
                    .fill(TickerColors.scheduled.opacity(0.15))
                    .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)

                Image(systemName: "alarm")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(TickerColors.scheduled)
            }
        }
    }

    @ViewBuilder
    private var scheduleInfoView: some View {
        if let schedule = alarmItem.schedule {
            HStack(spacing: 4) {
                Image(systemName: scheduleIcon(for: schedule))
                Text(scheduleDescription(for: schedule))
            }
        } else if alarmItem.countdown?.preAlert != nil {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text("Countdown")
            }
        }
    }

    private func scheduleIcon(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime: return "calendar"
        case .daily: return "repeat"
        }
    }

    private func scheduleDescription(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime(let date):
            return date.formatted(date: .abbreviated, time: .omitted)
        case .daily:
            return "Every day"
        }
    }

    @ViewBuilder
    private func scheduleText(for schedule: TickerSchedule) -> some View {
        switch schedule {
        case .oneTime(let date):
            Text(date, style: .time)
        case .daily(let time):
            Text(formatTime(time))
        }
    }

    private func formatTime(_ time: TickerSchedule.TimeOfDay) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(time.hour):\(String(format: "%02d", time.minute))"
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? interval.formatted()
    }

    var tag: some View {
        Text(tagLabel)
            .tickerStatusBadge(color: tagColor)
    }

    var tagLabel: String {
        // Get current state from AlarmService
        if let alarmState = alarmService.getAlarmState(id: alarmItem.id) {
            switch alarmState.state {
            case .scheduled: return "Scheduled"
            case .countdown: return "Running"
            case .paused: return "Paused"
            case .alerting: return "Alert"
            }
        }
        // If no state in AlarmService, show based on isEnabled
        return alarmItem.isEnabled ? "Scheduled" : "Disabled"
    }

    var tagColor: Color {
        // Get current state from AlarmService
        if let alarmState = alarmService.getAlarmState(id: alarmItem.id) {
            switch alarmState.state {
            case .scheduled: return TickerColors.scheduled
            case .countdown: return TickerColors.running
            case .paused: return TickerColors.paused
            case .alerting: return TickerColors.alertActive
            }
        }
        // If no state in AlarmService
        return alarmItem.isEnabled ? TickerColors.scheduled : TickerColors.disabled
    }
}

