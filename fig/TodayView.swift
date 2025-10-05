//
//  TodayView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

struct TodayView: View {
    
    @State var showSettings: Bool = false
    
    @Environment(ViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            Text(verbatim: "Today View")
                .navigationTitle("Today")
                .navigationBarTitleDisplayMode(.automatic)
                .sheet(isPresented: $showSettings, content: {
                    SettingsView()
                })
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Settings", systemImage: "gear") {
                            showSettings = true
                        }
                    }
                    
                }
        }
        .tint(.accentColor)
        .environment(viewModel)
        
    }
}

#Preview {
    TodayView()
}
