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
        ScrollView {
            VStack(spacing: TickerSpacing.md) {
                // Repeat Options Section (moved to top)
                repeatOptionsSection
                
                // Calendar Date Picker (conditional, moved to bottom)
                if viewModel.shouldShowCalendar {
                    CalendarGrid(
                        selectedDate: $viewModel.selectedDate,
                        showStartDateLabel: false
                    )
                    .padding(.horizontal, TickerSpacing.md)
                }
            }
            .padding(.vertical, TickerSpacing.md)
        }
    }
    
    // MARK: - Repeat Options Section
    
    @ViewBuilder
    private var repeatOptionsSection: some View {
        VStack(spacing: TickerSpacing.md) {
            
            Text("Select a Repeat Frequency")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Main Repeat Type Selector with FlowLayout
            FlowLayout(spacing: TickerSpacing.xs) {
                ForEach(ScheduleViewModel.RepeatOption.allCases, id: \.self) { option in
                    repeatOptionButton(for: option)
                }
            }
            
            // Description for selected option
            Text(descriptionForOption(viewModel.selectedOption))
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TickerSpacing.xs)
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedOption)

            // Configuration View for selected option
            if viewModel.needsConfiguration {
                configurationView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.selectedOption)
            }
        }
    }
    
    // MARK: - Repeat Option Buttons
    
    @ViewBuilder
    private func repeatOptionButton(for option: ScheduleViewModel.RepeatOption) -> some View {
        Button {
            TickerHaptics.selection()
            viewModel.selectOption(option)
        } label: {
            TickerPill(
                icon: option.icon,
                title: option.rawValue,
                isActive: viewModel.selectedOption == option,
                hasValue: viewModel.selectedOption == option,
                size: .compact
            )
            .animation(.easeInOut(duration: 0.15), value: viewModel.selectedOption)
        }
    }
    
    private func descriptionForOption(_ option: ScheduleViewModel.RepeatOption) -> String {
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
    
    // MARK: - Configuration View
    
    @ViewBuilder
    private var configurationView: some View {
        switch viewModel.selectedOption {
            case .daily:
                EmptyView()
                
            case .weekdays:
                WeekdayPickerView(selectedWeekdays: $viewModel.selectedWeekdays)
                
            case .hourly:
                HourlyConfigView(
                    interval: $viewModel.hourlyInterval
                )
                
            case .every:
                EveryConfigView(
                    interval: $viewModel.everyInterval,
                    unit: $viewModel.everyUnit
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
    
}
