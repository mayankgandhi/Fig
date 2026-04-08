//
//  AlarmProgressView.swift
//  alarm
//
//  Progress indicator view for Live Activity
//  Displays circular progress with icon and real-time updates via TimelineView
//

import AlarmKit
import SwiftUI

/// Progress indicator for Live Activity showing countdown state
struct AlarmProgressView: View {
    var tickerIcon: String?
    var mode: AlarmPresentationState.Mode
    var tint: Color

    var body: some View {
        switch mode {
        case .countdown(let countdown):
            countdownRing(countdown: countdown)
        case .paused(let state):
            pausedRing(state: state)
        case .alert:
            alertRing()
        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Countdown (real-time via TimelineView)

    private func countdownRing(countdown: AlarmPresentationState.Mode.Countdown) -> some View {
        TimelineView(.periodic(every: 1)) { timeline in
            let totalDuration = countdown.fireDate.timeIntervalSince(countdown.startDate)
            guard totalDuration > 0 else { return }
            let elapsed = timeline.date.timeIntervalSince(countdown.startDate)
            let progress = max(0, min(1, elapsed / totalDuration))

            ZStack {
                Circle()
                    .stroke(tint.opacity(0.3), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Image(systemName: tickerIcon ?? "bell.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
                    .symbolEffect(.pulse, isActive: true)
            }
            .frame(width: 22, height: 22)
        }
    }

    // MARK: - Paused (static at paused position)

    private func pausedRing(state: AlarmPresentationState.Mode.Paused) -> some View {
        let progress = calculatePausedProgress(state: state)
        return ZStack {
            Circle()
                .stroke(tint.opacity(0.3), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [tint.opacity(0.8), tint.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: "pause.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
        }
        .frame(width: 22, height: 22)
    }

    // MARK: - Alert (completed ring with pulsing bell)

    private func alertRing() -> some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.3), lineWidth: 3)

            Circle()
                .trim(from: 0, to: 1)
                .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Image(systemName: "bell.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(TickerColor.alerting)
                .symbolEffect(.bounce, isActive: true)
        }
        .frame(width: 22, height: 22)
    }

    // MARK: - Helpers

    private func calculatePausedProgress(state: AlarmPresentationState.Mode.Paused) -> Double {
        let totalDuration = Double(state.totalCountdownDuration)
        guard totalDuration > 0 else { return 0 }
        let elapsed = Double(state.previouslyElapsedDuration)
        return max(0, min(1, elapsed / totalDuration))
    }
}
