//
//  AppView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import AlarmKit
import SwiftUI

struct AppView: View {
    @State private var viewModel = ViewModel()
    
    var body: some View {
        TabView {
        
            Tab("Today", systemImage: "clock") {
                ClockView(events: [
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
                ])
                .environment(viewModel)
            }
            
            Tab("Scheduled", systemImage: "clock") {
                ContentView()
                    .environment(viewModel)
            }
            
            Tab("Templates", systemImage: "alarm") {
                TodayView()
                    .environment(viewModel)
            }
            
        }
    }
    
}

#Preview {
    AppView()
}
