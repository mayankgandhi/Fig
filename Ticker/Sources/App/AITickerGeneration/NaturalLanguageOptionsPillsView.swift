//
//  NaturalLanguageOptionsPillsView.swift
//  fig
//
//  UI for displaying option pill buttons for Natural Language view (includes time pill)
//

import SwiftUI
import TickerCore

struct NaturalLanguageOptionsPillsView: View {
    let viewModel: NaturalLanguageViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.lg) {
            // Enhanced section header with better visual hierarchy
            HStack {
                Text("TICKER DETAILS")
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer()

                // Enhanced indicator for active options or parsing indicator
                if viewModel.isParsing {
                    // Parsing indicator with offline/fallback mode context
                    HStack(spacing: TickerSpacing.xxs) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint((viewModel.isOfflineMode || viewModel.isFallbackMode) ? TickerColor.textSecondary(for: colorScheme) : TickerColor.primary)

                        Text(parsingText(for: viewModel))
                            .Caption2()
                            .foregroundStyle((viewModel.isOfflineMode || viewModel.isFallbackMode) ? TickerColor.textSecondary(for: colorScheme) : TickerColor.primary)
                    }
                } else if hasAnyActiveOptions {
                    HStack(spacing: TickerSpacing.xxs) {
                        Circle()
                            .fill(TickerColor.primary)
                            .frame(width: 6, height: 6)
                            .opacity(0.8)

                        Text("\(activeOptionsCount)")
                            .Caption2()
                            .foregroundStyle(TickerColor.primary)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.horizontal, TickerSpacing.md)

            // Enhanced pill layout with improved spacing and alignment
            Group {
                // Show empty state when input is empty
                if isInputEmpty {
                    emptyStateContent
                } else {
                    // Show actual parsed pills progressively as data streams in
                    actualPillsContent
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isParsing)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.parsedConfiguration)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isInputEmpty)
        }
    }

    // MARK: - Actual Pills Content

    @ViewBuilder
    private var actualPillsContent: some View {
        FlowLayout(spacing: TickerSpacing.md) {
            // Time pill - always show once we have any input
            if hasTimeValue {
                expandablePillButton(
                    icon: "clock",
                    title: viewModel.timePickerViewModel.formattedTime,
                    field: .time,
                    hasValue: true
                )
                .contentTransition(.numericText())
                .transition(.scale.combined(with: .opacity))
            }

            // Schedule pill - show when parsed configuration is available
            if viewModel.parsedConfiguration != nil {
                expandablePillButton(
                    icon: "calendar.badge.clock",
                    title: viewModel.optionsPillsViewModel.displaySchedule,
                    field: .schedule,
                    hasValue: viewModel.optionsPillsViewModel.hasScheduleValue
                )
                .contentTransition(.interpolate)
                .transition(.scale.combined(with: .opacity))
            }

            // Label pill - show when parsed configuration is available
            if viewModel.parsedConfiguration != nil {
                expandablePillButton(
                    icon: "tag",
                    title: viewModel.optionsPillsViewModel.displayLabel,
                    field: .label,
                    hasValue: viewModel.optionsPillsViewModel.hasLabelValue
                )
                .contentTransition(.interpolate)
                .transition(.scale.combined(with: .opacity))
            }

            // Countdown pill - show when parsed configuration is available
            if viewModel.parsedConfiguration != nil {
                expandablePillButton(
                    icon: "timer",
                    title: viewModel.optionsPillsViewModel.displayCountdown,
                    field: .countdown,
                    hasValue: viewModel.optionsPillsViewModel.hasCountdownValue
                )
                .contentTransition(.interpolate)
                .transition(.scale.combined(with: .opacity))
            }

            // Sound pill - show when parsed configuration is available
            if viewModel.parsedConfiguration != nil {
                expandablePillButton(
                    icon: "speaker.wave.2",
                    title: viewModel.optionsPillsViewModel.displaySound,
                    field: .sound,
                    hasValue: viewModel.optionsPillsViewModel.hasSoundValue
                )
                .contentTransition(.interpolate)
                .transition(.scale.combined(with: .opacity))
            }

            // Icon pill - show only when icon value is received (not default)
            if hasIconValue {
                expandablePillButton(
                    icon: viewModel.iconPickerViewModel.selectedIcon,
                    title: "Icon",
                    field: .icon,
                    tintHex: viewModel.iconPickerViewModel.selectedColorHex,
                    hasValue: true
                )
                .contentTransition(.symbolEffect(.replace))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TickerSpacing.md)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: activeOptionsCount)
    }

    // MARK: - Empty State Content

    @ViewBuilder
    private var emptyStateContent: some View {
        VStack(spacing: TickerSpacing.md) {
            Text("Start typing to see ticker details")
                .Body()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.sm)
    }


    // MARK: - Pill Buttons

    @ViewBuilder
    private func expandablePillButton(
        icon: String,
        title: String,
        field: ExpandableField,
        tintHex: String? = nil,
        hasValue: Bool = false
    ) -> some View {
        Button {
            TickerHaptics.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                viewModel.optionsPillsViewModel.toggleField(field)
            }
        } label: {
            TickerPill(
                icon: icon,
                title: title,
                isActive: viewModel.optionsPillsViewModel.expandedField == field,
                hasValue: hasValue,
                size: .standard,
                iconTintColor: (title == "Icon") ? (Color(hex: tintHex ?? "") ?? TickerColor.primary) : nil
            )
        }
    }

    // MARK: - Computed Properties

    private var isInputEmpty: Bool {
        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasAnyActiveOptions: Bool {
        hasTimeValue || viewModel.optionsPillsViewModel.hasAnyActiveOptions
    }

    private var activeOptionsCount: Int {
        var count = 0
        if hasTimeValue { count += 1 }
        if viewModel.optionsPillsViewModel.hasScheduleValue { count += 1 }
        if viewModel.optionsPillsViewModel.hasLabelValue { count += 1 }
        if viewModel.optionsPillsViewModel.hasCountdownValue { count += 1 }
        if viewModel.optionsPillsViewModel.hasSoundValue { count += 1 }
        if hasIconValue { count += 1 }
        return count
    }
    
    // Check if time value has been received
    private var hasTimeValue: Bool {
        // Time is considered received if we have a parsed configuration
        // Time is always parsed, so show it once we have any config
        return viewModel.parsedConfiguration != nil
    }

    // Check if icon value has been received
    private var hasIconValue: Bool {
        // Icon is considered received if we have a parsed configuration
        // Icon is always parsed, so show it once we have any config
        return viewModel.parsedConfiguration != nil
    }

    private func parsingText(for viewModel: NaturalLanguageViewModel) -> String {
        if viewModel.isOfflineMode {
            return "Parsing Offline..."
        } else if viewModel.isFallbackMode {
            return "Retrying..."
        } else {
            return "Parsing..."
        }
    }
}
