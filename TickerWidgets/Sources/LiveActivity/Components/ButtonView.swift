//
//  ButtonView.swift
//  alarm
//
//  Reusable button component for Live Activity
//

import AppIntents
import AlarmKit
import SwiftUI
import TickerCore

/// Generic button view for Live Activity actions.
struct ButtonView<I>: View where I: AppIntent {

    var config: AlarmButton
    var intent: I
    var tint: Color
    /// Alert-state controls are sized for someone acting half-asleep with their
    /// eyes barely open, not for an attentive user.
    var prominent: Bool = false

    init?(config: AlarmButton?, intent: I, tint: Color, prominent: Bool = false) {
        guard let config else { return nil }
        self.config = config
        self.intent = intent
        self.tint = tint
        self.prominent = prominent
    }

    private var side: CGFloat {
        prominent ? TickerSpacing.tapTargetPreferred : TickerSpacing.tapTargetMin
    }

    var body: some View {
        Button(intent: intent) {
            Image(systemName: config.systemImageName)
                .font(.system(size: prominent ? 22 : 16, weight: .semibold))
                .foregroundStyle(TickerColor.absoluteWhite)
                .frame(minWidth: side, minHeight: side)
                .background(Capsule().fill(tint))
        }
        .buttonStyle(.plain)
        // `config.text` was carried all the way here and then thrown away, so
        // VoiceOver announced the raw SF Symbol name ("stop.fill") instead of
        // "Stop". Widgets cannot run gesture-based press feedback either — only
        // `Button(intent:)` is interactive — so the old `@State isPressed` plus
        // `onLongPressGesture` was dead code driving a scale effect that never
        // fired.
        .accessibilityLabel(Text(config.text))
        .accessibilityAddTraits(.isButton)
    }
}
