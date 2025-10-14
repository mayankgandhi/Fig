//
//  OnboardingContainerView.swift
//  Ticker
//
//  Manages the complete onboarding flow across 3 screens
//

import SwiftUI

struct OnboardingContainerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var currentPage: Int = 0
    @State private var animationComplete: Bool = false

    private let totalPages = 3

    var body: some View {
        ZStack {
            // Background gradient
            TickerColor.liquidGlassGradient(for: colorScheme)
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Page 1: Welcome Screen
                IntroView(onContinue: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentPage = 1
                    }
                })
                .tag(0)

                // Page 2: Animation Demo
                IntroAnimation(onComplete: {
                    animationComplete = true
                    // Auto-advance after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage = 2
                        }
                    }
                })
                .tag(1)

                // Page 3: Get Started
                GetStartedView(onGetStarted: {
                    completeOnboarding()
                })
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Custom page indicators
            VStack {
                Spacer()

                if currentPage < 2 {
                    PageIndicator(currentPage: currentPage, totalPages: totalPages)
                        .padding(.bottom, TickerSpacing.xxxl)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .ignoresSafeArea()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
    }

    private func completeOnboarding() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasCompletedOnboarding = true
        }
        TickerHaptics.success()
    }
}

// MARK: - Page Indicator Component

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: TickerSpacing.sm) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? TickerColor.primary : TickerColor.textTertiary(for: colorScheme))
                    .frame(
                        width: index == currentPage ? 24 : 8,
                        height: 8
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}

#Preview("Onboarding Flow") {
    OnboardingContainerView()
}
