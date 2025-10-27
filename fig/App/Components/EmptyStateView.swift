//
//  EmptyStateView.swift
//  fig
//
//  Empty state component for ContentView
//

import SwiftUI

struct EmptyStateView: View {
    
    let isEmpty: Bool // true = no tickers, false = no search results
    let searchText: String
    let onAddTicker: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ContentUnavailableView {
            Text(isEmpty ? "No Tickers" : "No Results")
                .Title3()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
        } description: {
            Text(isEmpty ? "Add a new ticker by tapping + button." : "No tickers match '\(searchText)'")
                .Body()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
        } actions: {
            if isEmpty {
                Button {
                    TickerHaptics.criticalAction()
                    onAddTicker()
                } label: {
                    HStack(spacing: TickerSpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .Callout()
                        Text("Add Ticker")
                            .ButtonText()
                    }
                    .foregroundStyle(TickerColor.absoluteWhite)
                    .padding(.horizontal, TickerSpacing.xl)
                    .padding(.vertical, TickerSpacing.md)
                    .background(
                        Capsule()
                            .fill(TickerColor.primary)
                    )
                    .shadow(
                        color: TickerColor.primary.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptyStateView(
            isEmpty: true,
            searchText: "",
            onAddTicker: {}
        )
        
        EmptyStateView(
            isEmpty: false,
            searchText: "test",
            onAddTicker: {}
        )
    }
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
}
