//
//  TimePickerCard.swift
//  fig
//
//  A styled card wrapper for the time picker with Liquid Glass effects
//

import SwiftUI

struct TimePickerCard: View {
    let viewModel: TimePickerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimePickerView(viewModel: viewModel)
            .padding(.horizontal, TickerSpacing.md)
            .padding(.vertical, TickerSpacing.lg)
            .glassEffect(in: .rect(cornerRadius: TickerRadius.large))
            .shadow(color: Color.black.opacity(0.1), radius: 25, x: 0, y: 12)
            .shadow(color: TickerColor.primary.opacity(0.15), radius: 35, x: 0, y: 18)
            .padding(.horizontal, TickerSpacing.md)
            .padding(.top, TickerSpacing.md)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.selectedHour)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.selectedMinute)
    }
}
