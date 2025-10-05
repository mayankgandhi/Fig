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
                TodayView()
                    .environment(viewModel)
            }
            .customizationID("com.myApp.home")
            
            Tab("Alarms", systemImage: "alarm") {
                ContentView()
                    .environment(viewModel)
            }
            .customizationID("com.myApp.alarms")
            
        }
    }
    
}

#Preview {
    AppView()
}
