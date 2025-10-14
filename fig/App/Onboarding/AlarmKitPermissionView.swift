//
//  AlarmKitPermissionView.swift
//  Ticker
//
//  Dedicated screen for requesting AlarmKit permissions during onboarding
//

import SwiftUI

struct AlarmKitPermissionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AlarmService.self) private var alarmService

    @State private var isRequesting = false
    @State private var permissionDenied = false
    @State private var iconScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0

    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: TickerSpacing.xxxl) {
            Spacer()

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
                        .frame(width: 120, height: 120)
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
                        .font(.system(size: 52, weight: .semibold))
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

            // Title and description
            VStack(spacing: TickerSpacing.sm) {
                Text("Allow Ticker to Schedule Alarms")
                    .Title()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)

                Text("Ticker needs permission to schedule alarms so you can receive timely reminders")
                    .Headline()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, TickerSpacing.xl)

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
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Open Settings")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                        }
                        .tickerSecondaryButton()

                        Button {
                            TickerHaptics.selection()
                            onContinue()
                        } label: {
                            Text("Continue Without Alarms")
                                .Caption()
                                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        }
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
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Allow Alarms")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
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

            Spacer()
                .frame(height: TickerSpacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, TickerSpacing.lg)
        .onAppear {
            startAnimations()
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
                let status = try await alarmService.requestAuthorization()

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
    AlarmKitPermissionView(onContinue: {
        print("Continue tapped")
    })
    .environment(AlarmService())
}
