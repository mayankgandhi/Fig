//
//  AboutSheet.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI
import TickerCore
import Gate

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var copiedToClipboard = false
    @State private var userID: String? = nil

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.xl) {
                    // Hero Section
                    heroSection
                        .padding(.top, TickerSpacing.lg)
                        .padding(.horizontal, TickerSpacing.md)

                    // App Information Card
                    appInfoCard
                        .padding(.horizontal, TickerSpacing.md)

                    // User ID Card
                    userIDCard
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
            .navigationTitle("About")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        TickerHaptics.selection()
                        dismiss()
                    }
                    .Body()
                    .foregroundStyle(TickerColor.primary)
                }
            }
            .task {
                // Load user ID asynchronously
                userID = UserService.shared.getCurrentUserID()
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: TickerSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                TickerColor.primary.opacity(0.2),
                                TickerColor.accent.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: TickerIcons.alarmScheduled)
                    .font(.system(size: 40, weight: .regular, design: .rounded))
                    .foregroundStyle(TickerColor.primary)
            }

            VStack(spacing: TickerSpacing.xs) {
                Text("fig")
                    .Title()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Text("Smart Alarm Manager")
                    .Subheadline()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }
        }
    }

    // MARK: - App Information Card

    private var appInfoCard: some View {
        VStack(spacing: TickerSpacing.md) {
            HStack {
                Text("App Information")
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                Spacer()
            }

            VStack(spacing: TickerSpacing.sm) {
                infoRow(label: "Version", value: appVersion)
                
                Divider()
                    .background(TickerColor.textTertiary(for: colorScheme).opacity(0.3))

                infoRow(label: "Build", value: buildNumber)
            }
        }
        .padding(TickerSpacing.md)
        .tickerCard()
    }

    // MARK: - User ID Card

    private var userIDCard: some View {
        VStack(spacing: TickerSpacing.md) {
            HStack {
                Text("RevenueCat User ID")
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                Spacer()
            }

            if let userID = userID {
                HStack(spacing: TickerSpacing.sm) {
                    Text(userID)
                        .Body()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    Button {
                        copyUserIDToClipboard(userID)
                    } label: {
                        HStack(spacing: TickerSpacing.xs) {
                            Image(systemName: copiedToClipboard ? TickerIcons.checkmark : "doc.on.doc")
                                .SmallText()
                                .foregroundStyle(copiedToClipboard ? TickerColor.success : TickerColor.primary)

                            if copiedToClipboard {
                                Text("Copied")
                                    .SmallText()
                                    .foregroundStyle(TickerColor.success)
                            }
                        }
                        .padding(.horizontal, TickerSpacing.sm)
                        .padding(.vertical, TickerSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: TickerRadius.small)
                                .fill(
                                    copiedToClipboard
                                        ? TickerColor.success.opacity(0.1)
                                        : TickerColor.primary.opacity(0.1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .Body()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    Spacer()
                }
            }
        }
        .padding(TickerSpacing.md)
        .tickerCard()
    }

    // MARK: - Helper Views

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .Body()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            Spacer()
            Text(value)
                .Body()
                .fontWeight(.medium)
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
        }
    }

    // MARK: - Helper Functions

    private func copyUserIDToClipboard(_ userID: String) {
        UIPasteboard.general.string = userID
        TickerHaptics.success()
        copiedToClipboard = true

        // Reset copied state after 2 seconds
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                copiedToClipboard = false
            }
        }
    }
}

#Preview {
    AboutSheet()
}
