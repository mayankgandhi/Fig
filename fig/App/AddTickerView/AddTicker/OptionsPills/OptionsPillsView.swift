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
                    .font(.system(size: 11, weight: .bold, design: .rounded))
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

            // Enhanced pill layout with better spacing
            FlowLayout(spacing: TickerSpacing.sm) {
                expandablePillButton(
                    icon: "calendar",
                    title: viewModel.displayDate,
                    field: .calendar
                )

                expandablePillButton(
                    icon: "repeat",
                    title: viewModel.displayRepeat,
                    field: .repeat
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

                expandablePillButton(
                    icon: selectedIcon,
                    title: "Icon",
                    field: .icon
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
        field: ExpandableField
    ) -> some View {
        Button {
            TickerHaptics.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                viewModel.toggleField(field)
            }
        } label: {
            pillButtonContent(
                icon: icon,
                title: title,
                isActive: viewModel.expandedField == field,
                hasValue: viewModel.hasValue(for: field),
                field: field
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
            pillButtonContent(
                icon: icon,
                title: title,
                isActive: isActive,
                hasValue: false,
                field: nil
            )
        }
    }

    private func pillButtonContent(
        icon: String,
        title: String,
        isActive: Bool,
        hasValue: Bool,
        field: ExpandableField?
    ) -> some View {
        let isIconField = title == "Icon"
        let iconColor = isIconField ? (Color(hex: selectedColorHex) ?? TickerColor.primary) : nil

        return HStack(spacing: TickerSpacing.xs) {
            ZStack {
                if isIconField {
                    // Icon field: Enhanced colored circle background
                    Circle()
                        .fill(iconColor ?? TickerColor.primary)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    TickerColor.absoluteWhite.opacity(0.2),
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TickerColor.absoluteWhite)
                } else {
                    // Other fields: Enhanced icon with better states
                    ZStack {
                        // Subtle background for better contrast
                        if isActive {
                            Circle()
                                .fill(TickerColor.absoluteWhite.opacity(0.15))
                                .frame(width: 24, height: 24)
                        } else if hasValue {
                            Circle()
                                .fill(TickerColor.primary.opacity(0.1))
                                .frame(width: 22, height: 22)
                        }

                        Image(systemName: icon)
                            .font(.system(size: 15, weight: isActive ? .bold : .semibold))
                            .foregroundStyle(
                                isActive ? TickerColor.absoluteWhite : 
                                hasValue ? TickerColor.primary : 
                                TickerColor.textPrimary(for: colorScheme)
                            )
                    }
                }
            }

            Text(title)
                .font(.system(size: 14, weight: isActive ? .bold : .semibold, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(
                    isActive ? TickerColor.absoluteWhite : 
                    hasValue ? TickerColor.textPrimary(for: colorScheme) : 
                    TickerColor.textSecondary(for: colorScheme)
                )
        }
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.md)
        .background(
            ZStack {
                if isActive {
                    // Enhanced active gradient background
                    LinearGradient(
                        colors: [
                            TickerColor.primary,
                            TickerColor.primary.opacity(0.95),
                            TickerColor.primary.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else if hasValue {
                    // Value state with subtle primary tint
                    LinearGradient(
                        colors: [
                            TickerColor.surface(for: colorScheme),
                            TickerColor.surface(for: colorScheme).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    // Default inactive state
                    TickerColor.surface(for: colorScheme)
                        .opacity(0.6)
                }
            }
        )
        .background(.ultraThinMaterial.opacity(isActive ? 0.6 : hasValue ? 0.4 : 0.2))
        .overlay(
            Capsule()
                .strokeBorder(
                    hasValue && !isActive ?
                    LinearGradient(
                        colors: [
                            TickerColor.primary.opacity(0.7),
                            TickerColor.primary.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                        LinearGradient(
                            colors: [Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    lineWidth: hasValue ? 1.5 : 0
                )
        )
        .clipShape(Capsule())
        .shadow(
            color: isActive ? TickerColor.primary.opacity(0.5) : 
                   hasValue ? TickerColor.primary.opacity(0.15) : 
                   Color.black.opacity(0.06),
            radius: isActive ? 10 : hasValue ? 6 : 3,
            x: 0,
            y: isActive ? 5 : hasValue ? 3 : 1
        )
        .scaleEffect(isActive ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasValue)
    }
}

