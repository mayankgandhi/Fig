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
            // Header Section with App Icon
            headerSection

            // Content Section
            contentSection

            // Action Button
            actionButton
        }
        .padding(TickerSpacing.md)
        .glassEffect(in: .rect(cornerRadius: TickerRadius.xlarge))
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)
        .sheet(isPresented: $showPaywall) {
            GatePaywallView()
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: TickerSpacing.md) {
            // App Icon and Title Row
            HStack(spacing: TickerSpacing.md) {
                // App Icon
                appIconView
                
                VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                    Text(configuration.premiumBrandName)
                        .Title2()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                    subscriptionStatusText
                        .Subheadline()
                        .foregroundStyle(statusColor)
                }

                Spacer()
            }
            
            // Description
            if !subscriptionService.isSubscribed {
                Text("Unlock the full power of Ticker with premium features")
                    .Body()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var appIconView: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: TickerRadius.medium)
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
                .frame(width: 64, height: 64)
            
            // App Icon
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: TickerRadius.small))
                .shadow(color: TickerColor.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            TickerColor.primary.opacity(0.3),
                            TickerColor.accent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
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

    private var statusColor: Color {
        if subscriptionService.isLoading {
            return TickerColor.textSecondary(for: colorScheme)
        } else if subscriptionService.isSubscribed {
            return TickerColor.success
        } else {
            return TickerColor.primary
        }
    }

    // MARK: - Content Section
    
    @ViewBuilder
    private var contentSection: some View {
        if subscriptionService.isSubscribed {
            Text("Thanks for being a Pro Member! 🎉")
                .Headline()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TickerSpacing.md)
        }
    }
    
    private func featureRow(feature: PremiumFeature, isEnabled: Bool) -> some View {
        HStack(spacing: TickerSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        isEnabled
                            ? TickerColor.success.opacity(0.15)
                            : TickerColor.primary.opacity(0.15)
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        isEnabled
                            ? TickerColor.success
                            : TickerColor.primary
                    )
            }
            
            // Text
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(feature.title)
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                
                Text(feature.description)
                    .Caption()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Checkmark or lock
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(TickerColor.success)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme).opacity(0.5))
            }
        }
        .padding(TickerSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColor.surface(for: colorScheme).opacity(0.5))
        )
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button(action: handleButtonAction) {
            HStack(spacing: TickerSpacing.sm) {
                if subscriptionService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: buttonForegroundColor))
                } else {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .symbolEffect(.pulse, value: !subscriptionService.isSubscribed)

                    Text(buttonTitle)
                        .ButtonText()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: TickerSpacing.buttonHeightStandard)
            .background(buttonBackgroundColor)
            .foregroundStyle(buttonForegroundColor)
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
            .shadow(
                color: !subscriptionService.isSubscribed 
                    ? TickerColor.primary.opacity(0.3) 
                    : Color.clear,
                radius: !subscriptionService.isSubscribed ? 12 : 0,
                x: 0,
                y: !subscriptionService.isSubscribed ? 4 : 0
            )
        }
        .glassEffect(.regular.interactive())
        .disabled(subscriptionService.isLoading)
        .padding(.top, TickerSpacing.lg)
    }

    private var buttonBackgroundColor: Color {
        subscriptionService.isSubscribed
            ? TickerColor.surface(for: colorScheme)
            : TickerColor.primary
    }

    private var buttonForegroundColor: Color {
        subscriptionService.isSubscribed
            ? TickerColor.textPrimary(for: colorScheme)
            : TickerColor.absoluteWhite
    }

    private var buttonIcon: String {
        subscriptionService.isSubscribed ? "gear" : "sparkles"
    }

    private var buttonTitle: String {
        subscriptionService.isSubscribed ? "Manage Subscription" : "Upgrade to Pro"
    }

    // MARK: - Actions

    private func handleButtonAction() {
        TickerHaptics.selection()
        if subscriptionService.isSubscribed {
            // Open subscription management
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }
        } else {
            showPaywall = true
        }
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
