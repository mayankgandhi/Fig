//
//  UpcomingAlarmRow.swift
//  fig
//
//  Created by Mayank Gandhi on 11/10/25.
//

import SwiftUI
import Foundation

// MARK: - Upcoming Alarm Row

struct UpcomingAlarmRow: View {
    let presentation: UpcomingAlarmPresentation
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
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(presentation.color)
                }

                // Alarm details
                VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                    Text(presentation.displayName)
                        .Headline()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                    HStack(spacing: TickerSpacing.xs) {
                        Text(presentation.nextAlarmTime, style: .time)
                            .Footnote()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                        Text("•")
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                        Text(presentation.timeUntilAlarm(from: context.date))
                            .Footnote()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                // Schedule type badge
                Text(presentation.scheduleType.badgeText)
                    .tickerStatusBadge(color: presentation.scheduleType.badgeColor)
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
        }
    }
}
