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
            HStack(spacing: 6) {
                Image(systemName: config.systemImageName)
                    .font(.system(size: 14, weight: .semibold))

                Text(config.text)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(tint)
                    .shadow(color: tint.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}
