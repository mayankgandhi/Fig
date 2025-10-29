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
            // The presentations that appear in the Dynamic Island.
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .trailing) {
                        // Enhanced status indicator with better visual hierarchy
                        HStack(spacing: TickerSpacing.xs) {
                            Circle()
                                .fill(stateColor(for: context.state.mode))
                                .frame(width: 8, height: 8)
                                .scaleEffect(isCountdownMode(context.state.mode) ? 1.4 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(context.state.mode))
                            
                            Text(isCountdownMode(context.state.mode) ? "Active" : "Paused")
                                .SmallText()
                                .foregroundStyle(
                                    TickerColor.textSecondary(for: colorScheme)
                                )
                        }
                        
                        // Enhanced ticker category badge
                        tickerCategory(metadata: context.attributes.metadata)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    bottomView(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                // The compact leading presentation with enhanced styling
                HStack(spacing: TickerSpacing.xs) {
                    Circle()
                        .fill(stateColor(for: context.state.mode))
                        .frame(width: 8, height: 8)
                        .scaleEffect(isCountdownMode(context.state.mode) ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(context.state.mode))
                    
                    countdown(state: context.state, maxWidth: 50)
                        .ButtonText()
                }
            } compactTrailing: {
                // The compact trailing presentation with enhanced progress
                AlarmProgressView(tickerIcon: context.attributes.metadata?.icon,
                                  mode: context.state.mode,
                                  tint: stateColor(for: context.state.mode))
            } minimal: {
                // The minimal presentation with enhanced styling and glow effect
                ZStack {
                    // Background circle with enhanced glow
                    Circle()
                        .fill(stateColor(for: context.state.mode).opacity(0.15))
                        .frame(width: 24, height: 24)
                        .scaleEffect(isCountdownMode(context.state.mode) ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(context.state.mode))
                    
                    // Progress indicator with enhanced styling
                    AlarmProgressView(tickerIcon: context.attributes.metadata?.icon,
                                      mode: context.state.mode,
                                      tint: stateColor(for: context.state.mode))
                }
            }
            .keylineTint(stateColor(for: context.state.mode))
        }
    }
    
    func lockScreenView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        VStack(spacing: TickerSpacing.lg) {
            HStack(alignment: .top) {
                tickerCategory(metadata: attributes.metadata)
                Spacer()
            }
            
            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, TickerSpacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alarm countdown: \(state.mode)")
    }
    
    func bottomView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        HStack(spacing: TickerSpacing.lg) {
            // Enhanced countdown display (prioritized)
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                countdown(state: state, maxWidth: 150)
                    .TimeDisplay()
                
                // Enhanced status indicator with better visual hierarchy
                HStack(spacing: TickerSpacing.sm) {
                    Circle()
                        .fill(stateColor(for: state.mode))
                        .frame(width: 12, height: 12)
                        .scaleEffect(isCountdownMode(state.mode) ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(state.mode))
                    
                    Text(isCountdownMode(state.mode) ? "Running" : "Paused")
                        .DetailText()
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
        .frame(maxWidth: maxWidth, alignment: .leading)
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
                    .lineLimit(1)
                    .foregroundStyle(
                        Color(hex: colorHex) ?? TickerColor
                            .textPrimary(for: colorScheme)
                    )
            }
            
            
        } else {
            EmptyView()
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

