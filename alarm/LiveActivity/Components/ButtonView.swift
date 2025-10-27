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

// MARK: - Previews

#Preview("Button View - Pause Button") {
    ButtonView(
        config: AlarmButton(systemImageName: "pause.fill", text: "Pause"),
        intent: PauseIntent(alarmID: UUID().uuidString),
        tint: TickerColor.paused
    )
    .padding()
}

#Preview("Button View - Resume Button") {
    ButtonView(
        config: AlarmButton(systemImageName: "play.fill", text: "Resume"),
        intent: ResumeIntent(alarmID: UUID().uuidString),
        tint: TickerColor.running
    )
    .padding()
}

#Preview("Button View - Stop Button") {
    ButtonView(
        config: AlarmButton(systemImageName: "stop.fill", text: "Stop"),
        intent: StopIntent(alarmID: UUID().uuidString),
        tint: TickerColor.danger
    )
    .padding()
}
