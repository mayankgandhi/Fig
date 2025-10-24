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

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<TickerData>.self) { context in
            // The Lock Screen presentation.
            lockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            // The presentations that appear in the Dynamic Island.
            DynamicIsland {
                // The expanded Dynamic Island presentation.
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        alarmTitle(attributes: context.attributes, state: context.state)

                        // Status indicator for expanded view
                        HStack(spacing: 6) {
                            Circle()
                                .fill(context.attributes.tintColor)
                                .frame(width: 6, height: 6)
                                .scaleEffect(isCountdownMode(context.state.mode) ? 1.3 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(context.state.mode))

                            Text(isCountdownMode(context.state.mode) ? "Active" : "Paused")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        tickerCategory(metadata: context.attributes.metadata)

                        // Quick countdown in expanded view
                        countdown(state: context.state, maxWidth: 80)
                            .ButtonText()
                            .foregroundStyle(context.attributes.tintColor)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    bottomView(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                // The compact leading presentation.
                HStack(spacing: 4) {
                    Circle()
                        .fill(context.attributes.tintColor)
                        .frame(width: 6, height: 6)
                        .scaleEffect(isCountdownMode(context.state.mode) ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(context.state.mode))

                    countdown(state: context.state, maxWidth: 44)
                        .SmallText()
                        .foregroundStyle(context.attributes.tintColor)
                }
            } compactTrailing: {
                // The compact trailing presentation.
                AlarmProgressView(tickerIcon: context.attributes.metadata?.icon,
                                  mode: context.state.mode,
                                  tint: context.attributes.tintColor)
            } minimal: {
                // The minimal presentation with enhanced styling.
                ZStack {
                    // Background circle with subtle glow
                    Circle()
                        .fill(context.attributes.tintColor.opacity(0.1))
                        .frame(width: 20, height: 20)
                        .scaleEffect(isCountdownMode(context.state.mode) ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(context.state.mode))

                    // Progress indicator
                    AlarmProgressView(tickerIcon: context.attributes.metadata?.icon,
                                      mode: context.state.mode,
                                      tint: context.attributes.tintColor)
                }
            }
            .keylineTint(context.attributes.tintColor)
        }
    }

    func lockScreenView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                alarmTitle(attributes: attributes, state: state)
                Spacer()
                tickerCategory(metadata: attributes.metadata)
            }

            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, 16)
        .background(
            ZStack {
                // Glassmorphism background
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                attributes.tintColor.opacity(0.1),
                                Color.clear,
                                attributes.tintColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    func bottomView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        HStack(spacing: 20) {
            // Enhanced countdown display
            VStack(alignment: .leading, spacing: 4) {
                countdown(state: state, maxWidth: 150)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(attributes.tintColor)

                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(attributes.tintColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isCountdownMode(state.mode) ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(state.mode))

                    Text(isCountdownMode(state.mode) ? "Running" : "Paused")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
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

        VStack(alignment: .leading, spacing: 2) {
            Text(title ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Text("Alarm")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder func tickerCategory(metadata: TickerData?) -> some View {
        if let name = metadata?.name, let icon = metadata?.icon {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .Callout()
                    .foregroundStyle(.primary)

                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        } else {
            EmptyView()
        }
    }
}
