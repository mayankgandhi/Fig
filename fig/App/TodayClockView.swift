//
//  TodayClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 07/10/25.
//

import SwiftUI
import WalnutDesignSystem

struct TodayClockView: View {
    
    @State private var showSettings: Bool = false
    
    @State private var events: [ClockView.TimeBlock] = [
        ClockView.TimeBlock(
            id: UUID(),
            city: "Los Angeles",
            hour: 1,
            minute: 47,
            color: .black
        ),
        ClockView.TimeBlock(
            id: UUID(),
            city: "Tokyo",
            hour: 4,
            minute: 47,
            color: .gray
        ),
        ClockView.TimeBlock(
            id: UUID(),
            city: "Yerevan",
            hour: 11,
            minute: 47,
            color: .red
        ),
        ClockView.TimeBlock(
            id: UUID(),
            city: "Paris",
            hour: 9,
            minute: 47,
            color: .blue
        )
    ]
    
    var body: some View {
        NavigationStack {
            ClockView(events: events)
                .navigationTitle("Today")
                .toolbarTitleDisplayMode(.inlineLarge)
                .padding(.trailing)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showSettings, content: {
                    SettingsView()
                        .presentationCornerRadius(Spacing.large)
                        .presentationDragIndicator(.visible)
                })
        }
    }
}

#Preview {
    TodayClockView()
}
