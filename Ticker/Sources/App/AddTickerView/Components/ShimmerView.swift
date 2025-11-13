//
//  ShimmerView.swift
//  fig
//
//  Shimmer loading effect for UI components
//

import SwiftUI
import TickerCore

struct ShimmerView: View {
    @State private var isAnimating = false
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct ShimmerPill: View {
    @State private var isAnimating = false
    let width: CGFloat
    let height: CGFloat

    init(width: CGFloat = 120, height: CGFloat = 40) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? width + 50 : -width - 50)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Intricate Shimmer Pill (Matches TickerPill Design)

struct IntricateShimmerPill: View {
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme

    let size: TickerPillSize
    let estimatedWidth: CGFloat

    init(size: TickerPillSize = .standard, estimatedWidth: CGFloat = 100) {
        self.size = size
        self.estimatedWidth = estimatedWidth
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            // Icon placeholder - circle with shimmer
            Circle()
                .fill(shimmerBaseColor)
                .frame(width: size.iconSize, height: size.iconSize)
                .overlay(
                    Circle()
                        .fill(shimmerHighlightGradient)
                        .offset(x: isAnimating ? estimatedWidth : -estimatedWidth)
                )

            // Text placeholder - rounded rectangle with shimmer
            RoundedRectangle(cornerRadius: 4)
                .fill(shimmerBaseColor)
                .frame(width: estimatedWidth - size.iconSize - size.spacing - (size.horizontalPadding * 2), height: size.iconSize * 0.8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerHighlightGradient)
                        .offset(x: isAnimating ? estimatedWidth : -estimatedWidth)
                )
        }
        .padding(.horizontal, size.horizontalPadding)
        .frame(width: estimatedWidth, height: size.height)
        .background(pillBackgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(pillBorderColor, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: 2,
            x: 0,
            y: 0.5
        )
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }

    // MARK: - Computed Properties

    private var shimmerBaseColor: Color {
        colorScheme == .dark
            ? Color.gray.opacity(0.3)
            : Color.gray.opacity(0.2)
    }

    private var shimmerHighlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.clear,
                colorScheme == .dark
                    ? Color.white.opacity(0.2)
                    : Color.white.opacity(0.4),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var pillBackgroundColor: Color {
        TickerColor.surface(for: colorScheme).opacity(0.5)
    }

    private var pillBorderColor: Color {
        TickerColor.textTertiary(for: colorScheme).opacity(0.15)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: TickerSpacing.lg) {
        Text("Shimmer Effects")
            .Title2()

        VStack(spacing: TickerSpacing.md) {
            Text("Intricate Shimmer Pills")
                .Caption()
                .foregroundStyle(.secondary)

            FlowLayout(spacing: TickerSpacing.md) {
                IntricateShimmerPill(size: .standard, estimatedWidth: 100)
                IntricateShimmerPill(size: .standard, estimatedWidth: 120)
                IntricateShimmerPill(size: .standard, estimatedWidth: 90)
                IntricateShimmerPill(size: .standard, estimatedWidth: 110)
                IntricateShimmerPill(size: .standard, estimatedWidth: 80)
            }
        }

        VStack(spacing: TickerSpacing.md) {
            Text("Basic Shimmer Pills (Legacy)")
                .Caption()
                .foregroundStyle(.secondary)

            HStack(spacing: TickerSpacing.sm) {
                ShimmerPill(width: 80, height: 32)
                ShimmerPill(width: 120, height: 32)
                ShimmerPill(width: 100, height: 32)
            }
        }

        VStack(spacing: TickerSpacing.md) {
            Text("Shimmer Cards")
                .Caption()
                .foregroundStyle(.secondary)

            VStack(spacing: TickerSpacing.sm) {
                ShimmerView(cornerRadius: 8)
                    .frame(height: 60)

                ShimmerView(cornerRadius: 8)
                    .frame(height: 40)
            }
        }

        Spacer()
    }
    .padding(TickerSpacing.md)
}
