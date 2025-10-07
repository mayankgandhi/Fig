//
//  TodayClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 07/10/25.
//

import SwiftUI

struct TodayClockView: View {
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
        ClockView(events: events)
            .navigationTitle("Today")
            .padding(.trailing)
    }
}

#Preview {
    TodayClockView()
}
