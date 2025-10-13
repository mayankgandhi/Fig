//
//  CalendarPickerView.swift
//  fig
//
//  UI wrapper for calendar date selection
//

import SwiftUI

struct CalendarPickerView: View {
    @Bindable var viewModel: CalendarPickerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        CalendarGrid(selectedDate: $viewModel.selectedDate)
            .padding(TickerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .fill(TickerColors.surface(for: colorScheme).opacity(0.95))
            )
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
