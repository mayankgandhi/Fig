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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if isPresented {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(TickerColor.textTertiary(for: colorScheme))
                        .frame(width: 36, height: 4)
                        .padding(.top, TickerSpacing.md)
                        .padding(.bottom, TickerSpacing.sm)

                    content()
                        .padding(.horizontal, TickerSpacing.md)
                        .padding(.bottom, TickerSpacing.lg)
                }
                .background(
                    RoundedRectangle(cornerRadius: TickerRadius.large, style: .continuous)
                        .fill(TickerColor.surface(for: colorScheme).opacity(0.95))
                        .background(.ultraThinMaterial.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: TickerRadius.large, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            TickerColor.primary.opacity(0.3),
                                            TickerColor.primary.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.15),
                            radius: 20,
                            x: 0,
                            y: -10
                        )
                )
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom)
                                .combined(with: .opacity)
                                .combined(with: .scale(scale: 0.9, anchor: .bottom))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8)),
                            removal: .move(edge: .bottom)
                                .combined(with: .opacity)
                                .combined(with: .scale(scale: 0.95, anchor: .bottom))
                                .animation(.spring(response: 0.3, dampingFraction: 0.9))
                        )
                    )
            }
            .background(
                ZStack {
                    // Enhanced backdrop blur with better material
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.98)
                        .ignoresSafeArea()

                    // Dynamic gradient overlay based on color scheme
                    LinearGradient(
                        colors: colorScheme == .dark ? [
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.3)
                        ] : [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    // Subtle primary color wash
                    LinearGradient(
                        colors: [
                            TickerColor.primary.opacity(0.05),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                .onTapGesture {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        onDismiss()
                    }
                }
            )
            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }
}
