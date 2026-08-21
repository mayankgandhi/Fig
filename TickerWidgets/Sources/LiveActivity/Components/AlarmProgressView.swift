//
//  AlarmProgressView.swift
//  alarm
//
//  Progress indicator view for Live Activity
//

import AlarmKit
import SwiftUI
import TickerCore

/// Progress indicator for Live Activity showing countdown, paused and alerting states.
struct AlarmProgressView: View {
    var tickerIcon: String?
    var mode: AlarmPresentationState.Mode
    var tint: Color

    var body: some View {
        switch mode {
        case .countdown(let countdown):
            // `ProgressView(timerInterval:)` is the only circular progress that
            // advances on its own inside a widget process.
            //
            // The previous ring computed its own trim from `Date.now` at render
            // time, inside a view that only re-renders when ActivityKit pushes a
            // new content state — so it was frozen at its initial fill for the
            // entire countdown. Its `.animation(..., value: countdown.fireDate)`
            // guaranteed it, since `fireDate` never changes.
            ProgressView(
                timerInterval: countdown.startDate...countdown.fireDate,
                countsDown: true
            ) {
                EmptyView()
            } currentValueLabel: {
                Image(systemName: tickerIcon ?? "bell.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
            }
            .progressViewStyle(.circular)
            .tint(tint)

        case .paused(let state):
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.3), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: pausedProgress(state))
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Image(systemName: "pause.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
            }

        case .alert:
            // `symbolEffect` is self-animating and is honoured by WidgetKit,
            // unlike `.repeatForever` keyed on a value that never changes.
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(TickerColor.alerting)
                .symbolEffect(.pulse, options: .repeating)

        @unknown default:
            EmptyView()
        }
    }

    private func pausedProgress(_ state: AlarmPresentationState.Mode.Paused) -> Double {
        let total = state.totalCountdownDuration
        guard total > 0 else { return 0 }
        return max(0, min(1, state.previouslyElapsedDuration / total))
    }
}
