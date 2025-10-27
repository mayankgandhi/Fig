//
//  ButtonView.swift
//  alarm
//
//  Reusable button component for Live Activity
//  Supports app intents with customizable styling
//

import AppIntents
import AlarmKit
import SwiftUI

/// Generic button view for Live Activity actions
struct ButtonView<I>: View where I: AppIntent {
    var config: AlarmButton
    var intent: I
    var tint: Color

    init?(config: AlarmButton?, intent: I, tint: Color) {
        guard let config else { return nil }
        self.config = config
        self.intent = intent
        self.tint = tint
    }

    var body: some View {
        Button(intent: intent) {
            HStack(spacing: TickerSpacing.xxs) {
                Image(systemName: config.systemImageName)
                    .ButtonText()

                Text(config.text)
                    .SmallText()
                    .lineLimit(1)
            }
            .foregroundStyle(TickerColor.absoluteWhite)
            .padding(.horizontal, TickerSpacing.md)
            .padding(.vertical, TickerSpacing.xs)
            .background(
                Capsule()
                    .fill(tint)
                    .shadow(
                        color: TickerShadow.elevated.color,
                        radius: TickerShadow.elevated.radius,
                        x: TickerShadow.elevated.x,
                        y: TickerShadow.elevated.y
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(TickerAnimation.quick, value: false)
    }
}
