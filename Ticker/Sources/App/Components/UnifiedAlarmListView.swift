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
                    CompositeAlarmCell(compositeItem: composite) {
                        onCompositeTap(composite)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
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

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: compositeItem.compositeType.iconName)
                    .font(.title2)
                    .foregroundStyle(compositeItem.presentation.tintColor)
                    .frame(width: 40, height: 40)
                    .glassEffect()

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(compositeItem.label)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        // Child count badge
                        if compositeItem.childCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                Text("\(compositeItem.childCount) alarms")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }

                        // Sleep duration (for sleep schedules)
                        if let config = compositeItem.sleepScheduleConfig {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(config.formattedDuration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Enabled/disabled indicator
                ZStack {
                    Circle()
                        .fill(compositeItem.isEnabled ?
                              compositeItem.presentation.tintColor.opacity(0.2) :
                              Color.gray.opacity(0.1))
                        .frame(width: 24, height: 24)

                    if compositeItem.isEnabled {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(compositeItem.presentation.tintColor)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
        }
        .buttonStyle(.plain)
    }
}
