//
//  IconPickerView.swift
//  fig
//
//  SF Symbols icon picker with ViewModel support
//

import SwiftUI

struct IconPickerViewMVVM: View {
    @Bindable var viewModel: IconPickerViewModel
    @Environment(\.colorScheme) private var colorScheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: TickerSpacing.xs), count: 5)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: TickerSpacing.sm) {
                ForEach(IconColorPair.allIcons) { iconPair in
                    IconCell(
                        iconPair: iconPair,
                        isSelected: viewModel.selectedIcon == iconPair.symbol
                    ) {
                        selectIcon(iconPair)
                    }
                }
            }
        }
    }

    private func selectIcon(_ iconPair: IconColorPair) {
        TickerHaptics.selection()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            viewModel.selectIcon(iconPair.symbol, colorHex: iconPair.colorHex)
        }
    }
}

// MARK: - Icon Cell

private struct IconCell: View {
    let iconPair: IconColorPair
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle
                Circle()
                    .fill(iconPair.color.opacity(isSelected ? 0.2 : 0.1))
                    .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)

                // Glass effect layer
                if isSelected {
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)
                }

                // Icon
                Image(systemName: iconPair.symbol)
                    .Title3()
                    .foregroundStyle(iconPair.color)

                // Selection indicator
                if isSelected {
                    Circle()
                        .strokeBorder(iconPair.color, lineWidth: 2.5)
                        .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)
                }
            }
            .shadow(
                color: isSelected ? iconPair.color.opacity(0.3) : .clear,
                radius: isSelected ? 4 : 0,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
}

