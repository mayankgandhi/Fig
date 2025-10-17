//
//  ScheduleView.swift
//  fig
//
//  Unified UI for date selection and repeat frequency configuration
//  Combines CalendarPickerView and RepeatOptionsView with built-in validation
//

import SwiftUI

struct ScheduleView: View {
    @Bindable var viewModel: ScheduleViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: TickerSpacing.lg) {
            // Calendar Date Picker
            CalendarGrid(selectedDate: $viewModel.selectedDate)

            Divider()
                .padding(.horizontal, TickerSpacing.md)

            // Repeat Options
            repeatOptionsSection
        }
    }

    // MARK: - Repeat Options Section

    @ViewBuilder
    private var repeatOptionsSection: some View {
        VStack(spacing: TickerSpacing.md) {
            // Main Repeat Type Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TickerSpacing.xs) {
                    ForEach(ScheduleViewModel.RepeatOption.allCases, id: \.self) { option in
                        repeatOptionButton(for: option)
                    }
                }
                .padding(.horizontal, TickerSpacing.md)
            }
            .padding(.vertical, TickerSpacing.sm)

            // Validation Message (baked in)
            if let validationMessage = viewModel.dateWeekdayMismatchMessage {
                validationMessageView(message: validationMessage)
            }

            // Configuration View for selected option
            if viewModel.needsConfiguration {
                configurationView
            }
        }
    }

    // MARK: - Repeat Option Buttons

    @ViewBuilder
    private func repeatOptionButton(for option: ScheduleViewModel.RepeatOption) -> some View {
        Button {
            TickerHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectOption(option)
            }
        } label: {
            TickerPill(
                icon: option.icon,
                title: option.rawValue,
                isActive: viewModel.selectedOption == option,
                hasValue: viewModel.selectedOption == option,
                size: .compact
            )
        }
    }

    // MARK: - Configuration View

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

        case .every:
            EveryConfigView(
                interval: $viewModel.everyInterval,
                unit: $viewModel.everyUnit,
                startTime: $viewModel.everyStartTime,
                endTime: $viewModel.everyEndTime
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

    // MARK: - Validation Message View

    @ViewBuilder
    private func validationMessageView(message: String) -> some View {
        VStack(spacing: TickerSpacing.sm) {
            HStack(spacing: TickerSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(TickerColor.warning)

                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.leading)

                Spacer()
            }

            // Fix Date button
            Button {
                TickerHaptics.selection()
                viewModel.adjustDateToMatchWeekdays()
            } label: {
                HStack(spacing: TickerSpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                    Text("Fix Date")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(TickerColor.primary)
                .padding(.horizontal, TickerSpacing.sm)
                .padding(.vertical, TickerSpacing.xs)
                .background(
                    Capsule()
                        .fill(TickerColor.primary.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(TickerColor.primary.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColor.warning.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .strokeBorder(TickerColor.warning.opacity(0.3), lineWidth: 1)
        )
    }
}
