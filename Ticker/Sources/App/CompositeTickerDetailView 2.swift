//
//  CompositeTickerDetailView 2.swift
//  Ticker
//
//  Created by Mayank Gandhi on 26/11/25.
//

import Factory
import SwiftData
import SwiftUI
import TickerCore

struct CompositeTickerDetailContainerView: View {

    let compositeTicker: CompositeTicker

    var body: some View {
        switch compositeTicker.compositeType {
        case .sleepSchedule:
            SleepScheduleEditor(
                viewModel: SleepScheduleViewModel(
                    bedtime: compositeTicker.sleepScheduleConfig?.bedtime ?? TimeOfDay(hour: 22, minute: 0),
                    wakeTime: compositeTicker.sleepScheduleConfig?.wakeTime ?? TimeOfDay(hour: 6, minute: 30),
                    presentation: compositeTicker.presentation,
                    compositeTickerToUpdate: compositeTicker
                )
            )
        @unknown default:
            CompositeTickerDetailView(compositeTicker: compositeTicker)
        }
    }
}

