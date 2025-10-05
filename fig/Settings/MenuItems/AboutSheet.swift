//
//  AboutSheet.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import WalnutDesignSystem
import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {

                VStack(spacing: Spacing.medium) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.blue)

                    Text("fig")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Smart Alarm Manager")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HealthCard {
                    VStack(spacing: Spacing.medium) {
                        HStack {
                            Text("Version")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(appVersion)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Build")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(buildNumber)
                                .fontWeight(.medium)
                        }
                    }
                }

                Spacer()
            }
            .padding(Spacing.medium)
            .navigationTitle(Text("About"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AboutSheet()
}
