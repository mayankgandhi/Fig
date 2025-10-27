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
            // Main Repeat Type Selector with FlowLayout
            FlowLayout(spacing: TickerSpacing.xs) {
                ForEach(RepeatOptionsViewModel.RepeatOption.allCases, id: \.self) { option in
                    repeatOptionButton(for: option)
                }
            }
            .padding(.horizontal, TickerSpacing.md)
            .padding(.vertical, TickerSpacing.sm)
            
            // Description for selected option
            Text(descriptionForOption(viewModel.selectedOption))
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TickerSpacing.md)
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedOption)

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
    
    private func descriptionForOption(_ option: RepeatOptionsViewModel.RepeatOption) -> String {
        switch option {
        case .oneTime:
            return "Set for a specific date"
        case .daily:
            return "Perfect for everyday habits"
        case .weekdays:
            return "Monday through Friday"
        case .hourly:
            return "Repeats every hour or custom interval"
        case .every:
            return "Custom time intervals"
        case .biweekly:
            return "Every other week"
        case .monthly:
            return "Once per month"
        case .yearly:
            return "Once per year"
        }
    }

    @ViewBuilder
    private var configurationView: some View {
        switch viewModel.selectedOption {
        case .weekdays:
            WeekdayPickerView(selectedWeekdays: $viewModel.selectedWeekdays)

        case .hourly:
            HourlyConfigView(
                interval: $viewModel.hourlyInterval
            )

        case .every:
            EveryConfigView(
                interval: $viewModel.everyInterval,
                unit: $viewModel.everyUnit,
            )

        case .biweekly:
            BiweeklyConfigView(
                selectedWeekdays: $viewModel.biweeklyWeekdays
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
                    .Subheadline()
                    .foregroundStyle(TickerColor.warning)
                
                Text(message)
                    .Footnote()
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
                            .Caption()
                        Text("Fix Date")
                            .Caption()
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
