//
//  AppView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

struct AppView: View {

     init() {
        // For large titles
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(name: FigFontFamily.CabinetGrotesk.extrabold.name, size: 30)!
        ]

        // For inline titles
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont(name: FigFontFamily.CabinetGrotesk.extrabold.name, size: 20)!
        ]
    }
    
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
