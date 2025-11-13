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
            // Icon with ticker color
            ZStack {
                Circle()
                    .fill(alarm.color.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: alarm.icon)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(alarm.color)
            }
            .layoutPriority(1)
            
            // Alarm name
            Text(alarm.displayName)
                .Subheadline()
                .fontWeight(.medium)
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                .lineLimit(1)
                .truncationMode(.tail)
            
            // Time with ticker color
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                    .Callout()
                    .fontWeight(.bold)
                    .foregroundStyle(alarm.color)
                
                Text(alarm.hour < 12 ? "AM" : "PM")
                    .Caption2()
                    .fontWeight(.semibold)
                    .foregroundStyle(alarm.color.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(TickerSpacing.xxs)
        .background(
            TickerColor.surface(for: colorScheme)
                .cornerRadius(TickerRadius.small)
        )
    }
}

/// Detailed alarm row with icon circle, badges, and full information
struct DetailedAlarmRow: View {
    let alarm: UpcomingAlarmPresentation
    let currentDate: Date
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .center, spacing: TickerSpacing.sm) {
            // Icon with ticker color
            ZStack {
                Circle()
                    .fill(alarm.color.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: alarm.icon)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(alarm.color)
            }

            // Alarm details
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.displayName)
                    .DetailText()
                    .fontWeight(.medium)
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text(alarm.scheduleType.badgeText)
                        .Caption2()
                        .fontWeight(.semibold)
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

            // Time with ticker color
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
                    .fontWeight(.medium)
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.trailing)
            }
        }
        
    }
}

