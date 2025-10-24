//
//  WidgetViewComponents.swift
//  alarm
//
//  Shared view components for alarm widgets
//  Reusable alarm row components with consistent styling
//

import SwiftUI

// MARK: - Alarm Row Components

/// Standard alarm row with icon, name, and time display
struct AlarmRow: View {
    let alarm: UpcomingAlarmPresentation
    let currentDate: Date
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(alarm.color)

                    Text(alarm.hour < 12 ? "AM" : "PM")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(alarm.color.opacity(0.7))
                }

                Text(alarm.timeUntilAlarm(from: currentDate))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
            }

            Spacer()

            // Alarm info
            HStack(spacing: 6) {
                Image(systemName: alarm.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(alarm.color)

                Text(alarm.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
        )
    }
}

/// Compact alarm row for medium-sized widgets
struct CompactAlarmRow: View {
    let alarm: UpcomingAlarmPresentation
    let currentDate: Date
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 8) {
            // Time
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(alarm.color)

                Text(alarm.hour < 12 ? "AM" : "PM")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(alarm.color.opacity(0.7))
            }

            Spacer()

            // Alarm info
            HStack(spacing: 4) {
                Image(systemName: alarm.icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(alarm.color)

                Text(alarm.displayName)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground).opacity(0.4))
        )
    }
}

/// Detailed alarm row with icon circle, badges, and full information
struct DetailedAlarmRow: View {
    let alarm: UpcomingAlarmPresentation
    let currentDate: Date
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon and color indicator
            ZStack {
                Circle()
                    .fill(alarm.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: alarm.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(alarm.color)
            }

            // Alarm details
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text(alarm.scheduleType.badgeText)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(alarm.scheduleType.badgeColor)
                        )

                    if alarm.hasCountdown {
                        Image(systemName: "timer")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    }
                }
            }

            // Time and countdown - Fixed width for consistent alignment
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(String(format: "%d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(alarm.color)

                    Text(alarm.hour < 12 ? "AM" : "PM")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(alarm.color.opacity(0.7))
                }

                Text(alarm.timeUntilAlarm(from: currentDate))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(alarm.color.opacity(0.8))
                    .multilineTextAlignment(.trailing)
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
        )
    }
}
