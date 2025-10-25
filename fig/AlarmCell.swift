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
        HStack(spacing: TickerSpacing.md) {
            // Icon with background circle
            categoryIconView
            
            // Main content
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                HStack {
                    Text(alarmItem.label)
                        .TickerTitle()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Time display
                    if let schedule = alarmItem.schedule {
                        scheduleText(for: schedule)
                            .TimeDisplay()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    } else if let countdown = alarmItem.countdown?.preAlert {
                        Text(formatDuration(countdown.interval))
                            .TimeDisplay()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    }
                }
                
                HStack {
                    // Schedule info
                    scheduleInfoView
                        .DetailText()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    
                    Spacer()
                   
                }
            }
        }
        .padding(.vertical, TickerSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            TickerHaptics.selection()
            onTap?()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var categoryIconView: some View {
        let iconColor = iconColor
        let iconName = iconName
        
        ZStack {
            // Background circle
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 48, height: 48)
            
            // Icon
            Image(systemName: iconName)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
        }
    }
    
    private var iconColor: Color {
        if let tickerData = alarmItem.tickerData, let colorHex = tickerData.colorHex {
            return Color(hex: colorHex) ?? TickerColor.primary
        }
        return TickerColor.primary
    }
    
    private var iconName: String {
        if let tickerData = alarmItem.tickerData, let icon = tickerData.icon {
            return icon
        }
        return "alarm"
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
        case .daily(let time), .weekdays(let time, _), .biweekly(let time, _), .monthly(_, let time), .yearly(_, _, let time):
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
                        time: TickerSchedule.TimeOfDay(hour: 12, minute: 30)
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
                        time: TickerSchedule.TimeOfDay(hour: 22, minute: 0)
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

