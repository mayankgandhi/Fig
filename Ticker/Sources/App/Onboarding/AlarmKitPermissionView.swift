//
//  AlarmKitPermissionView.swift
//  Ticker
//
//  Dedicated screen for requesting AlarmKit permissions during onboarding
//

import SwiftUI
import TickerCore
import Factory

struct AlarmKitPermissionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Injected(\.tickerService) private var tickerService

    @State private var isRequesting = false
    @State private var permissionDenied = false
    @State private var iconScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0

    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top spacer - 15% of screen
                Spacer()
                    .frame(height: geometry.size.height * 0.15)

                // Icon with glow effect
                ZStack {
                    // Animated glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    TickerColor.primary.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .opacity(glowOpacity)

                    // Main icon
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 110, height: 110)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                TickerColor.primary.opacity(0.6),
                                                TickerColor.primary.opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )

                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        TickerColor.primary,
                                        TickerColor.primary.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(iconScale)
                    .shadow(
                        color: TickerColor.primary.opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
                }

                // Spacing after icon
                Spacer()
                    .frame(height: TickerSpacing.xl)

                // Title and description
                VStack(spacing: TickerSpacing.sm) {
                    Text("Allow Ticker to Schedule Tickers")
                        .Title()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)

                    Text("Ticker needs permission to schedule alarms so you can receive timely reminders")
                        .Headline()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .lineLimit(3)
                }
                .padding(.horizontal, TickerSpacing.xl)

                // Middle spacer - flexible
                Spacer()

                // Permission buttons
                VStack(spacing: TickerSpacing.md) {
                    if permissionDenied {
                        // Show settings prompt if denied
                        VStack(spacing: TickerSpacing.sm) {
                            Text("Permission Denied")
                                .Callout()
                                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                            Button {
                                openSettings()
                            } label: {
                                HStack(spacing: TickerSpacing.xs) {
                                    Image(systemName: "gear")
                                        .Callout()
                                    Text("Open Settings")
                                        .TickerTitle()
                                }
                            }
                            .tickerSecondaryButton()

                        }
                    } else {
                        Button {
                            requestPermission()
                        } label: {
                            HStack(spacing: TickerSpacing.xs) {
                                if isRequesting {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "clock.badge.checkmark")
                                        .Callout()
                                    Text("Allow Tickers")
                                        .TickerTitle()
                                }
                            }
                        }
                        .tickerPrimaryButton()
                        .disabled(isRequesting)

                        Button {
                            TickerHaptics.selection()
                            onContinue()
                        } label: {
                            Text("Not Now")
                                .Caption()
                                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        }
                        .disabled(isRequesting)
                    }
                }
                .padding(.horizontal, TickerSpacing.lg)

                // Bottom spacer - fixed safe space
                Spacer()
                    .frame(height: geometry.size.height * 0.12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, TickerSpacing.lg)
            .onAppear {
                startAnimations()
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Icon bounce in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            iconScale = 1.0
        }

        // Pulsing glow
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }
    }

    // MARK: - Permission Handling

    private func requestPermission() {
        isRequesting = true
        TickerHaptics.standardAction()

        Task {
            do {
                let status = try await tickerService.requestAuthorization()

                await MainActor.run {
                    isRequesting = false

                    switch status {
                    case .authorized:
                        TickerHaptics.success()
                        // Auto-continue on success
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onContinue()
                        }
                    case .denied:
                        TickerHaptics.error()
                        permissionDenied = true
                    case .notDetermined:
                        // Shouldn't happen, but handle gracefully
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    TickerHaptics.error()
                    // Show error but allow continuing
                    permissionDenied = true
                }
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    @Previewable @Injected(\.tickerService) var tickerService
    AlarmKitPermissionView(onContinue: {
        print("Continue tapped")
    })
    .environment(tickerService)
}
