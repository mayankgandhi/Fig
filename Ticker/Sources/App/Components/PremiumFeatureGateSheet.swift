//
//  PremiumFeatureGateSheet.swift
//  Ticker
//
//  Custom bottom sheet for premium feature gates, styled like AlarmKitPermissionSheet
//

import SwiftUI
import Gate
import TickerCore

struct PremiumFeatureGateSheet: View {
    // MARK: - Properties
    
    @Environment(\.colorScheme) var colorScheme
    
    let feature: PremiumFeature
    let onDismiss: () -> Void
    let onGoPro: () -> Void
    @State private var isVisible = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Hero Section - Icon with prominence
            iconView
                .padding(.top, TickerSpacing.xxl)
                .padding(.bottom, TickerSpacing.xl)

            // Primary Content Section
            VStack(spacing: TickerSpacing.lg) {
                // Title and Description Group
                VStack(spacing: TickerSpacing.sm) {
                    titleView
                    descriptionView
                }
                .padding(.horizontal, TickerSpacing.sm)
                
                // Instruction Card (if available) - Elevated section
                if let instruction = feature.instruction {
                    instructionView(instruction: instruction)
                        .padding(.horizontal, TickerSpacing.sm)
                }
            }
            .padding(.bottom, TickerSpacing.xl)

            Spacer(minLength: TickerSpacing.lg)

            // Action Section - Fixed at bottom
            actionButton
        }
        .padding(.horizontal, TickerSpacing.xl)
        .padding(.bottom, TickerSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .opacity(isVisible ? 1.0 : 0)
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }

    // MARK: - Subviews

    private var iconView: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            TickerColor.primary.opacity(0.15),
                            TickerColor.primary.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
            
            // Main icon container
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            TickerColor.primary.opacity(0.25),
                            TickerColor.primary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .shadow(
                    color: TickerColor.primary.opacity(0.2),
                    radius: 16,
                    x: 0,
                    y: 8
                )

            Image(systemName: feature.icon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            TickerColor.absoluteWhite,
                            TickerColor.absoluteWhite.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .glassEffect(.regular.tint(TickerColor.primary))
    }

    private var titleView: some View {
        Text(feature.title)
            .Title()
            .foregroundStyle(TickerColor.textPrimary(for: .dark))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }
    
    private func instructionView(instruction: String) -> some View {
        HStack(alignment: .top, spacing: TickerSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(TickerColor.primary)
                .padding(.top, 2)
            
            Text(instruction)
                .Callout()
                .foregroundStyle(TickerColor.textPrimary(for: .dark))
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(TickerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .strokeBorder(
                        TickerColor.primary.opacity(0.2),
                        lineWidth: 1
                    )
            }
        }
        .shadow(
            color: TickerShadow.subtle.color,
            radius: TickerShadow.subtle.radius,
            x: TickerShadow.subtle.x,
            y: TickerShadow.subtle.y
        )
    }

    private var descriptionView: some View {
        Text("This is a Ticker Pro feature. Upgrade to unlock \(feature.title.lowercased()) and more.")
            .Body()
            .foregroundStyle(TickerColor.textSecondary(for: .dark))
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actionButton: some View {
        Button(action: handleGoProAction) {
            HStack(spacing: TickerSpacing.sm) {
                Text("Go Pro")
                    .Headline()
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: TickerSpacing.buttonHeightLarge)
        }
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .fill(
                    LinearGradient(
                        colors: [
                            TickerColor.primary,
                            TickerColor.primaryDark
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: TickerColor.primary.opacity(0.4),
                    radius: 16,
                    x: 0,
                    y: 6
                )
        )
        .glassEffect(.regular.interactive())
    }

    private var backgroundGradient: some View {
        TickerColor.liquidGlassGradient(for: .dark)
            .ignoresSafeArea()
    }

    // MARK: - Actions

    private func handleGoProAction() {
        TickerHaptics.standardAction()
        onDismiss()
        // Small delay to allow sheet dismissal animation
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            onGoPro()
        }
    }
}

// MARK: - Preview

#Preview {
    PremiumFeatureGateSheet(
        feature: .aiAlarmCreation,
        onDismiss: {},
        onGoPro: {}
    )
    .presentationDetents([.medium])
}

