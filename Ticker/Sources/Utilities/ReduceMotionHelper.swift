//
//  ReduceMotionHelper.swift
//  Ticker
//
//  Utilities for supporting reduce motion accessibility setting.
//  Provides helpers to conditionally apply animations based on user preference.
//

import SwiftUI

// MARK: - Reduce Motion Environment Helper

/// Extension to check if accessibility reduce motion is enabled
extension View {
    /// Conditionally applies an animation based on reduce motion setting
    /// - Parameter animation: The animation to apply when reduce motion is disabled
    /// - Returns: View with conditional animation
    func reduceMotionAnimation(_ animation: Animation?) -> some View {
        self.modifier(ReduceMotionAnimationModifier(animation: animation))
    }

    /// Conditionally applies an animation with a value binding
    /// - Parameters:
    ///   - animation: The animation to apply when reduce motion is disabled
    ///   - value: The value to observe for animation triggers
    /// - Returns: View with conditional animation
    func reduceMotionAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.modifier(ReduceMotionAnimationValueModifier(animation: animation, value: value))
    }
}

// MARK: - View Modifiers

/// ViewModifier that conditionally applies animation based on reduce motion setting
private struct ReduceMotionAnimationModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: UUID())
        }
    }
}

/// ViewModifier that conditionally applies animation with value binding
private struct ReduceMotionAnimationValueModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}

// MARK: - Transition Helpers

extension AnyTransition {
    /// Provides a reduce motion-aware transition
    /// - Parameters:
    ///   - standard: Transition to use when reduce motion is disabled
    ///   - reduced: Simpler transition to use when reduce motion is enabled
    /// - Returns: Conditional transition
    static func reduceMotion(
        standard: AnyTransition,
        reduced: AnyTransition = .opacity
    ) -> AnyTransition {
        // Note: AnyTransition doesn't have access to environment
        // This returns the standard transition
        // Consider using conditional logic in views instead
        standard
    }
}
