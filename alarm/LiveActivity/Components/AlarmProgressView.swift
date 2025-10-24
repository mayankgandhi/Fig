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
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: countdown.fireDate)

                    // Icon
                    Image(systemName: tickerIcon ?? "bell.fill")
                        .font(.system(size: 8, weight: .semibold))
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
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(tint.opacity(0.7))
                }
            default:
                EmptyView()
            }
        }
    }
}
