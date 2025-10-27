//
//  NaturalLanguageOptionsPillsView.swift
//  fig
//
//  UI for displaying option pill buttons for Natural Language view (includes time pill)
//

import SwiftUI

struct NaturalLanguageOptionsPillsView: View {
    let viewModel: NaturalLanguageViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.lg) {
            // Enhanced section header with better visual hierarchy
            HStack {
                Text("PARSED OPTIONS")
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer()

                // Enhanced indicator for active options or parsing indicator
                if viewModel.aiGenerator.isParsing {
                    // Parsing indicator
                    HStack(spacing: TickerSpacing.xxs) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(TickerColor.primary)

                        Text("Parsing...")
                            .Caption2()
                            .foregroundStyle(TickerColor.primary)
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
                // Show shimmer when: actively parsing OR no configuration available yet
                // Show actual pills when: not parsing AND configuration is available
                if viewModel.aiGenerator.isParsing || viewModel.aiGenerator.parsedConfiguration == nil {
                    // Show shimmer loading state
                    shimmerPillsContent
                } else {
                    // Show actual parsed pills
                    actualPillsContent
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.aiGenerator.isParsing)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.aiGenerator.parsedConfiguration)
        }
    }

    // MARK: - Actual Pills Content

    @ViewBuilder
    private var actualPillsContent: some View {
        FlowLayout(spacing: TickerSpacing.md) {
                // Time pill (unique to Natural Language view)
                // contentTransition provides smooth updates as AI streams data
                expandablePillButton(
                    icon: "clock",
                    title: viewModel.timePickerViewModel.formattedTime,
                    field: .time,
                    hasValue: true
                )
                .contentTransition(.numericText())

                expandablePillButton(
                    icon: "calendar.badge.clock",
                    title: viewModel.optionsPillsViewModel.displaySchedule,
                    field: .schedule,
                    hasValue: viewModel.optionsPillsViewModel.hasScheduleValue
                )
                .contentTransition(.interpolate)

                expandablePillButton(
                    icon: "tag",
                    title: viewModel.optionsPillsViewModel.displayLabel,
                    field: .label,
                    hasValue: viewModel.optionsPillsViewModel.hasLabelValue
                )
                .contentTransition(.interpolate)

                expandablePillButton(
                    icon: "timer",
                    title: viewModel.optionsPillsViewModel.displayCountdown,
                    field: .countdown,
                    hasValue: viewModel.optionsPillsViewModel.hasCountdownValue
                )
                .contentTransition(.interpolate)

                // Icon pill uses the selected color as tint
                expandablePillButton(
                    icon: viewModel.iconPickerViewModel.selectedIcon,
                    title: "Icon",
                    field: .icon,
                    tintHex: viewModel.iconPickerViewModel.selectedColorHex,
                    hasValue: true
                )
                .contentTransition(.symbolEffect(.replace))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TickerSpacing.md)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: activeOptionsCount)
    }

    // MARK: - Shimmer Pills Content

    @ViewBuilder
    private var shimmerPillsContent: some View {
        FlowLayout(spacing: TickerSpacing.md) {
            // Time pill shimmer
            IntricateShimmerPill(size: .standard, estimatedWidth: 100)

            // Schedule pill shimmer
            IntricateShimmerPill(size: .standard, estimatedWidth: 120)

            // Label pill shimmer
            IntricateShimmerPill(size: .standard, estimatedWidth: 90)

            // Countdown pill shimmer
            IntricateShimmerPill(size: .standard, estimatedWidth: 110)

            // Icon pill shimmer
            IntricateShimmerPill(size: .standard, estimatedWidth: 80)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TickerSpacing.md)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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

    private var hasAnyActiveOptions: Bool {
        viewModel.optionsPillsViewModel.hasAnyActiveOptions || true // Time is always active
    }

    private var activeOptionsCount: Int {
        viewModel.optionsPillsViewModel.activeOptionsCount + 1 // +1 for time
    }
}
