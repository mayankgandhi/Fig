//
//  WidgetViewComponents.swift
//  alarm
//
//  Shared view components for alarm widgets
//  Reusable alarm row components with consistent styling
//

import SwiftUI
import TickerCore
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
                        .TickerTitle()
                        .foregroundStyle(alarm.color)

                    Text(alarm.hour < 12 ? "AM" : "PM")
                        .Caption2()
                        .foregroundStyle(alarm.color.opacity(0.7))
                }

                Text(alarm.timeUntilAlarm(from: currentDate))
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
            }

            Spacer()

            // Alarm info
            HStack(spacing: 6) {
                Image(systemName: alarm.icon)
                    .SmallText()
                    .foregroundStyle(alarm.color)

                Text(alarm.displayName)
                    .SmallText()
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
        VStack(spacing: TickerSpacing.xxs) {
            ZStack {
                Circle()
                    .fill(alarm.color.opacity(0.12))
                    .frame(width: 24, height: 24)
                
                Image(systemName: alarm.icon)
                    .Subheadline()
                    .foregroundStyle(alarm.color)
            }
            .layoutPriority(1)
            
            Text(alarm.displayName)
                .Subheadline()
                .fontWeight(.medium)
                .foregroundStyle(alarm.color.opacity(0.7))
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                    .Callout()
                    .fontWeight(.bold)
                    .foregroundStyle(alarm.color)
                
                Text(alarm.hour < 12 ? "AM" : "PM")
                    .Callout()
                    .fontWeight(.bold)
                    .foregroundStyle(alarm.color)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(TickerSpacing.xxs)
        .background(
            TickerColor.background(for: colorScheme)
                .cornerRadius(TickerSpacing.md)
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
                    .Subheadline()
                    .foregroundStyle(alarm.color)
            }

            // Alarm details
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.displayName)
                    .DetailText()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text(alarm.scheduleType.badgeText)
                        .Caption2()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(alarm.scheduleType.badgeColor)
                        )

                    if alarm.hasCountdown {
                        Image(systemName: "timer")
                            .SmallText()
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    }
                }
            }

            // Time and countdown - Fixed width for consistent alignment
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(String(format: "%d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                        .Subheadline()
                        .fontWeight(.semibold)
                        .foregroundStyle(alarm.color)
                    
                    Text(alarm.hour < 12 ? "AM" : "PM")
                        .Caption2()
                        .fontWeight(.semibold)
                        .foregroundStyle(alarm.color.opacity(0.7))
                }
                
                Text(alarm.timeUntilAlarm(from: currentDate))
                    .Caption2()
                
                    .foregroundStyle(alarm.color.opacity(0.8))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, TickerSpacing.xs)
        .padding(.vertical, TickerSpacing.xxs)
        .background(
            TickerColor.background(for: colorScheme)
                .cornerRadius(TickerSpacing.xs)
        )
    }
}

