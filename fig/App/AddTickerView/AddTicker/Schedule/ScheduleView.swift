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
            VStack(spacing: TickerSpacing.lg) {
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
        .background(TickerColor.background(for: colorScheme).ignoresSafeArea())
    }
    
    // MARK: - Repeat Options Section
    
    @ViewBuilder
    private var repeatOptionsSection: some View {
        VStack(spacing: TickerSpacing.md) {
            
            Text("Select a Repeat Frequency")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TickerSpacing.md)
            
            // Main Repeat Type Selector
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TickerSpacing.xs) {
                        ForEach(ScheduleViewModel.RepeatOption.allCases, id: \.self) { option in
                            repeatOptionButton(for: option)
                        }
                    }
                    .padding(.horizontal, TickerSpacing.md)
                }
            }
            
            // Validation Message
            if let validationMessage = viewModel.dateWeekdayMismatchMessage {
                validationMessageView(message: validationMessage)
                    .padding(.horizontal, TickerSpacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Configuration View for selected option
            if viewModel.needsConfiguration {
                configurationView
                    .padding(.horizontal, TickerSpacing.md)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
            case .daily:
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Perfect for everyday habits")
                        .Caption()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, TickerSpacing.md)
                }
                
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
    
    // MARK: - Validation Message View (Compact)
    
    @ViewBuilder
    private func validationMessageView(message: String) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            HStack(spacing: TickerSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .Footnote()
                    .foregroundStyle(TickerColor.warning)
                
                Text(message)
                    .Footnote()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            // Fix Date button
            Button {
                TickerHaptics.selection()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.adjustDateToMatchWeekdays()
                }
            } label: {
                HStack(spacing: TickerSpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .Caption()
                    Text("Fix Date")
                        .Caption()
                        .fontWeight(.semibold)
                }
                .foregroundStyle(TickerColor.primary)
                .padding(.horizontal, TickerSpacing.md)
                .padding(.vertical, TickerSpacing.sm)
                .background(
                    Capsule()
                        .fill(TickerColor.primary.opacity(0.12))
                )
            }
        }
        .padding(TickerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColor.warning.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .strokeBorder(TickerColor.warning.opacity(0.2), lineWidth: 1)
        )
    }
}
