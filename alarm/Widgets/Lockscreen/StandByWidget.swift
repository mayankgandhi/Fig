//
//  StandByWidget.swift
//  alarm
//
//  StandBy mode widget optimized for nightstand viewing
//  Large, high-contrast design for distance viewing
//  Refactored to use shared components
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - StandBy Widget Provider

struct StandByWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> AlarmTimelineEntry {
        BaseTimelineProvider.createPlaceholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (AlarmTimelineEntry) -> Void) {
        completion(BaseTimelineProvider.createSnapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AlarmTimelineEntry>) -> Void) {
        BaseTimelineProvider.generateNextAlarmTimeline(
            in: context,
            completion: completion,
            timeWindowMinutes: 30,
            alarmTimeWindowHours: 24
        )
    }
}

// MARK: - StandBy Widget View

struct StandByWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: AlarmTimelineEntry

    var body: some View {
        if let alarm = entry.upcomingAlarms.first {
            // Next alarm view - optimized for distance viewing
            HStack(spacing: 32) {
                // Left side - Alarm icon and name
                VStack(alignment: .leading, spacing: 12) {
                    // Icon with glow
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(alarm.color.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .blur(radius: 20)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        alarm.color.opacity(0.4),
                                        alarm.color.opacity(0.2)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 64, height: 64)

                        Image(systemName: alarm.icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(alarm.color)
                    }

                    // Alarm name
                    Text(alarm.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Schedule badge
                    Text(alarm.scheduleType.badgeText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(alarm.scheduleType.badgeColor.opacity(0.8))
                        )
                }

                Spacer()

                // Right side - Time and countdown
                VStack(alignment: .trailing, spacing: 16) {
                    // Next alarm time - extra large
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("NEXT ALARM")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .tracking(1.5)

                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text(String(format: "%d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12))
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(alarm.color)

                            Text(":")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(alarm.color.opacity(0.5))

                            Text(String(format: "%02d", alarm.minute))
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(alarm.color)

                            Text(alarm.hour < 12 ? "AM" : "PM")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(alarm.color.opacity(0.8))
                                .offset(y: -8)
                        }
                        .shadow(color: alarm.color.opacity(0.5), radius: 20, x: 0, y: 0)
                        .shadow(color: alarm.color.opacity(0.3), radius: 40, x: 0, y: 0)
                    }

                    // Countdown - glowing
                    HStack(spacing: 8) {
                        // Pulsing indicator
                        Circle()
                            .fill(alarm.color)
                            .frame(width: 12, height: 12)
                            .shadow(color: alarm.color, radius: 8, x: 0, y: 0)
                            .shadow(color: alarm.color, radius: 16, x: 0, y: 0)

                        Text(alarm.timeUntilAlarm(from: entry.date))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .strokeBorder(alarm.color.opacity(0.5), lineWidth: 2)
                            )
                    )
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    // Deep black background
                    Color.black

                    // Radial glow from alarm color
                    RadialGradient(
                        colors: [
                            alarm.color.opacity(0.15),
                            alarm.color.opacity(0.05),
                            Color.clear
                        ],
                        center: .trailing,
                        startRadius: 50,
                        endRadius: 400
                    )

                    // Subtle top glow
                    LinearGradient(
                        colors: [
                            alarm.color.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
        } else {
            // No alarms view
            VStack(spacing: 24) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(TickerColor.textTertiary(for: colorScheme).opacity(0.2))
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)

                    Image(systemName: "alarm.slash")
                        .font(.system(size: 48, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(spacing: 8) {
                    Text("No Alarms")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Enjoy your rest")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
    }
}

// MARK: - StandBy Widget Configuration

struct StandByAlarmWidget: Widget {
    let kind: String = "StandByAlarmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StandByWidgetProvider()) { entry in
            StandByWidgetView(entry: entry)
        }
        .configurationDisplayName("Alarm Clock")
        .description("Large alarm display for StandBy mode")
        .supportedFamilies([.systemExtraLarge])
    }
}

// MARK: - Previews

#Preview("StandBy - With Alarm", as: .systemExtraLarge) {
    StandByAlarmWidget()
} timeline: {
    AlarmTimelineEntry(
        date: .now,
        upcomingAlarms: [
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Morning Wake Up",
                icon: "sunrise.fill",
                color: .orange,
                nextAlarmTime: Date().addingTimeInterval(7200),
                scheduleType: .daily,
                hour: 7,
                minute: 30,
                hasCountdown: true,
                tickerDataTitle: nil
            )
        ]
    )
}

#Preview("StandBy - No Alarm", as: .systemExtraLarge) {
    StandByAlarmWidget()
} timeline: {
    AlarmTimelineEntry(
        date: .now,
        upcomingAlarms: []
    )
}
