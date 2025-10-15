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
    
    // Optional validation message from parent
    let validationMessage: String?
    let onFixMismatch: (() -> Void)?
    
    init(viewModel: RepeatOptionsViewModel, validationMessage: String? = nil, onFixMismatch: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.validationMessage = validationMessage
        self.onFixMismatch = onFixMismatch
    }

    var body: some View {
        VStack(spacing: TickerSpacing.md) {
            // Main Repeat Type Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TickerSpacing.xs) {
                    ForEach(RepeatOptionsViewModel.RepeatOption.allCases, id: \.self) { option in
                        repeatOptionButton(for: option)
                    }
                }
                .padding(.horizontal, TickerSpacing.md)
            }
            .padding(.vertical, TickerSpacing.sm)

            // Validation Message
            if let validationMessage = validationMessage {
                validationMessageView(message: validationMessage)
            }

            // Configuration View for selected option
            if viewModel.needsConfiguration {
                configurationView
            }
        }
    }

    @ViewBuilder
    private func repeatOptionButton(for option: RepeatOptionsViewModel.RepeatOption) -> some View {
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
            
            if let onFixMismatch = onFixMismatch {
                Button {
                    TickerHaptics.selection()
                    onFixMismatch()
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
