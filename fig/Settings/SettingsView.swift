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
                VStack(spacing: 16) {

                    // App Settings Section
                    appSettingsSection
                        .padding(.horizontal, 16)

                    // Data Section
                    dataSection
                        .padding(.horizontal, 16)

                    Spacer(minLength: 32)
                }
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .presentationCompactAdaptation(.sheet)
            .presentationDragIndicator(.visible)
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inlineLarge)

        }
    }

    // MARK: - View Components

    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APP SETTINGS")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)

            VStack(spacing: 8) {
                AboutView()
                FAQView()
                HelpSupportView()
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DATA")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)

            VStack(spacing: 8) {
                DeleteAllDataView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
