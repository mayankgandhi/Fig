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
        VStack(spacing: TickerSpacing.xxxl) {
            Spacer()

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

                    Text("Never Forget What Matters Most")
                        .Headline()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Continue button
            Button {
                TickerHaptics.standardAction()
                onContinue()
            } label: {
                HStack(spacing: TickerSpacing.xs) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold, design: .rounded))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .tickerPrimaryButton()
            .padding(.horizontal, TickerSpacing.lg)

            Spacer()
                .frame(height: TickerSpacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, TickerSpacing.lg)
    }
}

#Preview {
    IntroView(onContinue: {
        print("Continue tapped")
    })
}
