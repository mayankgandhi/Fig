//
//  AlarmLiveActivity.swift
//  alarm
//
//  Live Activity configuration for alarm countdown and alerts
//  Refactored to use extracted components
//
//  Note: LiveActivity intents (PauseIntent, StopIntent, ResumeIntent) are located
//  at fig/AppIntents/LiveActivity/
//

import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit
import TickerCore

struct AlarmLiveActivity: Widget {
    
    @Environment(\.colorScheme) var colorScheme
    
    private func isCountdownMode(_ mode: AlarmPresentationState.Mode) -> Bool {
        switch mode {
            case .countdown: return true
            case .paused, .alert: return false
            @unknown default: return false
        }
    }

    private func isPausedMode(_ mode: AlarmPresentationState.Mode) -> Bool {
        switch mode {
            case .paused: return true
            case .countdown, .alert: return false
            @unknown default: return false
        }
    }
    
    // Helper to build Dynamic Island expanded content
    @ViewBuilder
    private func dynamicIslandContent(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        expandedBottomView(attributes: attributes, state: state)
    }
    
    @ViewBuilder
    private func compactLeadingContent(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        let tint = Color(hex: attributes.metadata?.colorHex ?? "#000000") ?? TickerColor.primary
        HStack(spacing: TickerSpacing.xs) {
            switch state.mode {
            case .countdown, .paused:
                Image(systemName: stateIcon(for: state.mode))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
                    .symbolEffect(.pulse, isActive: isCountdownMode(state.mode))
                countdown(state: state, maxWidth: 50)
                    .ButtonText()
            case .alert:
                Image(systemName: "bell.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(TickerColor.alerting)
                    .symbolEffect(.pulse, isActive: true)
                Text(attributes.metadata?.name ?? "Alarm")
                    .ButtonText()
                    .lineLimit(1)
            @unknown default:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func compactTrailingContent(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        AlarmProgressView(
            tickerIcon: attributes.metadata?.icon,
            mode: state.mode,
            tint: Color(
                hex: attributes.metadata?.colorHex ?? "#000000"
            ) ?? TickerColor.primary
        )
    }
    
    @ViewBuilder
    private func minimalContent(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        minimalDynamicIslandView(attributes: attributes, state: state)
    }
    
    private func stateIcon(for mode: AlarmPresentationState.Mode) -> String {
        switch mode {
            case .countdown: return "timer"
            case .paused: return "pause.circle.fill"
            case .alert: return "bell.fill"
            @unknown default: return "bell"
        }
    }

    private func stateColor(for mode: AlarmPresentationState.Mode) -> Color {
        switch mode {
            case .countdown:
                return TickerColor.running
            case .paused:
                return TickerColor.paused
            case .alert:
                return TickerColor.alerting
            @unknown default:
                return TickerColor.disabled
        }
    }

    // MARK: - Accessibility Helpers

    private func accessibilityLabel(for attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> String {
        let name = attributes.metadata?.name ?? "Alarm"
        let modeText = modeName(for: state.mode)
        return "\(name) \(modeText)"
    }

    private func accessibilityValue(for state: AlarmPresentationState) -> String {
        switch state.mode {
        case .countdown(let countdown):
            let remaining = max(0, countdown.fireDate.timeIntervalSinceNow)
            return formatAccessibleDuration(remaining)
        case .paused(let pausedState):
            let remaining = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
            return formatAccessibleDuration(remaining)
        case .alert:
            return "Alarm is alerting"
        @unknown default:
            return ""
        }
    }

    private func modeName(for mode: AlarmPresentationState.Mode) -> String {
        switch mode {
        case .countdown: return "countdown running"
        case .paused: return "countdown paused"
        case .alert: return "alerting"
        @unknown default: return "inactive"
        }
    }

    private func formatAccessibleDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        var components: [String] = []
        if hours > 0 {
            components.append("\(hours) \(hours == 1 ? "hour" : "hours")")
        }
        if minutes > 0 {
            components.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }
        if secs > 0 || components.isEmpty {
            components.append("\(secs) \(secs == 1 ? "second" : "seconds")")
        }

        return components.joined(separator: ", ") + " remaining"
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<TickerData>.self) { context in
            // The Lock Screen presentation.
            lockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    dynamicIslandContent(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                compactLeadingContent(attributes: context.attributes, state: context.state)
            } compactTrailing: {
                compactTrailingContent(attributes: context.attributes, state: context.state)
            } minimal: {
                minimalContent(attributes: context.attributes, state: context.state)
            }
            .keylineTint(Color(
                hex: context.attributes.metadata?.colorHex ?? "#000000"
            ) ?? TickerColor.primary)
        }
    }
    
    @ViewBuilder
    func lockScreenView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        VStack(spacing: TickerSpacing.lg) {
            HStack(alignment: .top) {
                tickerCategory(metadata: attributes.metadata)
                    .accessibilityHidden(true)
                Spacer()
                Text("Ticker")
                    .SmallText()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .accessibilityHidden(true)
            }

            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, TickerSpacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel(for: attributes, state: state))
        .accessibilityValue(accessibilityValue(for: state))
        .accessibilityHint("Alarm display with controls")
    }
    
    func bottomView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        HStack(spacing: TickerSpacing.md) {
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                switch state.mode {
                case .countdown, .paused:
                    countdown(state: state, maxWidth: 150)
                        .TimeDisplay()
                case .alert:
                    Text("Alerting")
                        .TimeDisplay()
                        .foregroundStyle(TickerColor.alerting)
                @unknown default:
                    EmptyView()
                }

                HStack(spacing: TickerSpacing.sm) {
                    Image(systemName: stateIcon(for: state.mode))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(stateColor(for: state.mode))
                        .symbolEffect(.pulse, isActive: !isPausedMode(state.mode))

                    Text(modeName(for: state.mode).capitalized)
                        .DetailText()
                }
            }

            Spacer()

            AlarmControls(presentation: attributes.presentation, state: state)
        }
    }
    
    func countdown(state: AlarmPresentationState, maxWidth: CGFloat = .infinity) -> some View {
        Group {
            switch state.mode {
                case .countdown(let countdown):
                    Text(timerInterval: Date.now ... countdown.fireDate, countsDown: true)
                        .TimeDisplay()
                case .paused(let state):
                    let remaining = Duration.seconds(state.totalCountdownDuration - state.previouslyElapsedDuration)
                    let pattern: Duration.TimeFormatStyle.Pattern = remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                    Text(remaining.formatted(.time(pattern: pattern)))
                        .TimeDisplay()
                case .alert:
                    EmptyView()
                @unknown default:
                    EmptyView()
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
    
    @ViewBuilder func tickerCategory(metadata: TickerData?) -> some View {
        if let name = metadata?.name, let icon = metadata?.icon, let colorHex = metadata?.colorHex {
            HStack(spacing: TickerSpacing.xs) {
                Image(systemName: icon)
                    .Title2()
                    .bold()
                    .foregroundStyle(
                        Color(hex: colorHex) ?? TickerColor
                            .textPrimary(for: colorScheme)
                    )
                Text(name)
                    .Title2()
                    .bold()
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(
                        Color(hex: colorHex) ?? TickerColor
                            .textPrimary(for: colorScheme)
                    )
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Dynamic Island Expanded Leading View
    func expandedLeadingView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            // Alarm category/name with icon
            if let metadata = attributes.metadata {
                HStack(spacing: TickerSpacing.xs) {
                    Image(systemName: metadata.icon ?? "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            Color(hex: metadata.colorHex ?? "#000000") ?? TickerColor.primary
                        )
                    
                    Text(metadata.name ?? "Alarm")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        .lineLimit(1)
                }
            }
            
            // Status indicator with app branding
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                HStack(spacing: TickerSpacing.xs) {
                    Image(systemName: stateIcon(for: state.mode))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(stateColor(for: state.mode))
                        .symbolEffect(.pulse, isActive: isCountdownMode(state.mode))
                    Text(modeName(for: state.mode).capitalized)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
                
                // App branding
                Text("Ticker")
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
            }
        }
    }
    
    // MARK: - Dynamic Island Expanded Bottom View
    func expandedBottomView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        HStack(spacing: TickerSpacing.lg) {
            // Countdown time - prominently displayed
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                Group {
                    switch state.mode {
                    case .countdown(let countdown):
                        Text(timerInterval: Date.now ... countdown.fireDate, countsDown: true)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                Color(hex: attributes.metadata?.colorHex ?? "#000000") ?? TickerColor.primary
                            )
                    case .paused(let state):
                        let remaining = Duration.seconds(state.totalCountdownDuration - state.previouslyElapsedDuration)
                        let pattern: Duration.TimeFormatStyle.Pattern = remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                        Text(remaining.formatted(.time(pattern: pattern)))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                Color(hex: attributes.metadata?.colorHex ?? "#000000") ?? TickerColor.primary
                            )
                    case .alert:
                        Text("Alerting")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(TickerColor.alerting)
                    @unknown default:
                        EmptyView()
                    }
                }
                .monospacedDigit()
                .lineLimit(1)

                HStack(spacing: TickerSpacing.xs) {
                    Image(systemName: stateIcon(for: state.mode))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(stateColor(for: state.mode))
                        .symbolEffect(.pulse, isActive: isCountdownMode(state.mode))
                    Text(modeName(for: state.mode).capitalized)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            
            Spacer()
            
            // Controls and progress indicator
            VStack(spacing: TickerSpacing.sm) {
                AlarmProgressView(
                    tickerIcon: attributes.metadata?.icon,
                    mode: state.mode,
                    tint: Color(
                        hex: attributes.metadata?.colorHex ?? "#000000"
                    ) ?? TickerColor.primary
                )
                .frame(width: 44, height: 44)
                
                AlarmControls(presentation: attributes.presentation, state: state)
            }
        }
        .padding(.horizontal, TickerSpacing.md)
    }
    
    // MARK: - Dynamic Island Minimal View
    func minimalDynamicIslandView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        let tint = Color(hex: attributes.metadata?.colorHex ?? "#000000") ?? TickerColor.primary
        return AlarmProgressView(
            tickerIcon: attributes.metadata?.icon,
            mode: state.mode,
            tint: tint
        )
        .frame(width: 22, height: 22)
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

#Preview("Live Activity - Alert", as: .content, using: AlarmLiveActivity.mockAttributes(title: "Meeting Reminder", icon: "calendar")) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockAlertState()
}

#Preview("Live Activity - Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: AlarmLiveActivity.mockAttributes()) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockCountdownState()
}

#Preview("Live Activity - Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: AlarmLiveActivity.mockAttributes()) {
    AlarmLiveActivity()
} contentStates: {
    AlarmLiveActivity.mockCountdownState()
}

#Preview("Full Preview Showcase") {
    AlarmLiveActivityPreview()
}
