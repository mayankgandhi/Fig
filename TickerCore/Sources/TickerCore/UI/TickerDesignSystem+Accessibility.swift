//
//  TickerDesignSystem+Accessibility.swift
//  TickerCore
//
//  Accessibility extensions for the Ticker design system.
//  Provides reusable accessibility modifiers for consistent implementation.
//

import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    /// Applies standardized accessibility label and optional hint to a button
    /// - Parameters:
    ///   - label: The accessibility label describing what the button does
    ///   - hint: Optional hint providing additional context about the action
    ///   - traits: Additional accessibility traits (e.g., .isButton, .isSelected)
    /// - Returns: View with accessibility modifiers applied
    func accessibleButton(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(traits)
    }

    /// Applies accessibility label to an icon with SF Symbol
    /// - Parameters:
    ///   - systemName: The SF Symbol name
    ///   - label: The accessible description of the icon
    /// - Returns: View with accessibility label applied
    func accessibleIcon(
        _ systemName: String,
        label: String
    ) -> some View {
        self.accessibilityLabel(label)
    }

    /// Groups related elements with a combined accessibility label and value
    /// - Parameters:
    ///   - label: The main description of the grouped content
    ///   - value: Optional current value or state
    ///   - hint: Optional hint for user interaction
    /// - Returns: View with grouped accessibility
    func accessibleGroup(
        label: String,
        value: String? = nil,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
    }

    /// Applies adaptive animation that respects reduce motion setting
    /// - Parameter animation: The animation to apply when reduce motion is disabled
    /// - Returns: View with conditional animation
    func adaptiveAnimation(_ animation: Animation) -> some View {
        self.modifier(AdaptiveAnimationModifier(animation: animation))
    }

    /// Applies adaptive animation with a value binding
    /// - Parameters:
    ///   - animation: The animation to apply when reduce motion is disabled
    ///   - value: The value to observe for animation triggers
    /// - Returns: View with conditional animation
    func adaptiveAnimation<V: Equatable>(
        _ animation: Animation,
        value: V
    ) -> some View {
        self.modifier(AdaptiveAnimationValueModifier(animation: animation, value: value))
    }
}

// MARK: - Adaptive Animation Modifier

/// ViewModifier that conditionally applies animation based on reduce motion setting
private struct AdaptiveAnimationModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: UUID())
        }
    }
}

/// ViewModifier that conditionally applies animation with value binding
private struct AdaptiveAnimationValueModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}

// MARK: - Layout Adaptation

extension View {
    /// Switches between compact and accessible layouts based on Dynamic Type size
    /// - Parameters:
    ///   - compact: Layout to use for standard size categories
    ///   - accessible: Layout to use for accessibility size categories
    /// - Returns: View with adaptive layout
    func adaptiveLayout(
        compact: AnyLayout,
        accessible: AnyLayout
    ) -> some View {
        self.modifier(AdaptiveLayoutModifier(compact: compact, accessible: accessible))
    }
}

/// ViewModifier that switches layout based on size category
private struct AdaptiveLayoutModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    let compact: AnyLayout
    let accessible: AnyLayout

    func body(content: Content) -> some View {
        let layout = sizeCategory.isAccessibilityCategory ? accessible : compact
        layout {
            content
        }
    }
}

// MARK: - Typography with Accessibility Scaling

extension View {
    /// Applies a text style that fully supports accessibility sizes
    /// - Parameter style: The text style to apply
    /// - Returns: View with scaled font
    func accessibilityScaled(_ style: Font.TextStyle) -> some View {
        self.font(.system(style, design: .default))
    }
}

// MARK: - Accessibility Trait Helpers

extension View {
    /// Adds button trait along with additional custom traits
    func accessibleButtonTraits(_ additional: AccessibilityTraits = []) -> some View {
        self
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(additional)
    }

    /// Adds header trait along with additional custom traits
    func accessibleHeaderTraits(_ additional: AccessibilityTraits = []) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityAddTraits(additional)
    }
}
