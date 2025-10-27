//
//  ButtonView.swift
//  alarm
//
//  Reusable button component for Live Activity
//  Supports app intents with customizable styling and haptic feedback
//

import AppIntents
import AlarmKit
import SwiftUI

/// Generic button view for Live Activity actions
struct ButtonView<I>: View where I: AppIntent {
    var config: AlarmButton
    var intent: I
    var tint: Color
    @State private var isPressed = false

    init?(config: AlarmButton?, intent: I, tint: Color) {
        guard let config else { return nil }
        self.config = config
        self.intent = intent
        self.tint = tint
    }

    var body: some View {
        Button {
            // Execute the intent
            Task {
                try? await intent.perform()
            }
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        } label: {
            HStack(spacing: TickerSpacing.xxs) {
                Image(systemName: config.systemImageName)
                    .font(.system(size: 14, weight: .semibold))

                Text(config.text)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(TickerColor.absoluteWhite)
            .padding(.horizontal, TickerSpacing.md)
            .padding(.vertical, TickerSpacing.sm)
            .background(
                Capsule()
                    .fill(tint)
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(isPressed ? 0.2 : 0))
                            .animation(.easeInOut(duration: 0.1), value: isPressed)
                    )
                    .shadow(
                        color: tint.opacity(0.4),
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
