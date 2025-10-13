//
//  ExpandableOverlayContainer.swift
//  fig
//
//  Reusable overlay container with backdrop blur for expandable content
//

import SwiftUI

struct ExpandableOverlayContainer<Content: View>: View {
    let isPresented: Bool
    let onDismiss: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isPresented {
            VStack {
                Spacer()

                content()
                    .padding(.horizontal, TickerSpacing.md)
                    .padding(.bottom, TickerSpacing.lg)
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.95, anchor: .bottom))
                    )
            }
            .background(
                ZStack {
                    // Backdrop blur
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.95)
                        .ignoresSafeArea()

                    // Gradient overlay
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        onDismiss()
                    }
                }
            )
        }
    }
}
