//
//  SettingsView.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI
import AlarmKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.lg) {

                    // App Settings Section
                    appSettingsSection
                        .padding(.horizontal, TickerSpacing.md)


                    // Data Section
                    dataSection
                        .padding(.horizontal, TickerSpacing.md)

                    Spacer(minLength: TickerSpacing.xxl)
                }
                .padding(.vertical, TickerSpacing.lg)
            }
            .background(
                ZStack {
                    TickerColor.liquidGlassGradient(for: colorScheme)
                        .ignoresSafeArea()
                    
                    // Subtle overlay for glass effect
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.1)
                        .ignoresSafeArea()
                }
            )
            .presentationCompactAdaptation(.sheet)
            .presentationDragIndicator(.visible)
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }

    // MARK: - View Components

    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            sectionHeader(title: "App Settings", icon: "app.badge")
            
            VStack(spacing: TickerSpacing.xs) {
                AboutView()
                FAQView()
                HelpSupportView()
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            sectionHeader(title: "Data Management", icon: "externaldrive.fill")
            
            VStack(spacing: TickerSpacing.xs) {
                DeleteAllDataView()
            }
        }
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: TickerSpacing.sm) {
            ZStack {
                Circle()
                    .fill(TickerColor.primary.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .SmallText()
                    .foregroundStyle(TickerColor.primary)
            }
            
            Text(title)
                .DetailText()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                .textCase(.uppercase)
                .tracking(0.5)
            
            Spacer()
        }
        .padding(.leading, TickerSpacing.xs)
    }
}

#Preview {
    SettingsView()
}
