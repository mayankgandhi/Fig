//
//  TimePickerView.swift
//  fig
//
//  UI for selecting hour and minute
//

import SwiftUI

struct TimePickerView: View {
    @Bindable var viewModel: TimePickerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: TickerSpacing.sm) {
            // Title
            Text("Set Time")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

            // Time Pickers
            HStack(spacing: 0) {
                Picker("Hour", selection: $viewModel.selectedHour) {
                    ForEach(0..<24) { hour in
                        Text(String(format: "%02d", hour))
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 100)

                Text(":")
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(TickerColors.primary)
                    .padding(.horizontal, TickerSpacing.xs)

                Picker("Minute", selection: $viewModel.selectedMinute) {
                    ForEach(0..<60) { minute in
                        Text(String(format: "%02d", minute))
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 100)
            }
            .frame(height: 150)
        }
    }
}
