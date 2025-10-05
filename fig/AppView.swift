//
//  AppView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import AlarmKit
import SwiftUI

struct AppView: View {
    
    var body: some View {
        TabView {
            Tab("Today", systemImage: "clock") {
                TodayView()
            }
            .customizationID("com.myApp.home")
            
            Tab("Alarms", systemImage: "alarm") {
                ContentView()
            }
            .customizationID("com.myApp.reports")
        }
    }
    
}

#Preview {
    AppView()
}
