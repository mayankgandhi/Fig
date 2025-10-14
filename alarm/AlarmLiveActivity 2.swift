/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The views for different Live Activity configurations for the app.
*/

import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

// Note: LiveActivity intents (PauseIntent, StopIntent, ResumeIntent) are now located
// at fig/AppIntents/LiveActivity/

struct AlarmLiveActivity: Widget {
    
    // Helper function to check if mode is countdown
    private func isCountdownMode(_ mode: AlarmPresentationState.Mode) -> Bool {
        switch mode {
        case .countdown:
            return true
        case .paused, .alert:
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
                            .font(.system(size: 14, weight: .bold, design: .rounded))
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
                        .font(.system(size: 12, weight: .bold, design: .rounded))
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
                    .font(.system(size: 36, weight: .bold, design: .rounded))
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
                    .font(.system(size: 16, weight: .medium))
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

struct AlarmProgressView: View {
    var tickerIcon: String?
    var mode: AlarmPresentationState.Mode
    var tint: Color

    var body: some View {
        Group {
            switch mode {
            case .countdown(let countdown):
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(tint.opacity(0.2), lineWidth: 2)
                        .frame(width: 16, height: 16)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: 0.75) // 3/4 progress for visual appeal
                        .stroke(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: countdown.fireDate)
                    
                    // Icon
                    Image(systemName: tickerIcon ?? "bell.fill")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(tint)
                }
            case .paused(let pausedState):
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(tint.opacity(0.2), lineWidth: 2)
                        .frame(width: 16, height: 16)
                    
                    // Paused progress
                    Circle()
                        .trim(from: 0, to: 0.5) // Half progress for paused state
                        .stroke(
                            LinearGradient(
                                colors: [tint.opacity(0.6), tint.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(-90))
                    
                    // Pause icon
                    Image(systemName: "pause.fill")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(tint.opacity(0.7))
                }
            default:
                EmptyView()
            }
        }
    }
}

struct AlarmControls: View {
    var presentation: AlarmPresentation
    var state: AlarmPresentationState
    
    var body: some View {
        HStack(spacing: 4) {
            switch state.mode {
            case .countdown:
                ButtonView(config: presentation.countdown?.pauseButton, intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: .orange)
            case .paused:
                ButtonView(config: presentation.paused?.resumeButton, intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: .orange)
            default:
                EmptyView()
            }

            ButtonView(config: presentation.alert.stopButton, intent: StopIntent(alarmID: state.alarmID.uuidString), tint: .red)
        }
    }
}

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
