/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that displays an individual alarm cell in the list.
*/

import SwiftUI

struct AlarmCell: View {

    let alarmItem: Ticker
    let onTap: (() -> Void)?
    @Environment(TickerService.self) private var tickerService
    @Environment(\.colorScheme) private var colorScheme

    init(alarmItem: Ticker, onTap: (() -> Void)? = nil) {
        self.alarmItem = alarmItem
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            categoryIconView
            
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alarmItem.label)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Time display
                    if let schedule = alarmItem.schedule {
                        scheduleText(for: schedule)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                    } else if let countdown = alarmItem.countdown?.preAlert {
                        Text(formatDuration(countdown.interval))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }
                
                HStack {
                    // Schedule info
                    scheduleInfoView
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Status tag
                    tag
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            TickerHaptics.selection()
            onTap?()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var categoryIconView: some View {
        if let tickerData = alarmItem.tickerData, let icon = tickerData.icon {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: tickerData.colorHex ?? "") ?? .blue)
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: "alarm")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)
        }
    }

    @ViewBuilder
    private var scheduleInfoView: some View {
        if let schedule = alarmItem.schedule {
            HStack(spacing: 4) {
                Image(systemName: schedule.icon)
                Text(scheduleDescription(for: schedule))
            }
        } else if alarmItem.countdown?.preAlert != nil {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text("Countdown")
            }
        }
    }

    private func scheduleDescription(for schedule: TickerSchedule) -> String {
        return schedule.displaySummary
    }

    @ViewBuilder
    private func scheduleText(for schedule: TickerSchedule) -> some View {
        switch schedule {
        case .oneTime(let date):
            Text(date, style: .time)
        case .daily(let time, _), .weekdays(let time, _, _), .biweekly(let time, _, _), .monthly(_, let time, _), .yearly(_, _, let time, _):
            Text(formatTime(time))
        case .hourly:
            Text("Hourly")
        case .every(let interval, let unit, let startTime, _):
            // For short intervals (minutes/hours), show start time
            // For longer intervals (days/weeks), show interval
            switch unit {
            case .minutes, .hours:
                Text(startTime, style: .time)
            case .days, .weeks:
                Text("Every \(interval) \(unit.displayName)")
            }
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
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(tagColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tagColor.opacity(0.1))
            .clipShape(Capsule())
    }

    var tagLabel: String {
        // If alarm is in service, it's active
        if tickerService.getTicker(id: alarmItem.id) != nil {
            return "Active"
        }
        // If not in service, show based on isEnabled
        return alarmItem.isEnabled ? "Scheduled" : "Disabled"
    }

    var tagColor: Color {
        // If alarm is in service, it's active (scheduled color)
        if tickerService.getTicker(id: alarmItem.id) != nil {
            return .green
        }
        // If not in service
        return alarmItem.isEnabled ? .blue : .gray
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: TickerSpacing.md) {
        // Daily alarm example
        AlarmCell(
alarmItem: Ticker(
            label: "Lunch Break",
            isEnabled: true,
            schedule: 
                    .daily(
                        time: TickerSchedule.TimeOfDay(hour: 12, minute: 30),
                        startDate: .now
                    ),
            countdown: nil,
            presentation: TickerPresentation(tintColorHex: nil, secondaryButtonType: .none),
            tickerData: TickerData(
                name: "Lunch Break",
                icon: "fork.knife",
                colorHex: "#06B6D4"
            )
        )
)

        // One-time alarm example
        AlarmCell(alarmItem: Ticker(
            label: "Morning Workout",
            isEnabled: true,
            schedule: .oneTime(date: Calendar.current.date(
                bySettingHour: 6,
                minute: 30,
                second: 0,
                of: Date()
            )!),
            countdown: nil,
            presentation: TickerPresentation(tintColorHex: nil, secondaryButtonType: .none),
            tickerData: TickerData(
                name: "Fitness & Health",
                icon: "figure.run",
                colorHex: "#FF6B35"
            )
        ))

        // Disabled alarm example
        AlarmCell(
alarmItem: Ticker(
            label: "Bedtime Reminder",
            isEnabled: false,
            schedule: 
                    .daily(
                        time: TickerSchedule.TimeOfDay(hour: 22, minute: 0),
                        startDate: .now
                    ),
            countdown: nil,
            presentation: TickerPresentation(tintColorHex: nil, secondaryButtonType: .none),
            tickerData: TickerData(
                name: "Wellness & Self-care",
                icon: "bed.double.fill",
                colorHex: "#6366F1"
            )
        )
)
    }
    .padding()
    .background(
        ZStack {
            TickerColor.liquidGlassGradient(for: .dark)
                .ignoresSafeArea()

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    )
    .environment(TickerService())
}

