//
//  CollectionDetailOptionsSection.swift
//  fig
//
//  Options section component for TickerCollectionDetailView showing collection properties as pills
//

import SwiftUI
import TickerCore

struct CollectionDetailOptionsSection: View {

    let tickerCollection: TickerCollection
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if let config = tickerCollection.sleepScheduleConfig {
            VStack(alignment: .leading, spacing: TickerSpacing.lg) {
                // Enhanced pill layout with improved spacing and alignment
                FlowLayout(spacing: TickerSpacing.md) {
                    // Sleep schedule duration (if applicable)
                    TickerPill(
                        icon: "moon.fill",
                        title: config.formattedDuration,
                        hasValue: true,
                        size: .standard
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TickerSpacing.md)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: childCount)
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var childCount: Int {
        tickerCollection.childTickers?.count ?? 0
    }
}

// MARK: - Preview

#Preview {
    CollectionDetailOptionsSection(
        tickerCollection: TickerCollection(
            label: "Sleep Schedule",
            collectionType: .sleepSchedule,
            configuration: .sleepSchedule(
                SleepScheduleConfiguration(
                    bedtime: TimeOfDay(hour: 22, minute: 0),
                    wakeTime: TimeOfDay(hour: 6, minute: 30)
                )
            )
        )
    )
    .padding()
}

