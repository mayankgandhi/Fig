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
    
    // Helper function to check if mode is countdown
    private func isCountdownMode(_ mode: AlarmPresentationState.Mode) -> Bool {
        switch mode {
            case .countdown:
                return true
            case .paused, .alert:
                return false
            @unknown default:
                return false
        }
    }
    
    // Helper function to check if ticker has countdown capability
    // This checks the presentation structure, not just the current state
    private func hasCountdownCapability(_ presentation: AlarmPresentation) -> Bool {
        // If presentation has countdown content, the ticker supports countdown
        return presentation.countdown != nil
    }
    
    // Helper function to check if mode has countdown capability (countdown or paused)
    // Alert-only modes (without countdown) should not show Dynamic Island
    private func hasCountdownState(_ mode: AlarmPresentationState.Mode) -> Bool {
        switch mode {
            case .countdown, .paused:
                return true
            case .alert:
                return false
            @unknown default:
                return false
        }
    }
    
    // Helper to conditionally show Dynamic Island content
    // Only show during countdown/paused states, not during alert
    @ViewBuilder
    private func dynamicIslandContent(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        if hasCountdownCapability(attributes.presentation) && hasCountdownState(state.mode) {
            expandedBottomView(attributes: attributes, state: state)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func compactLeadingContent(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        if hasCountdownCapability(attributes.presentation) && hasCountdownState(state.mode) {
            HStack(spacing: TickerSpacing.xs) {
                Circle()
                    .fill(Color(
                        hex: attributes.metadata?.colorHex ?? "#000000"
                    ) ?? TickerColor.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isCountdownMode(state.mode) ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(state.mode))
                
                countdown(state: state, maxWidth: 50)
                    .ButtonText()
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func compactTrailingContent(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        if hasCountdownCapability(attributes.presentation) && hasCountdownState(state.mode) {
            AlarmProgressView(
                tickerIcon: attributes.metadata?.icon,
                mode: state.mode,
                tint: Color(
                    hex: attributes.metadata?.colorHex ?? "#000000"
                ) ?? TickerColor.primary
            )
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func minimalContent(
        attributes: AlarmAttributes<TickerData>,
        state: AlarmPresentationState
    ) -> some View {
        if hasCountdownCapability(attributes.presentation) && hasCountdownState(state.mode) {
            minimalDynamicIslandView(attributes: attributes, state: state)
        } else {
            EmptyView()
        }
    }
    
    // Helper function to get state color based on mode
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
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<TickerData>.self) { context in
            // The Lock Screen presentation.
            lockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            // Only show Dynamic Island for tickers with countdown (countdown or paused states)
            // Hide it for alert-only states (tickers without countdown)
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
        // Only show Live Activity content during countdown/paused states
        // Hide it during alert state (even for tickers with countdown capability)
        if hasCountdownCapability(attributes.presentation) && hasCountdownState(state.mode) {
            VStack(spacing: TickerSpacing.lg) {
                HStack(alignment: .top) {
                    tickerCategory(metadata: attributes.metadata)
                    Spacer()
                    // App branding
                    Text("Ticker")
                        .SmallText()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                }
                
                bottomView(attributes: attributes, state: state)
            }
            .padding(.all, TickerSpacing.md)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Alarm countdown: \(state.mode)")
        } else {
            // Show minimal/empty view for alert state or non-countdown tickers
            EmptyView()
        }
    }
    
    func bottomView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        HStack(spacing: TickerSpacing.md) {
            // Enhanced countdown display (prioritized)
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                countdown(state: state, maxWidth: 150)
                    .TimeDisplay()
                
                // Enhanced status indicator - only show for countdown mode
                if isCountdownMode(state.mode) {
                    HStack(spacing: TickerSpacing.sm) {
                        Circle()
                            .fill(stateColor(for: state.mode))
                            .frame(width: 12, height: 12)
                            .scaleEffect(1.3)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(state.mode))
                        
                        Text("Running")
                            .DetailText()
                    }
                }
            }
            
            Spacer()
            
            // Enhanced controls with better spacing
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
                default:
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
                if isCountdownMode(state.mode) {
                    HStack(spacing: TickerSpacing.xs) {
                        Circle()
                            .fill(
                                Color(
                                    hex: attributes.metadata?.colorHex ?? "#000000"
                                ) ?? TickerColor.primary
                            )
                            .frame(width: 6, height: 6)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(state.mode))
                        
                        Text("Active")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    }
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
                    default:
                        EmptyView()
                    }
                }
                .monospacedDigit()
                .lineLimit(1)
                
                // Mode indicator
                HStack(spacing: TickerSpacing.xs) {
                    switch state.mode {
                    case .countdown:
                        Image(systemName: "timer")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TickerColor.running)
                        Text("Running")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    case .paused:
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TickerColor.paused)
                        Text("Paused")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    case .alert:
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TickerColor.alerting)
                        Text("Alerting")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    @unknown default:
                        EmptyView()
                    }
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
        HStack(spacing: TickerSpacing.xs) {
            // Progress indicator with icon
            ZStack {
                // Animated background pulse
                Circle()
                    .fill(
                        Color(
                            hex: attributes.metadata?.colorHex ?? "#000000"
                        ) ?? TickerColor.primary
                    )
                    .opacity(0.2)
                    .frame(width: 20, height: 20)
                    .scaleEffect(isCountdownMode(state.mode) ? 1.4 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(state.mode))
                
                // Progress circle
                AlarmProgressView(
                    tickerIcon: attributes.metadata?.icon,
                    mode: state.mode,
                    tint: Color(
                        hex: attributes.metadata?.colorHex ?? "#000000"
                    ) ?? TickerColor.primary
                )
                .frame(width: 18, height: 18)
            }
            
            // Compact countdown text
            Group {
                switch state.mode {
                case .countdown(let countdown):
                    Text(timerInterval: Date.now ... countdown.fireDate, countsDown: true)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        .lineLimit(1)
                case .paused(let pausedState):
                    let remaining = Duration.seconds(pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration)
                    let pattern: Duration.TimeFormatStyle.Pattern = remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                    Text(remaining.formatted(.time(pattern: pattern)))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        .lineLimit(1)
                case .alert:
                    // Show alert indicator for minimal view
                    Image(systemName: "bell.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(TickerColor.alerting)
                @unknown default:
                    EmptyView()
                }
            }
        }
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
