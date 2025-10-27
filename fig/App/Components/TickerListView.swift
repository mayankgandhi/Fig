//
//  TickerListView.swift
//  fig
//
//  Ticker list component for ContentView
//

import SwiftUI

struct TickerListView: View {
    
    let tickers: [Ticker]
    let onTap: (Ticker) -> Void
    let onEdit: (Ticker) -> Void
    let onDelete: (Ticker) -> Void
    
    var body: some View {
        List {
            ForEach(tickers, id: \.id) { ticker in
                AlarmCell(alarmItem: ticker) {
                    onTap(ticker)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .contextMenu(menuItems: {
                    Button {
                        TickerHaptics.selection()
                        onEdit(ticker)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                    
                    Button(role: .destructive) {
                        TickerHaptics.selection()
                        onDelete(ticker)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                })
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    TickerListView(
        tickers: [
            Ticker(
                label: "Morning Workout",
                isEnabled: true,
                schedule: .daily(time: TickerSchedule.TimeOfDay(hour: 6, minute: 30)),
                tickerData: TickerData(
                    name: "Fitness & Health",
                    icon: "figure.run",
                    colorHex: "#FF6B35"
                )
            ),
            Ticker(
                label: "Lunch Break",
                isEnabled: true,
                schedule: .daily(time: TickerSchedule.TimeOfDay(hour: 12, minute: 0)),
                tickerData: TickerData(
                    name: "Lunch Break",
                    icon: "fork.knife",
                    colorHex: "#06B6D4"
                )
            )
        ],
        onTap: { _ in },
        onEdit: { _ in },
        onDelete: { _ in }
    )
    .padding()
    .background(
        ZStack {
            TickerColor.liquidGlassGradient(for: .dark)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    )
}
