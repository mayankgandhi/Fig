import SwiftUI
import Gate
import TickerCore

/// Custom Ticker Pro subscription card with beautiful design
struct TickerPro: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showPaywall = false

    private let configuration = GateConfiguration.ticker
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Content Section
            contentSection
            
            // Action Button
            actionButton
        }
        .padding(TickerSpacing.lg)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: 16,
            x: 0,
            y: 8
        )
        .shadow(
            color: TickerColor.primary.opacity(0.1),
            radius: 24,
            x: 0,
            y: 12
        )
        .sheet(isPresented: $showPaywall) {
            GatePaywallView()
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: TickerSpacing.md) {
            // Pro Icon Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                TickerColor.primary,
                                TickerColor.accent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(TickerColor.absoluteWhite)
            }
            
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(configuration.premiumBrandName)
                    .Title2()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                
                subscriptionStatusText
                    .Subheadline()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(.bottom, TickerSpacing.lg)
    }
    
    private var subscriptionStatusText: Text {
        if subscriptionService.isLoading {
            return Text("Checking...")
        } else if subscriptionService.isSubscribed {
            return Text("Active")
        } else {
            return Text("Unlock Premium")
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            if !subscriptionService.isSubscribed {
                Text("Everything you need to stay on track")
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .padding(.bottom, TickerSpacing.xs)
            }

            // Features Grid
            featuresGrid
        }
    }
    
    private var featuresGrid: some View {
        VStack(spacing: TickerSpacing.sm) {
            ForEach(Array(configuration.premiumFeatures.enumerated()), id: \.element.id) { index, feature in
                featureRow(feature)
                
                if index < configuration.premiumFeatures.count - 1 {
                    Divider()
                        .background(TickerColor.textTertiary(for: colorScheme).opacity(0.3))
                }
            }
        }
    }
    
    private func featureRow(_ feature: PremiumFeature) -> some View {
        HStack(spacing: TickerSpacing.md) {
            // Feature Icon
            ZStack {
                RoundedRectangle(cornerRadius: TickerRadius.small)
                    .fill(
                        LinearGradient(
                            colors: [
                                TickerColor.primary.opacity(colorScheme == .dark ? 0.2 : 0.1),
                                TickerColor.accent.opacity(colorScheme == .dark ? 0.15 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [TickerColor.primary, TickerColor.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Feature Text
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(feature.title)
                    .Subheadline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                
                Text(feature.description)
                    .Caption()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, TickerSpacing.xs)
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            TickerHaptics.selection()
            if subscriptionService.isSubscribed {
                // Open subscription management
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: TickerSpacing.sm) {
                if subscriptionService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: TickerColor.absoluteWhite))
                } else {
                    Image(systemName: subscriptionService.isSubscribed ? "gear" : "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(subscriptionService.isSubscribed ? "Manage Subscription" : "Upgrade to Pro")
                    .ButtonText()
            }
            .frame(maxWidth: .infinity)
            .frame(height: TickerSpacing.buttonHeightStandard)
            .background(
                LinearGradient(
                    colors: subscriptionService.isSubscribed ? [
                        TickerColor.surface(for: colorScheme),
                        TickerColor.surface(for: colorScheme)
                    ] : [
                        TickerColor.primary,
                        TickerColor.accent
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(
                subscriptionService.isSubscribed
                    ? TickerColor.textPrimary(for: colorScheme)
                    : TickerColor.absoluteWhite
            )
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
            .overlay(
                Group {
                    if subscriptionService.isSubscribed {
                        RoundedRectangle(cornerRadius: TickerRadius.medium)
                            .strokeBorder(
                                TickerColor.textTertiary(for: colorScheme),
                                lineWidth: 1.5
                            )
                    }
                }
            )
        }
        .disabled(subscriptionService.isLoading)
        .padding(.top, TickerSpacing.lg)
    }
    
    // MARK: - Background & Styling
    
    private var cardBackground: some View {
        ZStack {
            // Base glass morphism layer
            RoundedRectangle(cornerRadius: TickerRadius.xlarge)
                .fill(.ultraThinMaterial)
            
            // Premium gradient overlay
            RoundedRectangle(cornerRadius: TickerRadius.xlarge)
                .fill(
                    LinearGradient(
                        colors: [
                            TickerColor.primary.opacity(colorScheme == .dark ? 0.15 : 0.08),
                            TickerColor.accent.opacity(colorScheme == .dark ? 0.12 : 0.06),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Subtle radial glow
            RoundedRectangle(cornerRadius: TickerRadius.xlarge)
                .fill(
                    RadialGradient(
                        colors: [
                            TickerColor.primary.opacity(colorScheme == .dark ? 0.1 : 0.05),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: TickerRadius.xlarge)
            .strokeBorder(
                TickerColor.primary.opacity(colorScheme == .dark ? 0.3 : 0.2),
                lineWidth: 1.5
            )
    }
}

#Preview("Light Mode") {
    TickerPro()
        .padding()
        .background(
            ZStack {
                TickerColor.liquidGlassGradient(for: .light)
                    .ignoresSafeArea()
                
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.1)
                    .ignoresSafeArea()
            }
        )
}

#Preview("Dark Mode") {
    TickerPro()
        .padding()
        .background(
            ZStack {
                TickerColor.liquidGlassGradient(for: .dark)
                    .ignoresSafeArea()
                
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.1)
                    .ignoresSafeArea()
            }
        )
        .preferredColorScheme(.dark)
}
