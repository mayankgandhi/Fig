//
//  AppView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

extension UIFont {
    /// Returns a rounded variant of the system font
    func withRoundedDesign() -> UIFont {
        if let descriptor = fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: pointSize)
        }
        return self
    }
}

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
