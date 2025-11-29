//
//  TickerCollectionDetailView 2.swift
//  Ticker
//
//  Container view for ticker collection detail that routes to appropriate view
//

import Factory
import SwiftData
import SwiftUI
import TickerCore

struct TickerCollectionDetailContainerView: View {
    let tickerCollection: TickerCollection
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        switch tickerCollection.collectionType {
        case .sleepSchedule:
            SleepScheduleEditor(
                viewModel: SleepScheduleViewModel(
                    bedtime: tickerCollection.sleepScheduleConfig?.bedtime ?? TimeOfDay(hour: 22, minute: 0),
                    wakeTime: tickerCollection.sleepScheduleConfig?.wakeTime ?? TimeOfDay(hour: 6, minute: 30),
                    presentation: tickerCollection.presentation,
                    tickerCollectionToUpdate: tickerCollection
                )
            )
        @unknown default:
            TickerCollectionDetailView(
                tickerCollection: tickerCollection,
                onEdit: onEdit,
                onDelete: onDelete
            )
        }
    }
}

