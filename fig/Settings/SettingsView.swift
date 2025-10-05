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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    NavBarHeader(
                        iconName: "gear",
                        iconColor: .blue,
                        title: "Settings",
                        subtitle: "Manage your alarm preferences"
                    )

                    // App Settings Section
                    appSettingsSection
                        .padding(.horizontal, Spacing.medium)

                    // Data Section
                    dataSection
                        .padding(.horizontal, Spacing.medium)

                    Spacer(minLength: Spacing.xl)
                }
                .padding(.vertical, Spacing.xl)
            }
            .presentationCompactAdaptation(.sheet)
            .presentationDragIndicator(.visible)
            
        }
    }

    // MARK: - View Components

    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("App Settings")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: Spacing.xs) {
                AboutView()
                FAQView()
                HelpSupportView()
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Data")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: Spacing.xs) {
                DeleteAllDataView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
