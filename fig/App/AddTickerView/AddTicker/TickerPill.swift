//
//  TickerPill.swift
//  Ticker
//
//  Pill-shaped interactive button component with Liquid Glass effects
//  Used for options, tags, and toggleable selections
//

import SwiftUI

// MARK: - Pill Size

enum TickerPillSize {
    case compact
    case standard
    case large

    var height: CGFloat {
        switch self {
        case .compact: return 32
        case .standard: return 40
        case .large: return 48
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return TickerSpacing.sm
        case .standard: return TickerSpacing.md
        case .large: return TickerSpacing.lg
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .compact: return 14
        case .standard: return 16
        case .large: return 18
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact: return TickerSpacing.xxs
        case .standard: return TickerSpacing.xs
        case .large: return TickerSpacing.sm
        }
    }
}

// MARK: - TickerPill View

struct TickerPill: View {
    let icon: String
    let title: String
    let isActive: Bool
    let hasValue: Bool
    let size: TickerPillSize
    let iconTintColor: Color?

    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        title: String,
        isActive: Bool = false,
        hasValue: Bool = false,
        size: TickerPillSize = .standard,
        iconTintColor: Color? = nil
    ) {
        self.icon = icon
        self.title = title
        self.isActive = isActive
        self.hasValue = hasValue
        self.size = size
        self.iconTintColor = iconTintColor
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .semibold, design: .rounded))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, size.horizontalPadding)
        .frame(height: size.height)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(borderColor, lineWidth: borderWidth)
        )
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: 0,
            y: shadowOffset
        )
        .contentShape(Capsule())
    }

    // MARK: - Computed Properties

    private var fontSize: CGFloat {
        switch size {
        case .compact: return 13
        case .standard: return 15
        case .large: return 17
        }
    }

    private var iconColor: Color {
        if let tintColor = iconTintColor {
            return tintColor
        }

        if isActive {
            return TickerColor.primary
        }

        if hasValue {
            return TickerColor.accent
        }

        return TickerColor.textSecondary(for: colorScheme)
    }

    private var textColor: Color {
        if isActive {
            return TickerColor.textPrimary(for: colorScheme)
        }

        if hasValue {
            return TickerColor.textPrimary(for: colorScheme)
        }

        return TickerColor.textSecondary(for: colorScheme)
    }

    private var backgroundColor: Color {
        if isActive {
            return TickerColor.primary.opacity(0.12)
        }

        if hasValue {
            return TickerColor.surface(for: colorScheme)
        }

        return TickerColor.surface(for: colorScheme).opacity(0.6)
    }

    private var borderColor: Color {
        if isActive {
            return TickerColor.primary.opacity(0.5)
        }

        if hasValue {
            return TickerColor.accent.opacity(0.3)
        }

        return TickerColor.textTertiary(for: colorScheme).opacity(0.2)
    }

    private var borderWidth: CGFloat {
        isActive ? 2 : 1
    }
    
    private var shadowColor: Color {
        if isActive {
            return TickerColor.primary.opacity(0.3)
        }
        
        if hasValue {
            return TickerColor.accent.opacity(0.2)
        }
        
        return Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1)
    }
    
    private var shadowRadius: CGFloat {
        if isActive {
            return 8
        }
        
        if hasValue {
            return 4
        }
        
        return 2
    }
    
    private var shadowOffset: CGFloat {
        if isActive {
            return 2
        }
        
        if hasValue {
            return 1
        }
        
        return 0.5
    }
}

// MARK: - Preview

#Preview("TickerPill States") {
    VStack(spacing: TickerSpacing.xl) {
        // Standard Size
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text("STANDARD SIZE")
                .Title2()

            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Text("Default State")
                    .Caption()
                    .foregroundStyle(.secondary)
                TickerPill(
                    icon: "calendar",
                    title: "Select Date",
                    size: .standard
                )

                Text("Has Value")
                    .Caption()
                    .foregroundStyle(.secondary)
                TickerPill(
                    icon: "calendar",
                    title: "Today",
                    hasValue: true,
                    size: .standard
                )

                Text("Active State")
                    .Caption()
                    .foregroundStyle(.secondary)
                TickerPill(
                    icon: "calendar",
                    title: "Tomorrow",
                    isActive: true,
                    hasValue: true,
                    size: .standard
                )
            }
        }

        // All Sizes
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text("SIZES")
                .Title2()

            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                TickerPill(
                    icon: "tag",
                    title: "Compact",
                    hasValue: true,
                    size: .compact
                )

                TickerPill(
                    icon: "tag",
                    title: "Standard",
                    hasValue: true,
                    size: .standard
                )

                TickerPill(
                    icon: "tag",
                    title: "Large",
                    hasValue: true,
                    size: .large
                )
            }
        }

        // Custom Tint
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text("CUSTOM ICON TINT")
                .Title2()

            HStack(spacing: TickerSpacing.sm) {
                TickerPill(
                    icon: "alarm.fill",
                    title: "Alarm",
                    hasValue: true,
                    size: .standard,
                    iconTintColor: TickerColor.scheduled
                )

                TickerPill(
                    icon: "figure.run",
                    title: "Running",
                    hasValue: true,
                    size: .standard,
                    iconTintColor: TickerColor.running
                )

                TickerPill(
                    icon: "bell.badge.fill",
                    title: "Alert",
                    hasValue: true,
                    size: .standard,
                    iconTintColor: TickerColor.alerting
                )
            }
        }

        Spacer()
    }
    .padding(TickerSpacing.md)
}

#Preview("TickerPill States - Dark") {
    VStack(spacing: TickerSpacing.xl) {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            TickerPill(
                icon: "calendar",
                title: "Select Date",
                size: .standard
            )

            TickerPill(
                icon: "calendar",
                title: "Today",
                hasValue: true,
                size: .standard
            )

            TickerPill(
                icon: "calendar",
                title: "Tomorrow",
                isActive: true,
                hasValue: true,
                size: .standard
            )
        }

        Spacer()
    }
    .padding(TickerSpacing.md)
    .preferredColorScheme(.dark)
}
