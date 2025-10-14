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
        VStack(spacing: TickerSpacing.md) {
            // Main Repeat Type Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TickerSpacing.xs) {
                    ForEach(RepeatOption.allCases, id: \.self) { option in
                        repeatOptionButton(for: option)
                    }
                }
                .padding(.horizontal, TickerSpacing.md)
            }
            .padding(.vertical, TickerSpacing.sm)
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

            // Configuration View for selected option
            if viewModel.needsConfiguration {
                configurationView
            }
        }
    }

    @ViewBuilder
    private func repeatOptionButton(for option: RepeatOption) -> some View {
        Button {
            TickerHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectOption(option)
            }
        } label: {
            HStack(spacing: TickerSpacing.xxs) {
                Image(systemName: option.icon)
                    .font(.system(size: 13, weight: .medium))
                Text(option.rawValue)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(viewModel.selectedOption == option ? TickerColor.absoluteWhite : TickerColor.textPrimary(for: colorScheme))
            .padding(.horizontal, TickerSpacing.md)
            .padding(.vertical, TickerSpacing.sm)
            .background(viewModel.selectedOption == option ? TickerColor.primary : TickerColor.surface(for: colorScheme).opacity(0.5))
            .background(.ultraThinMaterial.opacity(0.2))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        viewModel.selectedOption == option ? TickerColor.primary.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
    }

    @ViewBuilder
    private var configurationView: some View {
        switch viewModel.selectedOption {
        case .weekdays:
            WeekdayPickerView(selectedWeekdays: $viewModel.selectedWeekdays)

        case .hourly:
            HourlyConfigView(
                interval: $viewModel.hourlyInterval,
                startTime: $viewModel.hourlyStartTime,
                endTime: $viewModel.hourlyEndTime
            )

        case .biweekly:
            BiweeklyConfigView(
                selectedWeekdays: $viewModel.biweeklyWeekdays,
                anchorDate: $viewModel.biweeklyAnchorDate
            )

        case .monthly:
            MonthlyConfigView(
                dayType: $viewModel.monthlyDayType,
                fixedDay: $viewModel.monthlyFixedDay,
                weekday: $viewModel.monthlyWeekday
            )

        case .yearly:
            YearlyConfigView(
                month: $viewModel.yearlyMonth,
                day: $viewModel.yearlyDay
            )

        default:
            EmptyView()
        }
    }
}
