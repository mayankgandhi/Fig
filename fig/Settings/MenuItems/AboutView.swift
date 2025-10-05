//
//  AboutView.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI
import WalnutDesignSystem

struct AboutView: View {
    @State private var showAboutSheet = false

    var body: some View {
        MenuListItem(
            icon: "info.circle",
            title: "About",
            subtitle: "App version and information",
            iconColor: .blue
        ) {
            showAboutSheet = true
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
                .presentationDetents([.medium])
                .presentationCornerRadius(Spacing.large)
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    AboutView()
}
