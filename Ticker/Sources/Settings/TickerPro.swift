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
        .padding(TickerSpacing.xs)
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
        HStack(spacing: TickerSpacing.md) {
            // Pro Icon
            iconView

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
        .padding(.bottom, TickerSpacing.lg)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 40, height: 40)

            Image(systemName: iconSymbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
                .symbolEffect(.bounce, value: subscriptionService.isSubscribed)
        }
        .glassEffect(.regular.tint(iconColor))
    }

    private var iconSymbol: String {
        subscriptionService.isSubscribed ? "checkmark.seal.fill" : "sparkles"
    }

    private var iconColor: Color {
        subscriptionService.isSubscribed ? TickerColor.success : TickerColor.primary
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
            Text("Thanks for being a Pro Member!")
                .Headline()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TickerSpacing.md)
        } else {
            Text("Everything you need to stay on track")
                .Headline()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                .padding(.bottom, TickerSpacing.xs)
        }
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

                    Text(buttonTitle)
                        .ButtonText()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: TickerSpacing.buttonHeightStandard)
            .background(buttonBackgroundColor)
            .foregroundStyle(buttonForegroundColor)
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
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
