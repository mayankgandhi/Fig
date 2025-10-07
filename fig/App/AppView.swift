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
                TodayClockView()
                    .environment(viewModel)
            }
            
            Tab("Scheduled", systemImage: "clock") {
                ContentView()
                    .environment(viewModel)
            }
            
            Tab("Templates", systemImage: "square.grid.2x2") {
                TemplatesView()
            }
            
        }
    }
    
}

#Preview {
    AppView()
}
