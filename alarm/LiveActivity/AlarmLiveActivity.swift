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

struct AlarmLiveActivity: Widget {

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
                // The expanded Dynamic Island presentation.
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                        // Countdown time (largest, prioritized)
                        countdown(state: context.state, maxWidth: 120)
                            .Title()
                            .foregroundStyle(stateColor(for: context.state.mode))
                        
                        // Alarm title below countdown
                        alarmTitle(attributes: context.attributes, state: context.state)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: TickerSpacing.xxs) {
                        // Status indicator
                        HStack(spacing: TickerSpacing.xxs) {
                            Circle()
                                .fill(stateColor(for: context.state.mode))
                                .frame(width: 6, height: 6)
                                .scaleEffect(isCountdownMode(context.state.mode) ? 1.3 : 1.0)
                                .animation(TickerAnimation.pulse, value: isCountdownMode(context.state.mode))

                            Text(isCountdownMode(context.state.mode) ? "Active" : "Paused")
                                .Caption2()
                                .fontWeight(.medium)
                                .foregroundStyle(TickerColor.textSecondary(for: .light))
                        }
                        
                        // Ticker category badge
                        tickerCategory(metadata: context.attributes.metadata)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    bottomView(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                // The compact leading presentation.
                HStack(spacing: TickerSpacing.xxs) {
                    Circle()
                        .fill(stateColor(for: context.state.mode))
                        .frame(width: 6, height: 6)
                        .scaleEffect(isCountdownMode(context.state.mode) ? 1.2 : 1.0)
                        .animation(TickerAnimation.pulse, value: isCountdownMode(context.state.mode))

                    countdown(state: context.state, maxWidth: 44)
                        .SmallText()
                        .foregroundStyle(stateColor(for: context.state.mode))
                }
            } compactTrailing: {
                // The compact trailing presentation.
                AlarmProgressView(tickerIcon: context.attributes.metadata?.icon,
                                  mode: context.state.mode,
                                  tint: stateColor(for: context.state.mode))
            } minimal: {
                // The minimal presentation with enhanced styling.
                ZStack {
                    // Background circle with subtle glow
                    Circle()
                        .fill(stateColor(for: context.state.mode).opacity(0.1))
                        .frame(width: 20, height: 20)
                        .scaleEffect(isCountdownMode(context.state.mode) ? 1.2 : 1.0)
                        .animation(TickerAnimation.pulse, value: isCountdownMode(context.state.mode))

                    // Progress indicator
                    AlarmProgressView(tickerIcon: context.attributes.metadata?.icon,
                                      mode: context.state.mode,
                                      tint: stateColor(for: context.state.mode))
                }
            }
            .keylineTint(stateColor(for: context.state.mode))
        }
    }

    func lockScreenView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        VStack(spacing: TickerSpacing.md) {
            HStack(alignment: .top) {
                alarmTitle(attributes: attributes, state: state)
                Spacer()
                tickerCategory(metadata: attributes.metadata)
            }

            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, TickerSpacing.md)
        .background(
            TickerColor.liquidGlassGradient(for: .light)
                .clipShape(RoundedRectangle(cornerRadius: TickerRadius.large))
        )
        .shadow(
            color: TickerShadow.elevated.color,
            radius: TickerShadow.elevated.radius,
            x: TickerShadow.elevated.x,
            y: TickerShadow.elevated.y
        )
    }

    func bottomView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        HStack(spacing: TickerSpacing.lg) {
            // Enhanced countdown display (prioritized)
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                countdown(state: state, maxWidth: 150)
                    .Title()
                    .foregroundStyle(stateColor(for: state.mode))

                // Status indicator
                HStack(spacing: TickerSpacing.xxs) {
                    Circle()
                        .fill(stateColor(for: state.mode))
                        .frame(width: 8, height: 8)
                        .scaleEffect(isCountdownMode(state.mode) ? 1.2 : 1.0)
                        .animation(TickerAnimation.pulse, value: isCountdownMode(state.mode))

                    Text(isCountdownMode(state.mode) ? "Running" : "Paused")
                        .Caption()
                        .fontWeight(.medium)
                        .foregroundStyle(TickerColor.textSecondary(for: .light))
                }
            }

            Spacer()

            // Enhanced controls
            AlarmControls(presentation: attributes.presentation, state: state)
        }
    }

    func countdown(state: AlarmPresentationState, maxWidth: CGFloat = .infinity) -> some View {
        Group {
            switch state.mode {
            case .countdown(let countdown):
                Text(timerInterval: Date.now ... countdown.fireDate, countsDown: true)
            case .paused(let state):
                let remaining = Duration.seconds(state.totalCountdownDuration - state.previouslyElapsedDuration)
                let pattern: Duration.TimeFormatStyle.Pattern = remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                Text(remaining.formatted(.time(pattern: pattern)))
            default:
                EmptyView()
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: maxWidth, alignment: .leading)
    }

    @ViewBuilder func alarmTitle(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        let title: LocalizedStringResource? = switch state.mode {
        case .countdown:
            attributes.presentation.countdown?.title
        case .paused:
            attributes.presentation.paused?.title
        default:
            nil
        }

        VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
            Text(title ?? "")
                .Title3()
                .lineLimit(1)
                .foregroundStyle(TickerColor.textPrimary(for: .light))

            Text("Alarm")
                .Caption()
                .fontWeight(.medium)
                .foregroundStyle(TickerColor.textSecondary(for: .light))
        }
    }

    @ViewBuilder func tickerCategory(metadata: TickerData?) -> some View {
        if let name = metadata?.name, let icon = metadata?.icon {
            HStack(spacing: TickerSpacing.xxs) {
                Image(systemName: icon)
                    .Callout()
                    .foregroundStyle(TickerColor.textPrimary(for: .light))

                Text(name)
                    .Subheadline()
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .padding(.horizontal, TickerSpacing.sm)
            .padding(.vertical, TickerSpacing.xxs)
            .background(
                Capsule()
                    .fill(TickerColor.surface(for: .light))
                    .overlay(
                        Capsule()
                            .strokeBorder(TickerColor.textTertiary(for: .light), lineWidth: 1)
                    )
            )
        } else {
            EmptyView()
        }
    }
}
