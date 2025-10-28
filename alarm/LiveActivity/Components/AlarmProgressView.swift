//
//  AlarmProgressView.swift
//  alarm
//
//  Progress indicator view for Live Activity
//  Displays circular progress with icon and enhanced animations
//

import AlarmKit
import SwiftUI

/// Progress indicator for Live Activity showing countdown state
struct AlarmProgressView: View {
    var tickerIcon: String?
    var mode: AlarmPresentationState.Mode
    var tint: Color

    var body: some View {
        Group {
            switch mode {
            case .countdown(let countdown):
                ZStack {
                    // Background circle with enhanced glow
                    Circle()
                        .stroke(tint.opacity(0.3), lineWidth: 3)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(tint.opacity(0.1))
                                .frame(width: 26, height: 26)
                        )

                    // Progress circle with gradient
                    Circle()
                        .trim(from: 0, to: calculateProgress(countdown: countdown))
                        .stroke(
                            AngularGradient(
                                colors: [tint, tint.opacity(0.9), tint.opacity(0.7)],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 22, height: 22)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: countdown.fireDate)

                    // Icon with subtle pulse
                    Image(systemName: tickerIcon ?? "bell.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(tint)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: countdown.fireDate)
                }
            case .paused(let state):
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(tint.opacity(0.3), lineWidth: 3)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(tint.opacity(0.1))
                                .frame(width: 26, height: 26)
                        )

                    // Paused progress with static gradient
                    Circle()
                        .trim(from: 0, to: calculatePausedProgress(state: state))
                        .stroke(
                            LinearGradient(
                                colors: [tint.opacity(0.8), tint.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 22, height: 22)
                        .rotationEffect(.degrees(-90))

                    // Pause icon
                    Image(systemName: "pause.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(tint)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
            default:
                EmptyView()
            }
        }
    }
    
    private func calculateProgress(countdown: AlarmPresentationState.Mode.Countdown) -> Double {
        let totalDuration = countdown.fireDate.timeIntervalSince(countdown.startDate)
        let elapsed = Date.now.timeIntervalSince(countdown.startDate)
        let progress = max(0, min(1, elapsed / totalDuration))
        return progress
    }
    
    private func calculatePausedProgress(state: AlarmPresentationState.Mode.Paused) -> Double {
        let totalDuration = Double(state.totalCountdownDuration)
        let elapsed = Double(state.previouslyElapsedDuration)
        let progress = max(0, min(1, elapsed / totalDuration))
        return progress
    }
}
