//
//  OptionsPillsView.swift
//  fig
//
//  UI for displaying option pill buttons with expansion control
//

import SwiftUI

struct OptionsPillsView: View {
    @Bindable var viewModel: OptionsPillsViewModel
    let selectedIcon: String
    let selectedColorHex: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Enhanced section header
            HStack {
                Text("OPTIONS")
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)
                
                Spacer()
                
                // Subtle indicator for active options
                if viewModel.hasAnyActiveOptions {
                    Circle()
                        .fill(TickerColor.primary)
                        .frame(width: 6, height: 6)
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, TickerSpacing.md)

            // Enhanced pill layout with consistent styling
            FlowLayout(spacing: TickerSpacing.sm) {
                expandablePillButton(
                    icon: "calendar.badge.clock",
                    title: viewModel.displaySchedule,
                    field: .schedule
                )

                expandablePillButton(
                    icon: "tag",
                    title: viewModel.displayLabel,
                    field: .label
                )

                expandablePillButton(
                    icon: "timer",
                    title: viewModel.displayCountdown,
                    field: .countdown
                )

                // Icon pill uses the selected color as tint
                expandablePillButton(
                    icon: selectedIcon,
                    title: "Icon",
                    field: .icon,
                    tintHex: selectedColorHex
                )

                pillButton(
                    icon: "bell.badge",
                    title: "Snooze",
                    isActive: viewModel.enableSnooze
                ) {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.enableSnooze.toggle()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TickerSpacing.md)
        }
    }

    // MARK: - Pill Buttons

    @ViewBuilder
    private func expandablePillButton(
        icon: String,
        title: String,
        field: ExpandableField,
        tintHex: String? = nil
    ) -> some View {
        Button {
            TickerHaptics.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                viewModel.toggleField(field)
            }
        } label: {
            TickerPill(
                icon: icon,
                title: title,
                isActive: viewModel.expandedField == field,
                hasValue: viewModel.hasValue(for: field),
                size: .standard,
                iconTintColor: (title == "Icon") ? (Color(hex: tintHex ?? "") ?? TickerColor.primary) : nil
            )
        }
    }

    @ViewBuilder
    private func pillButton(
        icon: String,
        title: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            TickerPill(
                icon: icon,
                title: title,
                isActive: isActive,
                hasValue: isActive,
                size: .standard
            )
        }
    }
    
}

