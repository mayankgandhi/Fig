//
//  AlarmProgressView.swift
//  alarm
//
//  Progress indicator view for Live Activity
//  Displays circular progress with icon
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
                        .animation(TickerAnimation.pulse, value: countdown.fireDate)

                    // Icon
                    Image(systemName: tickerIcon ?? "bell.fill")
                        .Caption2()
                        .foregroundStyle(tint)
                }
            case .paused:
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
                        .Caption2()
                        .foregroundStyle(tint.opacity(0.7))
                }
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Alarm Progress - Countdown Mode") {
    AlarmProgressView(
        tickerIcon: "figure.run",
        mode: .countdown(AlarmPresentationState.Countdown(fireDate: Date().addingTimeInterval(3600))),
        tint: TickerColor.running
    )
    .padding()
}

#Preview("Alarm Progress - Paused Mode") {
    AlarmProgressView(
        tickerIcon: "figure.run",
        mode: .paused(AlarmPresentationState.Paused(
            totalCountdownDuration: 3600,
            previouslyElapsedDuration: 1800
        )),
        tint: TickerColor.paused
    )
    .padding()
}

#Preview("Alarm Progress - Alert Mode") {
    AlarmProgressView(
        tickerIcon: "bell.fill",
        mode: .alert,
        tint: TickerColor.alerting
    )
    .padding()
}
