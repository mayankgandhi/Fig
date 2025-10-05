//
//  DeleteAllDataView.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI
import WalnutDesignSystem
import AlarmKit

struct DeleteAllDataView: View {
    @Environment(ViewModel.self) private var viewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        MenuListItem(
            icon: "trash",
            title: "Delete All Data",
            subtitle: "Clear all scheduled alarms",
            iconColor: .red
        ) {
            showDeleteConfirmation = true
        }
        .alert("Delete All Alarms?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                deleteAllAlarms()
            }
        } message: {
            Text("This will permanently delete all your scheduled alarms. This action cannot be undone.")
        }
    }

    private func deleteAllAlarms() {
        // Get all alarm IDs
        let alarmIDs = Array(viewModel.alarmsMap.keys)

        // Unschedule all alarms
        for alarmID in alarmIDs {
            viewModel.unscheduleAlarm(with: alarmID)
        }
    }
}

#Preview {
    DeleteAllDataView()
        .environment(ViewModel())
}
