//
//  SettingsView.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI
import WalnutDesignSystem
import AlarmKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.md) {

                    // App Settings Section
                    appSettingsSection
                        .padding(.horizontal, TickerSpacing.md)

                    // Data Section
                    dataSection
                        .padding(.horizontal, TickerSpacing.md)

                    Spacer(minLength: TickerSpacing.xl)
                }
                .padding(.vertical, TickerSpacing.xl)
            }
            .presentationCompactAdaptation(.sheet)
            .presentationDragIndicator(.visible)
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inlineLarge)

        }
    }

    // MARK: - View Components

    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text("App Settings")
                .cabinetCaption2()
                .textCase(.uppercase)
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: TickerSpacing.xs) {
                AboutView()
                FAQView()
                HelpSupportView()
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text("Data")
                .cabinetCaption2()
                .textCase(.uppercase)
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: TickerSpacing.xs) {
                DeleteAllDataView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
