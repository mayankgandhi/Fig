/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that displays an individual alarm cell in the list.
*/

import SwiftUI

struct AlarmCell: View {

    let alarmItem: Ticker
    let onTap: (() -> Void)?
    @Environment(AlarmService.self) private var alarmService
    @Environment(\.colorScheme) private var colorScheme

    init(alarmItem: Ticker, onTap: (() -> Void)? = nil) {
        self.alarmItem = alarmItem
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: TickerSpacing.sm) {
            // Leading: Category icon with colored background
            categoryIconView

            // Main content area
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                // Primary: Alarm label
                Text(alarmItem.label)
                    .Title3()
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                // Secondary: Category name
                if let tickerData = alarmItem.tickerData, let name = tickerData.name, name != alarmItem.label {
                    Text(name)
                        .Subheadline()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                }

                // Tertiary: Schedule info
                scheduleInfoView
                    .Footnote()
                    .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
            }

            Spacer()

            // Trailing: Time and status
            VStack(alignment: .trailing, spacing: TickerSpacing.xs) {
                // Time display (large and prominent)
                if let schedule = alarmItem.schedule {
                    scheduleText(for: schedule)
                    .Title()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                } else if let countdown = alarmItem.countdown?.preAlert {
                    Text(formatDuration(countdown.interval))
                        .Headline()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                }

                // Status tag
                tag
            }
        }
        .padding(TickerSpacing.sm)
        .background(TickerColors.surface(for: colorScheme))
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.large))
        .shadow(
            color: TickerShadow.subtle.color,
            radius: TickerShadow.subtle.radius,
            x: TickerShadow.subtle.x,
            y: TickerShadow.subtle.y
        )
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
        // If alarm is in service, it's active
        if alarmService.getTicker(id: alarmItem.id) != nil {
            return "Active"
        }
        // If not in service, show based on isEnabled
        return alarmItem.isEnabled ? "Scheduled" : "Disabled"
    }

    var tagColor: Color {
        // If alarm is in service, it's active (scheduled color)
        if alarmService.getTicker(id: alarmItem.id) != nil {
            return TickerColors.scheduled
        }
        // If not in service
        return alarmItem.isEnabled ? TickerColors.scheduled : TickerColors.disabled
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: TickerSpacing.md) {
        // Daily alarm example
        AlarmCell(alarmItem: Ticker(
            label: "Lunch Break",
            isEnabled: true,
            notes: "Time for lunch!",
            schedule: .daily(time: TickerSchedule.TimeOfDay(hour: 12, minute: 30)),
            countdown: nil,
            presentation: TickerPresentation(tintColorHex: nil, secondaryButtonType: .none),
            tickerData: TickerData(
                name: "Lunch Break",
                icon: "fork.knife",
                colorHex: "#06B6D4"
            )
        ))

        // One-time alarm example
        AlarmCell(alarmItem: Ticker(
            label: "Morning Workout",
            isEnabled: true,
            notes: "Don't skip leg day",
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
        AlarmCell(alarmItem: Ticker(
            label: "Bedtime Reminder",
            isEnabled: false,
            notes: nil,
            schedule: .daily(time: TickerSchedule.TimeOfDay(hour: 22, minute: 0)),
            countdown: nil,
            presentation: TickerPresentation(tintColorHex: nil, secondaryButtonType: .none),
            tickerData: TickerData(
                name: "Wellness & Self-care",
                icon: "bed.double.fill",
                colorHex: "#6366F1"
            )
        ))
    }
    .padding()
    .background(
        ZStack {
            TickerColors.liquidGlassGradient(for: .dark)
                .ignoresSafeArea()

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    )
    .environment(AlarmService())
}

