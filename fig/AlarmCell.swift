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
        VStack(alignment: .leading) {
            HStack {
                if let schedule = alarmItem.schedule {
                    scheduleText(for: schedule)
                        .font(.title)
                        .fontWeight(.medium)
                } else if let countdown = alarmItem.countdown?.preAlert {
                    Text(formatDuration(countdown.interval))
                        .font(.title)
                        .fontWeight(.medium)
                }
                Spacer()
                tag
            }

            Text(alarmItem.label)
                .font(.headline)
        }
    }

    @ViewBuilder
    private func scheduleText(for schedule: TickerSchedule) -> some View {
        switch schedule {
        case .oneTime(let date):
            Text(date, style: .time)
        case .daily(let time):
            Text(formatTime(time))
        case .monthly(let time, _):
            Text(formatTime(time))
        case .yearly(_, _, let time):
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

