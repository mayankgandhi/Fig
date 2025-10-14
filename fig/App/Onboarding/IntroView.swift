//
//  IntroView.swift
//  Ticker
//
//  Created by Mayank Gandhi on 14/10/25.
//

import SwiftUI

struct IntroView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var showDetails = false
    
    var body: some View {
        VStack(alignment: .center, spacing: TickerSpacing.md) {
            Image("AppIconImage")
                .resizable()
                .frame(width: 100, height: 100)
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                Text("Welcome To Ticker")
                    .Title()
                Text("Never Forget What Matters Most")
                    .Headline()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }
            
            Spacer()

            if showDetails {
                // Moves in from the bottom
                Text("Details go here.")
                    .transition(.move(edge: .bottom))
    
            } else {
                Button("Proceed") {
                    withAnimation {
                        showDetails.toggle()
                    }
                }
                .tickerPrimaryButton()
                .transition(.move(edge: .top))
                
            }
            
        }
        .padding(.horizontal, TickerSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(
            ZStack {
                TickerColor.liquidGlassGradient(for: colorScheme)
                    .ignoresSafeArea()

                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.1)
                        .ignoresSafeArea()
                }
            )
    }
}

#Preview {
    IntroView()
}
