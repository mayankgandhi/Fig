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
                // The expanded Dynamic Island presentation.
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                        // Countdown time (largest, prioritized)
                        countdown(state: context.state, maxWidth: 120)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(stateColor(for: context.state.mode))
                        
                        // Alarm title below countdown
                        alarmTitle(attributes: context.attributes, state: context.state)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: TickerSpacing.xs) {
                        // Enhanced status indicator with better visual hierarchy
                        HStack(spacing: TickerSpacing.xs) {
                            Circle()
                                .fill(stateColor(for: context.state.mode))
                                .frame(width: 8, height: 8)
                                .scaleEffect(isCountdownMode(context.state.mode) ? 1.4 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(context.state.mode))

                            Text(isCountdownMode(context.state.mode) ? "Active" : "Paused")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(TickerColor.textSecondary(for: .light))
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
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(stateColor(for: context.state.mode))
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
                alarmTitle(attributes: attributes, state: state)
                Spacer()
                tickerCategory(metadata: attributes.metadata)
            }

            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, TickerSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .fill(TickerColor.surface(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.large)
                        .strokeBorder(
                            LinearGradient(
                                colors: [stateColor(for: state.mode).opacity(0.3), stateColor(for: state.mode).opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: stateColor(for: state.mode).opacity(0.2),
            radius: TickerShadow.elevated.radius,
            x: TickerShadow.elevated.x,
            y: TickerShadow.elevated.y
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alarm countdown: \(state.mode)")
    }

    func bottomView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        HStack(spacing: TickerSpacing.lg) {
            // Enhanced countdown display (prioritized)
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                countdown(state: state, maxWidth: 150)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(stateColor(for: state.mode))

                // Enhanced status indicator with better visual hierarchy
                HStack(spacing: TickerSpacing.xs) {
                    Circle()
                        .fill(stateColor(for: state.mode))
                        .frame(width: 10, height: 10)
                        .scaleEffect(isCountdownMode(state.mode) ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(state.mode))

                    Text(isCountdownMode(state.mode) ? "Running" : "Paused")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TickerColor.textSecondary(for: .light))
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
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
            case .paused(let state):
                let remaining = Duration.seconds(state.totalCountdownDuration - state.previouslyElapsedDuration)
                let pattern: Duration.TimeFormatStyle.Pattern = remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                Text(remaining.formatted(.time(pattern: pattern)))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
            default:
                EmptyView()
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .foregroundStyle(stateColor(for: state.mode))
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
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
                .font(.system(size: 16, weight: .semibold, design: .default))
                .lineLimit(1)
                .foregroundStyle(TickerColor.textPrimary(for: .light))
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)

            Text("Alarm")
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundStyle(TickerColor.textSecondary(for: .light))
        }
    }

    @ViewBuilder func tickerCategory(metadata: TickerData?) -> some View {
        if let name = metadata?.name, let icon = metadata?.icon {
            HStack(spacing: TickerSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TickerColor.textPrimary(for: .light))

                Text(name)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, TickerSpacing.sm)
            .padding(.vertical, TickerSpacing.xs)
            .background(
                Capsule()
                    .fill(TickerColor.surface(for: .light))
                    .overlay(
                        Capsule()
                            .strokeBorder(TickerColor.textTertiary(for: .light), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        } else {
            EmptyView()
        }
    }
}
