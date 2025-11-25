//
//  UnifiedAlarmListView.swift
//  Ticker
//
//  Created by Claude Code
//  Unified list view for displaying both standard Tickers and CompositeTickers
//

import SwiftUI
import TickerCore
import DesignKit

struct UnifiedAlarmListView: View {

    // Alarm list item enum for unified display
    enum AlarmListItem: Identifiable {
        case ticker(Ticker)
        case composite(CompositeTicker)

        var id: UUID {
            switch self {
            case .ticker(let ticker): return ticker.id
            case .composite(let composite): return composite.id
            }
        }
    }

    let alarmItems: [AlarmListItem]
    let onTickerTap: (Ticker) -> Void
    let onCompositeTap: (CompositeTicker) -> Void
    let onEdit: (Ticker) -> Void
    let onDelete: (Ticker) -> Void

    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            ForEach(alarmItems) { item in
                switch item {
                case .ticker(let ticker):
                    AlarmCell(alarmItem: ticker) {
                        onTickerTap(ticker)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(
                        top: DesignKit.xs,
                        leading: DesignKit.md,
                        bottom: DesignKit.xs,
                        trailing: DesignKit.md
                    ))
                    .contextMenu {
                        Button {
                            DesignKitHaptics.selection()
                            onEdit(ticker)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)

                        Button(role: .destructive) {
                            DesignKitHaptics.selection()
                            onDelete(ticker)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }

                case .composite(let composite):
                    if composite.compositeType == .sleepSchedule {
                        SleepScheduleCell(compositeItem: composite) {
                            onCompositeTap(composite)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(
                            top: DesignKit.sm,
                            leading: DesignKit.md,
                            bottom: DesignKit.sm,
                            trailing: DesignKit.md
                        ))
                    } else {
                        CompositeAlarmCell(compositeItem: composite) {
                            onCompositeTap(composite)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(
                            top: DesignKit.xs,
                            leading: DesignKit.md,
                            bottom: DesignKit.xs,
                            trailing: DesignKit.md
                        ))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Composite Alarm Cell

struct CompositeAlarmCell: View {
    let compositeItem: CompositeTicker
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var tintColor: Color {
        compositeItem.presentation.tintColor
    }

    var body: some View {
        Button(action: {
            DesignKitHaptics.selection()
            onTap()
        }) {
            HStack(spacing: DesignKit.md) {
                // Icon with background circle
                categoryIconView
                
                // Content
                VStack(alignment: .leading, spacing: DesignKit.xxs) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(compositeItem.label)
                            .tickerTitle()
                            .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: DesignKit.xs) {
                        // Child count badge
                        if compositeItem.childCount > 0 {
                            HStack(spacing: DesignKit.xxs) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12, weight: .medium))
                                Text("\(compositeItem.childCount) alarms")
                                    .detailText()
                            }
                            .foregroundStyle(DesignKit.textSecondary(for: colorScheme))
                        }

                        // Sleep duration (for sleep schedules)
                        if let config = compositeItem.sleepScheduleConfig {
                            if compositeItem.childCount > 0 {
                                Text("•")
                                    .foregroundStyle(DesignKit.textTertiary(for: colorScheme))
                            }
                            Text(config.formattedDuration)
                                .detailText()
                                .foregroundStyle(DesignKit.textSecondary(for: colorScheme))
                        }
                        
                        Spacer()
                        
                        // Enabled/disabled indicator
                        if !compositeItem.isEnabled {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(DesignKit.textTertiary(for: colorScheme))
                        }
                    }
                }
            }
            .padding(DesignKit.md)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignKit.large))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                radius: 8,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var categoryIconView: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(tintColor.opacity(0.15))
                .frame(width: 48, height: 48)
            
            // Icon
            Image(systemName: compositeItem.compositeType.iconName)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(tintColor)
                .frame(width: 24, height: 24)
        }
    }
    
    // MARK: - Card Background
    
    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            // Base material background
            RoundedRectangle(cornerRadius: DesignKit.large)
                .fill(.ultraThinMaterial)
            
            // Subtle color tint based on tint color
            RoundedRectangle(cornerRadius: DesignKit.large)
                .fill(
                    LinearGradient(
                        colors: [
                            tintColor.opacity(colorScheme == .dark ? 0.08 : 0.04),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Subtle border
            RoundedRectangle(cornerRadius: DesignKit.large)
                .strokeBorder(
                    tintColor.opacity(colorScheme == .dark ? 0.15 : 0.1),
                    lineWidth: 1
                )
        }
    }
}
