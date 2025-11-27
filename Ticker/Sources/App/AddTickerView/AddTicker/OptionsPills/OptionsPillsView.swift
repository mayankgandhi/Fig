//
//  OptionsPillsView.swift
//  fig
//
//  UI for displaying option pill buttons with expansion control
//

import SwiftUI
import TickerCore

struct OptionsPillsView: View {
    @Bindable var viewModel: OptionsPillsViewModel
    let selectedIcon: String
    let selectedColorHex: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.lg) {
            // Enhanced section header with better visual hierarchy
            HStack {
                Text("OPTIONS")
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)
                
                Spacer()
                
                // Enhanced indicator for active options
                if viewModel.hasAnyActiveOptions {
                    HStack(spacing: TickerSpacing.xxs) {
                        Circle()
                            .fill(TickerColor.primary)
                            .frame(width: 6, height: 6)
                            .opacity(0.8)
                        
                        Text("\(viewModel.activeOptionsCount)")
                            .Caption2()
                            .foregroundStyle(TickerColor.primary)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.horizontal, TickerSpacing.md)

            // Enhanced pill layout with improved spacing and alignment
            FlowLayout(spacing: TickerSpacing.md) {
            
                if viewModel.scheduleViewModel != nil {
                    expandablePillButton(
                        icon: "calendar.badge.clock",
                        title: viewModel.displaySchedule,
                        field: .schedule
                    )
                }
                
                if viewModel.iconViewModel != nil {
                    // Icon pill uses the selected color as tint
                    expandablePillButton(
                        icon: selectedIcon,
                        title: "Icon",
                        field: .icon,
                        tintHex: selectedColorHex
                    )
                }
                
                if viewModel.labelViewModel != nil {
                    expandablePillButton(
                        icon: "tag",
                        title: viewModel.displayLabel,
                        field: .label
                    )
                }
                
                if viewModel.countdownViewModel != nil {
                    expandablePillButton(
                        icon: "timer",
                        title: viewModel.displayCountdown,
                        field: .countdown
                    )
                }
                
                if viewModel.soundViewModel != nil {
                    expandablePillButton(
                        icon: "speaker.wave.2",
                        title: viewModel.displaySound,
                        field: .sound
                    )
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TickerSpacing.md)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.hasAnyActiveOptions)
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

}

