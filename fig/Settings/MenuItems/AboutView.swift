//
//  AboutView.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI
import TickerCore

struct AboutView: View {
    @State private var showAboutSheet = false

    var body: some View {
        NativeMenuListItem(
            icon: "info.circle",
            title: "About",
            subtitle: "App version and information",
            iconColor: TickerColor.primary
        ) {
            showAboutSheet = true
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
                .presentationDetents([.medium])
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    AboutView()
}
