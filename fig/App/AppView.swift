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
            Tab("Alarms", systemImage: "clock") {
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
