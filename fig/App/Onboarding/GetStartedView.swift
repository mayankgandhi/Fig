//
//  GetStartedView.swift
//  Ticker
//
//  Final onboarding screen with permissions and call-to-action
//

import SwiftUI
import UserNotifications

struct GetStartedView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var featuresVisible: Bool = false
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

    let onGetStarted: () -> Void

    private let features: [FeatureHighlight] = [
        FeatureHighlight(
            icon: "clock.fill",
            title: "Visual Clock",
            description: "See all your reminders on a beautiful clock face",
            color: .blue
        ),
        FeatureHighlight(
            icon: "bell.badge.fill",
            title: "Smart Alerts",
            description: "Never miss what matters with reliable notifications",
            color: .purple
        ),
        FeatureHighlight(
            icon: "repeat.circle.fill",
            title: "Flexible Repeating",
            description: "One-time or daily reminders, your choice",
            color: .green
        ),
        FeatureHighlight(
            icon: "timer",
            title: "Countdown Timers",
            description: "Add countdowns before your alarms trigger",
            color: .orange
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top spacer - reduced
                Spacer()
                    .frame(height: geometry.size.height * 0.06)

                // App Icon with celebration animation - smaller
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    TickerColor.primary.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(iconScale)

                    Image("AppIconImage")
                        .resizable()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(
                            color: TickerShadow.elevated.color,
                            radius: TickerShadow.elevated.radius,
                            x: TickerShadow.elevated.x,
                            y: TickerShadow.elevated.y
                        )
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                }

                // Spacing after icon
                Spacer()
                    .frame(height: TickerSpacing.md)

                // Title and subtitle
                VStack(spacing: TickerSpacing.xs) {
                    Text("You're All Set!")
                        .Title()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    Text("Here's what you can do with Ticker")
                        .Headline()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .padding(.horizontal, TickerSpacing.lg)

                // Spacing before features
                Spacer()
                    .frame(height: TickerSpacing.md)

                // Feature highlights - compact version, show only 2
                if featuresVisible {
                    VStack(spacing: TickerSpacing.sm) {
                        ForEach(Array(features.prefix(2).enumerated()), id: \.element.id) { index, feature in
                            CompactFeatureCard(feature: feature)
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                                        removal: .scale(scale: 0.9).combined(with: .opacity)
                                    )
                                )
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.1),
                                    value: featuresVisible
                                )
                        }
                    }
                    .padding(.horizontal, TickerSpacing.lg)
                }

                // Notification permission card - compact
                if notificationPermissionStatus == .notDetermined {
                    CompactNotificationCard {
                        requestNotificationPermission()
                    }
                    .padding(.horizontal, TickerSpacing.lg)
                    .padding(.top, TickerSpacing.sm)
                    .transition(.scale.combined(with: .opacity))
                }

                // Flexible spacer
                Spacer()

                // Get Started button
                VStack(spacing: TickerSpacing.sm) {
                    Button {
                        TickerHaptics.criticalAction()
                        onGetStarted()
                    } label: {
                        HStack(spacing: TickerSpacing.xs) {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .bold, design: .rounded))

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                    .tickerPrimaryButton()
                    .padding(.horizontal, TickerSpacing.lg)

                    if notificationPermissionStatus == .notDetermined {
                        Button {
                            TickerHaptics.selection()
                            onGetStarted()
                        } label: {
                            Text("Skip notifications for now")
                                .Caption()
                                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        }
                    }
                }

                // Bottom spacer
                Spacer()
                    .frame(height: geometry.size.height * 0.08)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startAnimations()
            checkNotificationPermission()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Icon bounce in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            iconScale = 1.0
        }

        // Subtle rotation
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            iconRotation = 5
        }

        withAnimation(.easeInOut(duration: 0.8).delay(1.1)) {
            iconRotation = 0
        }

        // Show features
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                featuresVisible = true
            }
        }
    }

    // MARK: - Notification Permission

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    notificationPermissionStatus = .authorized
                    TickerHaptics.success()
                } else {
                    notificationPermissionStatus = .denied
                }
            }
        }
    }
}

// MARK: - Feature Highlight Model

struct FeatureHighlight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Feature Card Component

struct FeatureCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let feature: FeatureHighlight

    var body: some View {
        HStack(alignment: .top, spacing: TickerSpacing.md) {
            // Icon
            Image(systemName: feature.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(feature.color)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(feature.color.opacity(0.15))
                )

            // Text content
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(feature.title)
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Text(feature.description)
                    .Callout()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(TickerSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.medium)
                        .strokeBorder(feature.color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Compact Feature Card Component

struct CompactFeatureCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let feature: FeatureHighlight

    var body: some View {
        HStack(alignment: .center, spacing: TickerSpacing.sm) {
            // Icon - smaller
            Image(systemName: feature.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(feature.color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(feature.color.opacity(0.15))
                )

            // Text content - condensed
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .Callout()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Text(feature.description)
                    .Caption()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, TickerSpacing.sm)
        .padding(.vertical, TickerSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.small)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.small)
                        .strokeBorder(feature.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Notification Permission Card

struct NotificationPermissionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            HStack(spacing: TickerSpacing.sm) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(TickerColor.primary)

                Text("Enable Notifications")
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Spacer()
            }

            Text("Get timely alerts so you never miss what's important")
                .Callout()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                TickerHaptics.standardAction()
                onRequest()
            } label: {
                Text("Allow Notifications")
            }
            .tickerSecondaryButton()
        }
        .padding(TickerSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.medium)
                        .strokeBorder(TickerColor.primary.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(
            color: TickerColor.primary.opacity(0.15),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - Compact Notification Permission Card

struct CompactNotificationCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let onRequest: () -> Void

    var body: some View {
        HStack(spacing: TickerSpacing.sm) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(TickerColor.primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(TickerColor.primary.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Enable Notifications")
                    .Callout()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Text("Stay updated with alerts")
                    .Caption()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                TickerHaptics.standardAction()
                onRequest()
            } label: {
                Text("Allow")
                    .Caption()
                    .foregroundStyle(.white)
                    .padding(.horizontal, TickerSpacing.sm)
                    .padding(.vertical, TickerSpacing.xxs)
                    .background(
                        Capsule()
                            .fill(TickerColor.primary)
                    )
            }
        }
        .padding(.horizontal, TickerSpacing.sm)
        .padding(.vertical, TickerSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.small)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.small)
                        .strokeBorder(TickerColor.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    GetStartedView(onGetStarted: {
        print("Get Started tapped")
    })
}
