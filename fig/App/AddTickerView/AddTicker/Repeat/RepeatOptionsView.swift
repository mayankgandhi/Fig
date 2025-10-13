//
//  RepeatOptionsView.swift
//  fig
//
//  UI for selecting repeat frequency
//

import SwiftUI

struct RepeatOptionsView: View {
    @Bindable var viewModel: RepeatOptionsViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: TickerSpacing.xs) {
            ForEach(RepeatOption.allCases, id: \.self) { option in
                Button {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectOption(option)
                    }
                } label: {
                    HStack(spacing: TickerSpacing.xxs) {
                        Image(systemName: option.icon)
                            .font(.system(size: 14, weight: .medium))
                        Text(option.rawValue)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(viewModel.selectedOption == option ? TickerColor.absoluteWhite : TickerColor.textPrimary(for: colorScheme))
                    .padding(.horizontal, TickerSpacing.md)
                    .padding(.vertical, TickerSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.selectedOption == option ? TickerColor.primary : TickerColor.surface(for: colorScheme).opacity(0.5))
                    .background(.ultraThinMaterial.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: TickerRadius.small))
                }
            }
        }
        .padding(TickerSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .fill(TickerColor.surface(for: colorScheme).opacity(0.95))
        )
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
    }
}
