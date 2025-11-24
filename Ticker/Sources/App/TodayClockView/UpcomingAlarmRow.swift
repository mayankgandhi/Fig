//
//  UpcomingAlarmRow.swift
//  fig
//
//  Created by Mayank Gandhi on 11/10/25.
//

import SwiftUI
import Foundation
import TickerCore

// MARK: - Upcoming Alarm Row

struct UpcomingAlarmRow: View {
    let presentation: UpcomingAlarmPresentation
    let onEdit: (UpcomingAlarmPresentation) -> Void
    let onSkip: (UpcomingAlarmPresentation) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60.0)) { context in
            HStack(spacing: TickerSpacing.md) {
                // Color indicator and icon
                ZStack {
                    Circle()
                        .fill(presentation.color.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: presentation.icon)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(presentation.color)
                }
                .layoutPriority(1)

                // Alarm details
                VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                    Text(presentation.displayName)
                        .Headline()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        .lineLimit(1)

                    HStack(spacing: TickerSpacing.xs) {
                        Text(presentation.nextAlarmTime, style: .time)
                            .Footnote()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                            .fixedSize()

                        Text("•")
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                            .fixedSize()

                        Text(presentation.timeUntilAlarm(from: context.date))
                            .Footnote()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                            .fixedSize()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Schedule type badge
                Text(presentation.scheduleType.badgeText)
                    .tickerStatusBadge(color: presentation.scheduleType.badgeColor)
                    .layoutPriority(2)
            }
            .padding(TickerSpacing.md)
            .background(TickerColor.surface(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.large))
            .shadow(
                color: TickerShadow.subtle.color,
                radius: TickerShadow.subtle.radius,
                x: TickerShadow.subtle.x,
                y: TickerShadow.subtle.y
            )
            .contextMenu {
                Button {
                    TickerHaptics.selection()
                    onEdit(presentation)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    TickerHaptics.selection()
                    onSkip(presentation)
                } label: {
                    Label("Skip Alarm", systemImage: "bell.slash")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Upcoming Alarm Variations") {
    VStack(spacing: TickerSpacing.lg) {
        // Daily alarm - waking up
        UpcomingAlarmRow(
            presentation: UpcomingAlarmPresentation(
            baseAlarmId: UUID(),
            displayName: "Wake Up",
            icon: "sunrise.fill",
            color: .orange,
            nextAlarmTime: Calendar.current.date(byAdding: .hour, value: 8, to: .now) ?? .now,
            scheduleType: .daily,
            hour: 7,
            minute: 30,
            hasCountdown: true,
            tickerDataTitle: "Morning Routine"
        ), onEdit: { _ in }, onSkip: { _ in })

        // One-time alarm - meeting
        UpcomingAlarmRow(
            presentation: UpcomingAlarmPresentation(
            baseAlarmId: UUID(),
            displayName: "Team Meeting",
            icon: "person.3.fill",
            color: .blue,
            nextAlarmTime: Calendar.current.date(byAdding: .minute, value: 45, to: .now) ?? .now,
            scheduleType: .oneTime,
            hour: 14,
            minute: 0,
            hasCountdown: false,
            tickerDataTitle: nil
        ), onEdit: { _ in }, onSkip: { _ in })

        // Weekdays alarm - work
        UpcomingAlarmRow(
            presentation: UpcomingAlarmPresentation(
            baseAlarmId: UUID(),
            displayName: "Work Start",
            icon: "briefcase.fill",
            color: .purple,
            nextAlarmTime: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
            scheduleType: .weekdays([1, 2, 3, 4, 5]),
            hour: 9,
            minute: 0,
            hasCountdown: true,
            tickerDataTitle: "Get Ready"
        ), onEdit: { _ in }, onSkip: { _ in })

        // Hourly interval alarm - medication
        UpcomingAlarmRow(
            presentation: UpcomingAlarmPresentation(
            baseAlarmId: UUID(),
            displayName: "Medication",
            icon: "pills.fill",
            color: .red,
            nextAlarmTime: Calendar.current.date(byAdding: .minute, value: 20, to: .now) ?? .now,
            scheduleType: .hourly(interval: 4),
            hour: 10,
            minute: 0,
            hasCountdown: false,
            tickerDataTitle: nil
        ), onEdit: { _ in }, onSkip: { _ in })
    }
    .padding()
}

#Preview("Single Alarm - Light Mode") {
    UpcomingAlarmRow(
        presentation: UpcomingAlarmPresentation(
        baseAlarmId: UUID(),
        displayName: "Morning Coffee",
        icon: "cup.and.saucer.fill",
        color: .brown,
        nextAlarmTime: Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now,
        scheduleType: .daily,
        hour: 8,
        minute: 15,
        hasCountdown: true,
        tickerDataTitle: "Brew Time"
    ), onEdit: { _ in }, onSkip: { _ in })
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Single Alarm - Dark Mode") {
    UpcomingAlarmRow(
        presentation: UpcomingAlarmPresentation(
        baseAlarmId: UUID(),
        displayName: "Evening Walk",
        icon: "figure.walk",
        color: .green,
        nextAlarmTime: Calendar.current.date(byAdding: .hour, value: 5, to: .now) ?? .now,
        scheduleType: .daily,
        hour: 18,
        minute: 30,
        hasCountdown: false,
        tickerDataTitle: nil
    ), onEdit: { _ in }, onSkip: { _ in })
    .padding()
    .preferredColorScheme(.dark)
}
