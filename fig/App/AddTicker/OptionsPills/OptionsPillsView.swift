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
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            Text("OPTIONS")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                .padding(.horizontal, TickerSpacing.md)

            FlowLayout(spacing: TickerSpacing.xs) {
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
                    icon: "note.text",
                    title: viewModel.displayNotes,
                    field: .notes
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
                    viewModel.enableSnooze.toggle()
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
                hasValue: viewModel.hasValue(for: field)
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
                hasValue: false
            )
        }
    }

    private func pillButtonContent(
        icon: String,
        title: String,
        isActive: Bool,
        hasValue: Bool
    ) -> some View {
        let iconColor = title == "Icon" ? (Color(hex: selectedColorHex) ?? TickerColors.primary) : nil

        return HStack(spacing: TickerSpacing.xxs) {
            ZStack {
                // Icon background glow for active state
                if isActive {
                    Circle()
                        .fill(TickerColors.absoluteWhite.opacity(0.2))
                        .frame(width: 20, height: 20)
                        .blur(radius: 4)
                }

                Image(systemName: icon)
                    .font(.system(size: 14, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(iconColor ?? (isActive ? TickerColors.absoluteWhite : TickerColors.textPrimary(for: colorScheme)))
            }

            Text(title)
                .font(.system(size: 13, weight: isActive ? .semibold : .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? TickerColors.absoluteWhite : TickerColors.textPrimary(for: colorScheme))
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.sm)
        .background(
            ZStack {
                if isActive {
                    // Active gradient background
                    LinearGradient(
                        colors: [
                            TickerColors.primary,
                            TickerColors.primary.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    // Inactive glass background
                    TickerColors.surface(for: colorScheme)
                        .opacity(0.7)
                }
            }
        )
        .background(.ultraThinMaterial.opacity(isActive ? 0.5 : 0.3))
        .overlay(
            Capsule()
                .strokeBorder(
                    hasValue && !isActive ?
                    LinearGradient(
                        colors: [
                            TickerColors.primary.opacity(0.6),
                            TickerColors.primary.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                        LinearGradient(
                            colors: [Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    lineWidth: 1.5
                )
        )
        .clipShape(Capsule())
        .shadow(
            color: isActive ? TickerColors.primary.opacity(0.4) : Color.black.opacity(0.08),
            radius: isActive ? 8 : 4,
            x: 0,
            y: isActive ? 4 : 2
        )
    }
}
