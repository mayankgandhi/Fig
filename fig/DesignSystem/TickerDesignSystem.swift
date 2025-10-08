//
//  TickerDesignSystem.swift
//  Ticker
//
//  Mission-critical design system for urgent, reliable alarm management
//

import SwiftUI

// MARK: - Color System

enum TickerColors {

    // MARK: Base Colors (High Contrast)

    /// Pure black for dark mode backgrounds and text on light
    static let absoluteBlack = Color(red: 0.0, green: 0.0, blue: 0.0)

    /// Pure white for light mode backgrounds and text on dark
    static let absoluteWhite = Color(red: 1.0, green: 1.0, blue: 1.0)

    /// Deep charcoal for elevated surfaces in dark mode
    static let surfaceDark = Color(red: 0.08, green: 0.08, blue: 0.08)

    /// Bright off-white for elevated surfaces in light mode
    static let surfaceLight = Color(red: 0.98, green: 0.98, blue: 0.98)

    // MARK: Critical Accent (Electric Red)

    /// Primary action color - electric red for maximum urgency
    static let criticalRed = Color(red: 1.0, green: 0.17, blue: 0.33) // #FF2B55

    /// Active state - pulsing alarm indicator
    static let alertActive = Color(red: 1.0, green: 0.27, blue: 0.0) // #FF4500

    /// Danger/destructive actions
    static let danger = Color(red: 0.92, green: 0.0, blue: 0.0) // #EB0000

    // MARK: Semantic States

    /// Scheduled state - cool blue for reliability
    static let scheduled = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF

    /// Running state - electric green for active countdowns
    static let running = Color(red: 0.2, green: 0.84, blue: 0.29) // #34D64A

    /// Paused state - amber warning
    static let paused = Color(red: 1.0, green: 0.6, blue: 0.0) // #FF9900

    /// Disabled state - neutral gray
    static let disabled = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93

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
}

// MARK: - Typography System

enum TickerTypography {

    // MARK: Time Display (Massive, Tabular)

    /// 72pt - Hero alarm time
    static let timeHero = Font.custom("CabinetGrotesk-Variable", size: 72)
        .weight(.black)
        .monospacedDigit()

    /// 56pt - Large alarm time in list
    static let timeLarge = Font.custom("CabinetGrotesk-Variable", size: 56)
        .weight(.bold)
        .monospacedDigit()

    /// 36pt - Medium time display
    static let timeMedium = Font.custom("CabinetGrotesk-Variable", size: 36)
        .weight(.semibold)
        .monospacedDigit()

    // MARK: Headers (Strong Geometric)

    /// 34pt - Screen titles
    static let headerXL = Font.custom("CabinetGrotesk-Variable", size: 34)
        .weight(.black)

    /// 28pt - Section headers
    static let headerLarge = Font.custom("CabinetGrotesk-Variable", size: 28)
        .weight(.heavy)

    /// 22pt - Subsection headers
    static let headerMedium = Font.custom("CabinetGrotesk-Variable", size: 22)
        .weight(.bold)

    /// 17pt - Small headers
    static let headerSmall = Font.custom("CabinetGrotesk-Variable", size: 17)
        .weight(.semibold)

    // MARK: Body Text (Legible)

    /// 17pt - Primary body
    static let bodyLarge = Font.custom("CabinetGrotesk-Variable", size: 17)
        .weight(.regular)

    /// 15pt - Secondary body
    static let bodyMedium = Font.custom("CabinetGrotesk-Variable", size: 15)
        .weight(.regular)

    /// 13pt - Small body
    static let bodySmall = Font.custom("CabinetGrotesk-Variable", size: 13)
        .weight(.regular)

    // MARK: Labels (Uppercase, Bold)

    /// 11pt - Status tags, badges
    static let labelBold = Font.custom("CabinetGrotesk-Variable", size: 11)
        .weight(.heavy)

    /// 10pt - Tiny labels
    static let labelSmall = Font.custom("CabinetGrotesk-Variable", size: 10)
        .weight(.semibold)

    // MARK: Buttons

    /// 20pt - Primary action buttons
    static let buttonPrimary = Font.custom("CabinetGrotesk-Variable", size: 20)
        .weight(.bold)

    /// 17pt - Secondary buttons
    static let buttonSecondary = Font.custom("CabinetGrotesk-Variable", size: 17)
        .weight(.semibold)
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

// MARK: - View Modifiers

struct TickerPrimaryButton: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let isDestructive: Bool

    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }

    func body(content: Content) -> some View {
        content
            .font(TickerTypography.buttonPrimary)
            .foregroundStyle(TickerColors.absoluteWhite)
            .frame(maxWidth: .infinity)
            .frame(height: TickerSpacing.buttonHeightLarge)
            .background(isDestructive ? TickerColors.danger : TickerColors.criticalRed)
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
            .shadow(
                color: TickerShadow.critical.color,
                radius: TickerShadow.critical.radius,
                x: TickerShadow.critical.x,
                y: TickerShadow.critical.y
            )
    }
}

struct TickerSecondaryButton: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .font(TickerTypography.buttonSecondary)
            .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
            .frame(maxWidth: .infinity)
            .frame(height: TickerSpacing.buttonHeightStandard)
            .background(TickerColors.surface(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .strokeBorder(
                        TickerColors.textTertiary(for: colorScheme),
                        lineWidth: 2
                    )
            )
    }
}

struct TickerStatusBadge: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(TickerTypography.labelBold)
            .textCase(.uppercase)
            .foregroundStyle(TickerColors.absoluteWhite)
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
            .background(TickerColors.surface(for: colorScheme))
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

    /// Apply primary button style
    func tickerPrimaryButton(isDestructive: Bool = false) -> some View {
        modifier(TickerPrimaryButton(isDestructive: isDestructive))
    }

    /// Apply secondary button style
    func tickerSecondaryButton() -> some View {
        modifier(TickerSecondaryButton())
    }

    /// Apply status badge style
    func tickerStatusBadge(color: Color) -> some View {
        modifier(TickerStatusBadge(color: color))
    }

    /// Apply card style
    func tickerCard() -> some View {
        modifier(TickerCard())
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
