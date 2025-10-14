//
//  DeleteAllDataView.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI
import SwiftData

struct DeleteAllDataView: View {
    @Environment(TickerService.self) private var tickerService
    @Environment(\.modelContext) private var modelContext
    @Query private var alarmItems: [Ticker]
    @State private var showDeleteConfirmation = false

    var body: some View {
        NativeMenuListItem(
            icon: "trash",
            title: "Delete All Data",
            subtitle: "Clear all scheduled tickers",
            iconColor: .red
        ) {
            showDeleteConfirmation = true
        }
        .alert("Delete All Tickers?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                deleteAllAlarms()
            }
        } message: {
            Text("This will permanently delete all your scheduled tickers. This action cannot be undone.")
        }
    }

    private func deleteAllAlarms() {
        // Cancel and delete all alarms
        for alarmItem in alarmItems {
            try? tickerService.cancelAlarm(id: alarmItem.id, context: modelContext)
        }
    }
}

#Preview {
    let tickerService = TickerService()
    return DeleteAllDataView()
        .modelContainer(for: Ticker.self, inMemory: true)
        .environment(tickerService)
}
