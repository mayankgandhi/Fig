//
//  AlarmLiveActivity.swift
//  alarm
//
//  Live Activity configuration for alarm countdown and alerts.
//
//  Every surface here previously returned `EmptyView()` for the `.alert` mode,
//  and also for any alarm without a countdown — which is every plain "wake me at
//  7am" alarm, because `AlarmConfigurationBuilder` builds an alert-only
//  presentation in that case. The result was a blank Dynamic Island and a blank
//  lock-screen banner at exactly the moment the product has to work.
//
//  Note on scope: AlarmKit draws its own full-screen system alert from
//  `AlarmPresentation.Alert`. What this file controls is the Dynamic Island and
//  the lock-screen / Home Screen banner — what the user sees when the alarm
//  fires while they are in another app, or after dismissing the system UI.
//

import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit
import TickerCore

struct AlarmLiveActivity: Widget {

    // MARK: - Derived values

    /// Brand tint for this alarm.
    ///
    /// The old idiom was `Color(hex: metadata?.colorHex ?? "#000000") ?? .primary`,
    /// which never fell back: `Color.init?(hex:)` parses "000000" successfully, so
    /// an alarm with no colour rendered a black dot and a black keyline on the
    /// always-black Dynamic Island.
    private func tint(_ attributes: AlarmAttributes<TickerData>) -> Color {
        attributes.metadata?.colorHex.flatMap(Color.init(hex:)) ?? TickerColor.primary
    }

    private func icon(_ attributes: AlarmAttributes<TickerData>) -> String {
        attributes.metadata?.icon ?? "bell.fill"
    }

    /// The alarm's own title. Sourced from `presentation.alert.title` (the
    /// ticker's label) rather than `metadata.name`, so the Live Activity and
    /// AlarmKit's system alert always say the same thing — the two fields are
    /// independently editable.
    private func title(_ attributes: AlarmAttributes<TickerData>) -> LocalizedStringResource {
        attributes.presentation.alert.title
    }

    private func isAlerting(_ mode: AlarmPresentationState.Mode) -> Bool {
        if case .alert = mode { return true }
        return false
    }

    /// Locale-aware wall-clock rendering of the alert time. `Mode.Alert.time` is
    /// a raw hour/minute pair, so 12h vs 24h and AM/PM placement have to come
    /// from the formatter, not from string interpolation.
    private func formatted(_ time: Alarm.Schedule.Relative.Time) -> String {
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        guard let date = Calendar.autoupdatingCurrent.date(from: components) else {
            return String(format: "%d:%02d", time.hour, time.minute)
        }
        return date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Configuration

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<TickerData>.self) { context in
            lockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(nil)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(attributes: context.attributes, state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(attributes: context.attributes, state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    AlarmControls(presentation: context.attributes.presentation, state: context.state)
                        .padding(.top, TickerSpacing.xs)
                }
            } compactLeading: {
                compactLeading(attributes: context.attributes, state: context.state)
            } compactTrailing: {
                compactTrailing(attributes: context.attributes, state: context.state)
            } minimal: {
                minimal(attributes: context.attributes, state: context.state)
            }
            .keylineTint(isAlerting(context.state.mode) ? TickerColor.alerting : tint(context.attributes))
        }
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private func lockScreenView(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // The lock screen banner has room to grow, so it uses the design
            // system's Dynamic Type styles rather than fixed point sizes. The
            // Dynamic Island surfaces below deliberately keep fixed sizes: those
            // regions have hard geometry and scaling text clips them.
            HStack(alignment: .firstTextBaseline, spacing: TickerSpacing.sm) {
                Image(systemName: icon(attributes))
                    .Headline()
                    .foregroundStyle(isAlerting(state.mode) ? TickerColor.alerting : tint(attributes))
                    .accessibilityHidden(true)

                Text(title(attributes))
                    .Headline()
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            HStack(alignment: .center, spacing: TickerSpacing.md) {
                primaryReadout(attributes: attributes, state: state)

                Spacer(minLength: 0)

                AlarmControls(presentation: attributes.presentation, state: state)
            }
        }
        .padding(TickerSpacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel(for: attributes, state: state))
        .accessibilityValue(accessibilityValue(for: state))
    }

    /// The single most legible-in-under-a-second datum for each mode.
    @ViewBuilder
    private func primaryReadout(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        switch state.mode {
        case .alert(let alert):
            // Fire time leads. It answers "what time is it / why am I awake"
            // before the label answers "which alarm".
            Text(formatted(alert.time))
                .LargeTitle()
                .monospacedDigit()
                .foregroundStyle(TickerColor.alerting)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

        case .countdown(let countdown):
            Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
                .LargeTitle()
                .monospacedDigit()
                .foregroundStyle(tint(attributes))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

        case .paused(let paused):
            Text(remaining(paused).formatted(pattern(for: remaining(paused))))
                .LargeTitle()
                .monospacedDigit()
                .foregroundStyle(TickerColor.paused)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Dynamic Island: expanded

    @ViewBuilder
    private func expandedLeading(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        HStack(spacing: TickerSpacing.xs) {
            Image(systemName: icon(attributes))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isAlerting(state.mode) ? TickerColor.alerting : tint(attributes))

            Text(title(attributes))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                // Island colours are fixed: routing them through colorScheme
                // returned black text on the permanently black Island.
                .foregroundStyle(TickerColor.onIslandPrimary)
                .lineLimit(1)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func expandedTrailing(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        Group {
            switch state.mode {
            case .alert(let alert):
                Text(formatted(alert.time))
                    .foregroundStyle(TickerColor.alerting)
            case .countdown(let countdown):
                Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
                    .foregroundStyle(TickerColor.onIslandPrimary)
            case .paused(let paused):
                Text(remaining(paused).formatted(pattern(for: remaining(paused))))
                    .foregroundStyle(TickerColor.onIslandSecondary)
            @unknown default:
                EmptyView()
            }
        }
        .font(.system(size: 20, weight: .bold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    // MARK: - Dynamic Island: compact + minimal

    @ViewBuilder
    private func compactLeading(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        Image(systemName: isAlerting(state.mode) ? "bell.badge.fill" : icon(attributes))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isAlerting(state.mode) ? TickerColor.alerting : tint(attributes))
            .symbolEffect(.pulse, options: .repeating, isActive: isAlerting(state.mode))
    }

    @ViewBuilder
    private func compactTrailing(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        Group {
            switch state.mode {
            case .alert(let alert):
                Text(formatted(alert.time))
                    .foregroundStyle(TickerColor.alerting)
            case .countdown(let countdown):
                Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
                    .foregroundStyle(TickerColor.onIslandPrimary)
            case .paused(let paused):
                Text(remaining(paused).formatted(pattern(for: remaining(paused))))
                    .foregroundStyle(TickerColor.onIslandSecondary)
            @unknown default:
                EmptyView()
            }
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .frame(maxWidth: 58)
    }

    /// Exactly one glyph. The minimal region is roughly 24pt across; the previous
    /// implementation put an HStack of a 20pt ZStack plus a text run in there.
    @ViewBuilder
    private func minimal(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        Image(systemName: isAlerting(state.mode) ? "bell.badge.fill" : icon(attributes))
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(isAlerting(state.mode) ? TickerColor.alerting : tint(attributes))
            .symbolEffect(.pulse, options: .repeating, isActive: isAlerting(state.mode))
    }

    // MARK: - Helpers

    private func remaining(_ paused: AlarmPresentationState.Mode.Paused) -> Duration {
        .seconds(max(0, paused.totalCountdownDuration - paused.previouslyElapsedDuration))
    }

    private func pattern(for duration: Duration) -> Duration.TimeFormatStyle {
        let pattern: Duration.TimeFormatStyle.Pattern =
            duration > .seconds(3600) ? .hourMinuteSecond : .minuteSecond
        return .time(pattern: pattern)
    }

    // MARK: - Accessibility

    private func accessibilityLabel(
        for attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> String {
        let name = attributes.metadata?.name ?? "Alarm"
        switch state.mode {
        case .alert: return "\(name), alarm ringing"
        case .countdown: return "\(name), countdown running"
        case .paused: return "\(name), countdown paused"
        @unknown default: return name
        }
    }

    private func accessibilityValue(for state: AlarmPresentationState) -> String {
        switch state.mode {
        case .alert(let alert):
            return "Set for \(formatted(alert.time))"
        case .countdown(let countdown):
            return formatAccessibleDuration(countdown.fireDate.timeIntervalSinceNow)
        case .paused(let paused):
            return formatAccessibleDuration(
                paused.totalCountdownDuration - paused.previouslyElapsedDuration
            )
        @unknown default:
            return ""
        }
    }

    private func formatAccessibleDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        var components: [String] = []
        if hours > 0 { components.append("\(hours) \(hours == 1 ? "hour" : "hours")") }
        if minutes > 0 { components.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")") }
        if secs > 0 || components.isEmpty { components.append("\(secs) \(secs == 1 ? "second" : "seconds")") }

        return components.joined(separator: ", ") + " remaining"
    }
}

// MARK: - Widget Previews

#Preview("Live Activity - Countdown", as: .content, using: AlarmLiveActivity.mockAttributes()) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockCountdownState()
}

#Preview("Live Activity - Paused", as: .content, using: AlarmLiveActivity.mockAttributes(title: "Workout Timer", icon: "figure.run")) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockPausedState()
}

#Preview("Live Activity - Alert", as: .content, using: AlarmLiveActivity.mockAttributes(title: "Wake up", icon: "alarm.fill")) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockAlertState()
}

#Preview("Alert - Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: AlarmLiveActivity.mockAttributes(title: "Wake up", icon: "alarm.fill")) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockAlertState()
}

#Preview("Alert - Dynamic Island Compact", as: .dynamicIsland(.compact), using: AlarmLiveActivity.mockAttributes(title: "Wake up", icon: "alarm.fill")) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockAlertState()
}

#Preview("Alert - Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: AlarmLiveActivity.mockAttributes(title: "Wake up", icon: "alarm.fill")) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockAlertState()
}

#Preview("Countdown - Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: AlarmLiveActivity.mockAttributes()) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockCountdownState()
}
