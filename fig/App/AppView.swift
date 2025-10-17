//
//  AppView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

struct AppView: View {
    
    init() {
        // For large titles - SF Pro Rounded Bold
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 30, weight: .bold).withRoundedDesign()
        ]
        
        // For inline titles - SF Pro Rounded Bold
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold).withRoundedDesign()
        ]
    }
    
    var body: some View {
        TabView {
            Tab("Today", systemImage: "calendar.day.timeline.left") {
                TodayClockView()
            }
            
            Tab("Scheduled", systemImage: "alarm") {
                ContentView()
            }
        }
        .tint(TickerColor.primary)
        
    }
}

#Preview {
    AppView()
        .environment(TickerService())
}
