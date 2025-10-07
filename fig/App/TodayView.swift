//
//  TodayView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

struct TodayView: View {
    
    
    @Environment(ViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            Text(verbatim: "Today View")
                .navigationTitle("Today")
                .toolbarTitleDisplayMode(.inlineLarge)
                
        }
        .tint(.accentColor)
        .environment(viewModel)
        
    }
}

#Preview {
    TodayView()
}
