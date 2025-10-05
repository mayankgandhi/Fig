//
//  TodayView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text(verbatim: "Today View")
                .navigationTitle("Today")
                .navigationBarTitleDisplayMode(.automatic)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Settings", systemImage: "gear") {
                            print("Settings Tapped")
                        }
                    }
                    
                }
        }
        .tint(.accentColor)
    }
}

#Preview {
    TodayView()
}
