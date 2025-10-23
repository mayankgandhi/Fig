//
//  ShimmerView.swift
//  fig
//
//  Shimmer loading effect for UI components
//

import SwiftUI

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

// MARK: - Preview

#Preview {
    VStack(spacing: TickerSpacing.lg) {
        Text("Shimmer Effects")
            .Title2()
        
        VStack(spacing: TickerSpacing.md) {
            Text("Shimmer Pills")
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
