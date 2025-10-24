//
//  IntroView.swift
//  Ticker
//
//  Created by Mayank Gandhi on 14/10/25.
//

import SwiftUI

struct IntroView: View {

    @Environment(\.colorScheme) var colorScheme
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top spacer - 20% of screen
                Spacer()
                    .frame(height: geometry.size.height * 0.20)

                VStack(alignment: .center, spacing: TickerSpacing.lg) {
                    // App Icon
                    Image("AppIconImage")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(
                            color: TickerShadow.elevated.color,
                            radius: TickerShadow.elevated.radius,
                            x: TickerShadow.elevated.x,
                            y: TickerShadow.elevated.y
                        )

                    // Title and subtitle
                    VStack(spacing: TickerSpacing.xs) {
                        Text("Welcome To Ticker")
                            .Title()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        Text("Never Forget What Matters Most")
                            .Headline()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)
                    }
                }

                // Middle spacer - flexible
                Spacer()

                // Continue button
                Button {
                    TickerHaptics.standardAction()
                    onContinue()
                } label: {
                    HStack(spacing: TickerSpacing.xs) {
                        Text("Continue")
                            .TickerTitle()

                        Image(systemName: "arrow.right")
                            .Callout()
                    }
                }
                .tickerPrimaryButton()
                .padding(.horizontal, TickerSpacing.lg)

                // Bottom spacer - fixed safe space
                Spacer()
                    .frame(height: geometry.size.height * 0.12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, TickerSpacing.lg)
        }
    }
}

#Preview {
    IntroView(onContinue: {
        print("Continue tapped")
    })
}
