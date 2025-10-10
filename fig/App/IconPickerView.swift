//
//  IconPickerView.swift
//  fig
//
//  SF Symbols icon picker with predefined colors
//  Grid-based selection UI for alarm customization
//

import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Binding var selectedColorHex: String
    @Environment(\.colorScheme) private var colorScheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: TickerSpacing.xs), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TickerSpacing.xs) {
                    ForEach(IconColorPair.IconCategory.allCases, id: \.self) { category in
                        CategoryTab(
                            category: category,
                            isSelected: false
                        )
                    }
                }
            }

            // Icons grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: TickerSpacing.sm) {
                    ForEach(IconColorPair.allIcons) { iconPair in
                        IconCell(
                            iconPair: iconPair,
                            isSelected: selectedIcon == iconPair.symbol
                        ) {
                            selectIcon(iconPair)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(TickerSpacing.md)
        .background(TickerColors.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
    }

    private func selectIcon(_ iconPair: IconColorPair) {
        TickerHaptics.selection()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            selectedIcon = iconPair.symbol
            selectedColorHex = iconPair.colorHex
        }
    }
}

// MARK: - Category Tab

private struct CategoryTab: View {
    let category: IconColorPair.IconCategory
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(category.rawValue)
            .cabinetCaption2()
            .foregroundStyle(isSelected ? TickerColors.absoluteWhite : TickerColors.textSecondary(for: colorScheme))
            .padding(.horizontal, TickerSpacing.sm)
            .padding(.vertical, TickerSpacing.xs)
            .background(isSelected ? TickerColors.primary : TickerColors.surface(for: colorScheme).opacity(0.5))
            .clipShape(Capsule())
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

                // Icon
                Image(systemName: iconPair.symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(iconPair.color)

                // Selection indicator
                if isSelected {
                    Circle()
                        .strokeBorder(iconPair.color, lineWidth: 2.5)
                        .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedIcon = "alarm"
    @Previewable @State var selectedColorHex = "#8B5CF6"

    IconPickerView(selectedIcon: $selectedIcon, selectedColorHex: $selectedColorHex)
        .padding()
}
