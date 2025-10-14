//
//  AlarmTypesView.swift
//  fig
//
//  Settings menu item for managing alarm types
//

import SwiftUI

struct AlarmTypesView: View {
    @State private var showAlarmTypesSheet = false

    var body: some View {
        NativeMenuListItem(
            icon: "tag.circle",
            title: "Alarm Types",
            subtitle: "Create and manage custom alarm types",
            iconColor: .purple
        ) {
            showAlarmTypesSheet = true
        }
        .sheet(isPresented: $showAlarmTypesSheet) {
            AlarmTypesSheet()
                .presentationDetents([.large])
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    AlarmTypesView()
}
