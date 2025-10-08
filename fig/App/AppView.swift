//
//  AppView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

struct AppView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "clock") {
                TodayClockView()
            }

            Tab("Scheduled", systemImage: "clock") {
                ContentView()
            }
        }
    }
}

#Preview {
    AppView()
}
