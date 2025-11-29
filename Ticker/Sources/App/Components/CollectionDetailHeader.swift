//
//  CollectionDetailHeader.swift
//  fig
//
//  Header component for TickerCollectionDetailView showing icon, label, and status
//

import SwiftUI
import TickerCore
import Factory

struct CollectionDetailHeader: View {
    let tickerCollection: TickerCollection
    let tickerService: TickerService
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: TickerSpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: iconSymbol)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                // Label
                Text(tickerCollection.label)
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                // Status badge
                Text(statusLabel)
                    .caption2()
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, TickerSpacing.xs)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(TickerSpacing.sm)
        .background(TickerColor.surface(for: colorScheme).opacity(0.5))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
    }
    
    // MARK: - Helper Properties
    
    private var iconSymbol: String {
        tickerCollection.collectionType.iconName
    }

    private var iconColor: Color {
        tickerCollection.presentation.tintColor
    }

    private var statusLabel: String {
        // Check if any child tickers are active
        if let children = tickerCollection.childTickers,
           children.contains(where: { tickerService.getActiveAlarm(tickerID: $0.id) != nil }) {
            return "Active"
        }
        return tickerCollection.isEnabled ? "Scheduled" : "Disabled"
    }

    private var statusColor: Color {
        // Check if any child tickers are active
        if let children = tickerCollection.childTickers,
           children.contains(where: { tickerService.getActiveAlarm(tickerID: $0.id) != nil }) {
            return TickerColor.scheduled
        }
        return tickerCollection.isEnabled ? TickerColor.scheduled : TickerColor.disabled
    }
}

// MARK: - Preview

#Preview {
    @Previewable @Injected(\.tickerService) var tickerService

    CollectionDetailHeader(
        tickerCollection: TickerCollection(
            label: "Sleep Schedule",
            collectionType: .sleepSchedule,
            presentation: TickerPresentation(tintColorHex: "#6366F1")
        ),
        tickerService: tickerService
    )
    .environment(tickerService)
    .padding()
}

