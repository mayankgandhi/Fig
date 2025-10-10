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
                        .fill(presentation.color.opacity(0.15))
                        .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)

                    Image(systemName: presentation.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(presentation.color)
                }

                // Alarm details
                VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                    Text(presentation.displayName)
                        .cabinetTitle3()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                    HStack(spacing: TickerSpacing.xs) {
                        Text(presentation.nextAlarmTime, style: .time)
                            .cabinetSubheadline()
                            .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                        Text("•")
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                        Text(presentation.timeUntilAlarm(from: context.date))
                            .cabinetSubheadline()
                            .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                // Schedule type badge
                Text(presentation.scheduleType.badgeText)
                    .tickerStatusBadge(color: presentation.scheduleType.badgeColor)
            }
            .padding(TickerSpacing.md)
            .background(TickerColors.background(for: colorScheme))
        }
    }
}
