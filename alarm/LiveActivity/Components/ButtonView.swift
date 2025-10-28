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
        Button(intent: intent) {
            HStack(spacing: TickerSpacing.xs) {
                Image(systemName: config.systemImageName)
                    .Subheadline()
//                
//                Text(config.text)
//                    .font(.system(size: 15, weight: .semibold))
//                    .lineLimit(1)
            }
            .foregroundStyle(TickerColor.absoluteWhite)
            .padding(TickerSpacing.md)
            .background(
                Capsule()
                    .fill(tint)
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(isPressed ? 0.3 : 0))
                            .animation(.easeInOut(duration: 0.1), value: isPressed)
                    )
                    .shadow(
                        color: tint.opacity(0.6),
                        radius: isPressed ? 6 : 12,
                        x: 0,
                        y: isPressed ? 3 : 6
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
