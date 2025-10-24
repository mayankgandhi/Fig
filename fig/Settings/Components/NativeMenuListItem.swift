//
//  NativeMenuListItem.swift
//  fig
//
//  Apple-native menu list item component
//

import SwiftUI

struct NativeMenuListItem: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            TickerHaptics.selection()
            action()
        }) {
            HStack(spacing: TickerSpacing.md) {
                // Enhanced icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    iconColor,
                                    iconColor.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(
                            color: iconColor.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )

                    Image(systemName: icon)
                        .TickerTitle()
                        .foregroundStyle(.white)
                }

                // Title and subtitle with improved typography
                VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                    Text(title)
                        .Headline()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .ButtonText()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                // Enhanced chevron with subtle animation
                Image(systemName: "chevron.right")
                    .ButtonText()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(TickerAnimation.quick, value: isPressed)
            }
            .padding(.horizontal, TickerSpacing.md)
            .padding(.vertical, TickerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .fill(TickerColor.surface(for: colorScheme))
                    .shadow(
                        color: TickerShadow.subtle.color,
                        radius: TickerShadow.subtle.radius,
                        x: TickerShadow.subtle.x,
                        y: TickerShadow.subtle.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .strokeBorder(
                        TickerColor.textTertiary(for: colorScheme).opacity(0.2),
                        lineWidth: 0.5
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(TickerAnimation.quick, value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    VStack(spacing: TickerSpacing.xs) {
        NativeMenuListItem(
            icon: "info.circle",
            title: "About",
            subtitle: "App version and information",
            iconColor: TickerColor.primary
        ) {}

        NativeMenuListItem(
            icon: "questionmark.circle",
            title: "FAQ",
            subtitle: "Frequently asked questions",
            iconColor: TickerColor.accent
        ) {}

        NativeMenuListItem(
            icon: "envelope",
            title: "Help & Support",
            subtitle: "Get help or send feedback",
            iconColor: TickerColor.success
        ) {}

        NativeMenuListItem(
            icon: "trash",
            title: "Delete All Data",
            subtitle: "Clear all scheduled alarms",
            iconColor: TickerColor.danger
        ) {}
    }
    .padding(TickerSpacing.md)
    .background(
        ZStack {
            TickerColor.liquidGlassGradient(for: .light)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    )
}

#Preview("Dark Mode") {
    VStack(spacing: TickerSpacing.xs) {
        NativeMenuListItem(
            icon: "info.circle",
            title: "About",
            subtitle: "App version and information",
            iconColor: TickerColor.primary
        ) {}

        NativeMenuListItem(
            icon: "questionmark.circle",
            title: "FAQ",
            subtitle: "Frequently asked questions",
            iconColor: TickerColor.accent
        ) {}

        NativeMenuListItem(
            icon: "envelope",
            title: "Help & Support",
            subtitle: "Get help or send feedback",
            iconColor: TickerColor.success
        ) {}

        NativeMenuListItem(
            icon: "trash",
            title: "Delete All Data",
            subtitle: "Clear all scheduled alarms",
            iconColor: TickerColor.danger
        ) {}
    }
    .padding(TickerSpacing.md)
    .background(
        ZStack {
            TickerColor.liquidGlassGradient(for: .dark)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    )
    .preferredColorScheme(.dark)
}
