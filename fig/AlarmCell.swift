/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that displays an individual alarm cell in the list.
*/

import SwiftUI

struct AlarmCell: View {
    let alarmItem: AlarmItem
    @Environment(AlarmService.self) private var alarmService

    var body: some View {
        HStack(spacing: 16) {
            // Leading: Category icon with colored background
            categoryIconView

            // Main content area
            VStack(alignment: .leading, spacing: 6) {
                // Primary: Alarm label
                Text(alarmItem.label)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Secondary: Category name
                if let tickerData = alarmItem.tickerData, let name = tickerData.name {
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Tertiary: Schedule info
                scheduleInfoView
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Trailing: Time and status
            VStack(alignment: .trailing, spacing: 6) {
                // Time display (large and prominent)
                if let schedule = alarmItem.schedule {
                    scheduleText(for: schedule)
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                } else if let countdown = alarmItem.countdown?.preAlert {
                    Text(formatDuration(countdown.interval))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }

                // Status tag
                tag
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var categoryIconView: some View {
        if let tickerData = alarmItem.tickerData, let icon = tickerData.icon {
            ZStack {
                Circle()
                    .fill(Color(hex: tickerData.colorHex ?? "") ?? .blue)
                    .opacity(0.15)
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: tickerData.colorHex ?? "") ?? .blue)
            }
        } else {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "alarm")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.blue)
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
            .textCase(.uppercase)
            .font(.caption.bold())
            .padding(4)
            .background(tagColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
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
            case .scheduled: return .blue
            case .countdown: return .green
            case .paused: return .yellow
            case .alerting: return .red
            }
        }
        // If no state in AlarmService
        return alarmItem.isEnabled ? .blue : .gray
    }
}

