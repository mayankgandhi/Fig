//
//  TickerDesignSystem.swift
//  Ticker
//
//  Mission-critical design system for urgent, reliable alarm management
//

import SwiftUI

// MARK: - Color System

enum TickerColor {

    // MARK: Base Colors

    /// Pure black for dark mode backgrounds and text on light
    static let absoluteBlack = Color(red: 0.0, green: 0.0, blue: 0.0)

    /// Pure white for light mode backgrounds and text on dark
    static let absoluteWhite = Color(red: 1.0, green: 1.0, blue: 1.0)

    /// Elevated surface dark mode - subtle elevation
    static let surfaceDark = Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E

    /// Elevated surface light mode - soft background
    static let surfaceLight = Color(red: 0.96, green: 0.96, blue: 0.97) // #F5F5F7

    // MARK: Primary Brand Colors

    /// Primary action color - vibrant orange
    static let primary = Color(red: 0.976, green: 0.451, blue: 0.188) // #F97330

    /// Primary hover/pressed state - deeper orange
    static let primaryDark = Color(red: 0.914, green: 0.337, blue: 0.106) // #E9561B

    /// Accent color - golden amber
    static let accent = Color(red: 0.976, green: 0.616, blue: 0.169) // #F99D2B

    // MARK: Semantic Actions

    /// Success state - vibrant lime
    static let success = Color(red: 0.518, green: 0.800, blue: 0.086) // #84CC16

    /// Warning state - bright amber
    static let warning = Color(red: 0.965, green: 0.620, blue: 0.043) // #F59E0B

    /// Danger/destructive - hot pink (less aggressive than red)
    static let danger = Color(red: 0.925, green: 0.247, blue: 0.600) // #EC4899

    // MARK: Alarm States

    /// Scheduled - warm coral
    static let scheduled = Color(red: 0.976, green: 0.537, blue: 0.278) // #F98947

    /// Running - electric lime
    static let running = Color(red: 0.518, green: 0.800, blue: 0.086) // #84CC16

    /// Paused - warm orange
    static let paused = Color(red: 0.984, green: 0.573, blue: 0.235) // #FB923C

    /// Alerting - bright fuchsia
    static let alerting = Color(red: 0.851, green: 0.275, blue: 0.937) // #D946EF

    /// Disabled state - neutral gray
    static let disabled = Color(red: 0.584, green: 0.584, blue: 0.596) // #959598

    // MARK: Text Hierarchy

    /// Primary text - maximum contrast
    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? absoluteWhite : absoluteBlack
    }

    /// Secondary text - 70% opacity for hierarchy
    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.7)
            : Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.7)
    }

    /// Tertiary text - 50% opacity for subtle info
    static func textTertiary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.5)
            : Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.5)
    }

    // MARK: Background System

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? absoluteBlack : absoluteWhite
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? surfaceDark : surfaceLight
    }

    // MARK: Liquid Glass Background Gradient

    static func liquidGlassGradient(for colorScheme: ColorScheme) -> some View {
        if colorScheme == .dark {
            return ZStack {
                // Base gradient - Soft neutral dark with subtle warm undertones
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.04, blue: 0.04),  // Soft charcoal
                        Color(red: 0.05, green: 0.05, blue: 0.05),  // Neutral dark gray
                        Color(red: 0.06, green: 0.06, blue: 0.05),  // Barely warm gray
                        Color(red: 0.05, green: 0.04, blue: 0.04),  // Subtle warm undertone
                        Color(red: 0.04, green: 0.04, blue: 0.04)   // Return to neutral
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Mid-layer gradient - Very subtle diagonal accent
                LinearGradient(
                    colors: [
                        Color.clear,
                        primary.opacity(0.04),
                        Color.clear,
                        accent.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )

                // Radial depth overlay - Gentle center glow
                RadialGradient(
                    colors: [
                        primary.opacity(0.02),
                        Color.clear,
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 400
                )

                // Top shimmer - Delicate light reflection
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.03),
                        Color.white.opacity(0.01),
                        Color.clear,
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )

                // Bottom glow - Barely-there depth
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        primary.opacity(0.03),
                        primaryDark.opacity(0.02)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        } else {
            return ZStack {
                // Base gradient - Soft warm whites with peachy/amber tints
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.96, blue: 0.93),  // Warm cream
                        Color(red: 0.99, green: 0.95, blue: 0.91),  // Soft peach-white
                        Color(red: 0.99, green: 0.97, blue: 0.94),  // Ivory glow
                        Color(red: 0.98, green: 0.96, blue: 0.93),  // Champagne-white
                        Color(red: 0.99, green: 0.96, blue: 0.92)   // Vanilla-white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Mid-layer gradient - Diagonal warm wash
                LinearGradient(
                    colors: [
                        Color.clear,
                        primary.opacity(0.06),
                        Color.clear,
                        accent.opacity(0.04),
                        Color.clear
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )

                // Radial depth overlay - Subtle center highlight
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.4),
                        Color.clear,
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )

                // Top luminance - Bright edge
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.1),
                        Color.clear,
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )

                // Bottom color tint - Subtle warm depth
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        primary.opacity(0.04),
                        accent.opacity(0.03)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - Spacing System

enum TickerSpacing {

    /// 4pt - Micro spacing
    static let xxs: CGFloat = 4

    /// 8pt - Tiny spacing
    static let xs: CGFloat = 8

    /// 12pt - Small spacing
    static let sm: CGFloat = 12

    /// 16pt - Base spacing unit
    static let md: CGFloat = 16

    /// 24pt - Medium-large spacing
    static let lg: CGFloat = 24

    /// 32pt - Large spacing
    static let xl: CGFloat = 32

    /// 48pt - Extra large spacing
    static let xxl: CGFloat = 48

    /// 64pt - Section breaks
    static let xxxl: CGFloat = 64

    // MARK: Component Spacing

    /// Minimum tap target size (44x44)
    static let tapTargetMin: CGFloat = 44

    /// Preferred tap target for critical actions (56x56)
    static let tapTargetPreferred: CGFloat = 56

    /// Large action button height (64pt)
    static let buttonHeightLarge: CGFloat = 64

    /// Standard button height (48pt)
    static let buttonHeightStandard: CGFloat = 48
}

// MARK: - Corner Radius System

enum TickerRadius {

    /// 0pt - Sharp corners for urgency
    static let none: CGFloat = 0

    /// 4pt - Tight radius
    static let tight: CGFloat = 4

    /// 8pt - Small radius
    static let small: CGFloat = 8

    /// 12pt - Medium radius
    static let medium: CGFloat = 12

    /// 16pt - Large radius
    static let large: CGFloat = 16

    /// 24pt - Extra large radius
    static let xlarge: CGFloat = 24

    /// Full circle
    static let full: CGFloat = 999
}

// MARK: - Shadow System

enum TickerShadow {

    /// Sharp, high-contrast shadow for critical elements
    static let critical = (
        color: Color.black.opacity(0.3),
        radius: CGFloat(8),
        x: CGFloat(0),
        y: CGFloat(4)
    )

    /// Elevated surface shadow
    static let elevated = (
        color: Color.black.opacity(0.15),
        radius: CGFloat(12),
        x: CGFloat(0),
        y: CGFloat(6)
    )

    /// Subtle depth
    static let subtle = (
        color: Color.black.opacity(0.08),
        radius: CGFloat(4),
        x: CGFloat(0),
        y: CGFloat(2)
    )
}

// MARK: - Animation System

enum TickerAnimation {

    /// Instant feedback (0.1s) - for critical actions
    static let instant = Animation.easeOut(duration: 0.1)

    /// Quick response (0.2s) - for UI feedback
    static let quick = Animation.easeInOut(duration: 0.2)

    /// Standard (0.3s) - for transitions
    static let standard = Animation.easeInOut(duration: 0.3)

    /// Urgent pulse - for active alarms
    static let pulse = Animation
        .easeInOut(duration: 1.0)
        .repeatForever(autoreverses: true)

    /// Spring - for tactile feedback
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

// MARK: - Button Styles

struct TickerPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    let isDestructive: Bool

    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .Subheadline()
            .foregroundStyle(TickerColor.absoluteWhite)
            .frame(maxWidth: .infinity)
            .frame(height: TickerSpacing.buttonHeightLarge)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
            .shadow(
                color: TickerShadow.critical.color,
                radius: TickerShadow.critical.radius,
                x: TickerShadow.critical.x,
                y: TickerShadow.critical.y
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(TickerAnimation.quick, value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        if !isEnabled {
            return TickerColor.disabled
        }
        return isDestructive ? TickerColor.danger : TickerColor.primary
    }
}

struct TickerSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .Subheadline()
            .foregroundStyle(isEnabled ? TickerColor.textPrimary(for: colorScheme) : TickerColor.disabled)
            .frame(maxWidth: .infinity)
            .frame(height: TickerSpacing.buttonHeightStandard)
            .background(TickerColor.surface(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .strokeBorder(
                        isEnabled ? TickerColor.textTertiary(for: colorScheme) : TickerColor.disabled,
                        lineWidth: 2
                    )
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(TickerAnimation.quick, value: configuration.isPressed)
    }
}

struct TickerTertiaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .Subheadline()
            .foregroundStyle(isEnabled ? TickerColor.textPrimary(for: colorScheme) : TickerColor.disabled)
            .padding(.horizontal, TickerSpacing.md)
            .padding(.vertical, TickerSpacing.sm)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(TickerAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - View Modifiers

struct TickerStatusBadge: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .Caption()
            .textCase(.uppercase)
            .foregroundStyle(TickerColor.absoluteWhite)
            .padding(.horizontal, TickerSpacing.sm)
            .padding(.vertical, TickerSpacing.xxs)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.tight))
    }
}

struct TickerCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(TickerColor.surface(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.large))
            .shadow(
                color: TickerShadow.subtle.color,
                radius: TickerShadow.subtle.radius,
                x: TickerShadow.subtle.x,
                y: TickerShadow.subtle.y
            )
    }
}

// MARK: - View Extensions

extension View {

    /// Apply status badge style
    func tickerStatusBadge(color: Color) -> some View {
        modifier(TickerStatusBadge(color: color))
    }

    /// Apply card style
    func tickerCard() -> some View {
        modifier(TickerCard())
    }
}

// MARK: - Button Extensions

extension Button {

    /// Apply primary button style with optional destructive variant
    func tickerPrimaryButton(isDestructive: Bool = false) -> some View {
        self.buttonStyle(TickerPrimaryButtonStyle(isDestructive: isDestructive))
    }

    /// Apply secondary button style
    func tickerSecondaryButton() -> some View {
        self.buttonStyle(TickerSecondaryButtonStyle())
    }

    /// Apply tertiary button style (text-only button)
    func tickerTertiaryButton() -> some View {
        self.buttonStyle(TickerTertiaryButtonStyle())
    }
}

// MARK: - Icon System

enum TickerIcons {

    // MARK: Alarm States
    static let alarmScheduled = "alarm"
    static let alarmRunning = "alarm.fill"
    static let alarmPaused = "pause.circle.fill"
    static let alarmAlerting = "bell.badge.fill"

    // MARK: Actions
    static let add = "plus.circle.fill"
    static let delete = "trash.fill"
    static let edit = "pencil"
    static let settings = "gearshape.fill"
    static let close = "xmark"
    static let checkmark = "checkmark"

    // MARK: Time/Schedule
    static let calendar = "calendar"
    static let clock = "clock.fill"
    static let timer = "timer"
    static let `repeat` = "repeat"

    // MARK: Status Indicators
    static let warning = "exclamationmark.triangle.fill"
    static let error = "xmark.circle.fill"
    static let success = "checkmark.circle.fill"
    static let info = "info.circle.fill"
}

// MARK: - Haptic Feedback

enum TickerHaptics {

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: Contextual Haptics

    /// Heavy impact for critical actions (setting alarm)
    static func criticalAction() {
        impact(.heavy)
    }

    /// Medium impact for standard interactions
    static func standardAction() {
        impact(.medium)
    }

    /// Success haptic for alarm confirmation
    static func success() {
        notification(.success)
    }

    /// Warning haptic for alarm about to trigger
    static func warning() {
        notification(.warning)
    }

    /// Error haptic for failed actions
    static func error() {
        notification(.error)
    }
}
