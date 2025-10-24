//
//  ClockWidget.swift
//  alarm
//
//  Clock widget displaying upcoming alarms on a clock face
//  Refactored to use shared components
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Clock Widget Provider

struct ClockWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> AlarmTimelineEntry {
        BaseTimelineProvider.createPlaceholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (AlarmTimelineEntry) -> Void) {
        completion(BaseTimelineProvider.createSnapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AlarmTimelineEntry>) -> Void) {
        BaseTimelineProvider.generateTimeline(
            in: context,
            completion: completion,
            timeWindowMinutes: 120,
            alarmTimeWindowHours: 12,
            alarmLimit: nil
        )
    }
}

// MARK: - Clock Widget View

struct ClockWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: AlarmTimelineEntry

    var body: some View {
        ZStack {
            // Enhanced background with glassmorphism
            TickerColor.liquidGlassGradient(for: colorScheme)
                .ignoresSafeArea()

            // Subtle overlay for depth
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                    Color.clear,
                    Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Header with upcoming alarms count
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upcoming Alarms")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                        Text("\(entry.upcomingAlarms.count) scheduled")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    // Next alarm indicator
                    if let nextAlarm = entry.upcomingAlarms.first {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Next")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                            Text(nextAlarm.timeUntilAlarm(from: entry.date))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(nextAlarm.color)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Enhanced clock view
                ClockView(upcomingAlarms: entry.upcomingAlarms, shouldAnimateAlarms: false, showSecondsHand: false)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .containerBackground(for: .widget) {
            TickerColor.liquidGlassGradient(for: colorScheme)
        }
    }
}

// MARK: - Clock Widget Configuration

struct ClockWidget: Widget {
    let kind: String = "ClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockWidgetProvider()) { entry in
            ClockWidgetView(entry: entry)
        }
        .configurationDisplayName("Clock")
        .description("View your upcoming alarms on a clock face")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview("Clock - Medium", as: .systemMedium) {
    ClockWidget()
} timeline: {
    AlarmTimelineEntry(
        date: .now,
        upcomingAlarms: [
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Morning Run",
                icon: "figure.run",
                color: .orange,
                nextAlarmTime: Date().addingTimeInterval(7200),
                scheduleType: .daily,
                hour: 7,
                minute: 30,
                hasCountdown: true,
                tickerDataTitle: "Exercise"
            ),
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Team Meeting",
                icon: "briefcase.fill",
                color: .blue,
                nextAlarmTime: Date().addingTimeInterval(14400),
                scheduleType: .oneTime,
                hour: 14,
                minute: 0,
                hasCountdown: false,
                tickerDataTitle: nil
            )
        ]
    )
}

#Preview("Clock - Large", as: .systemLarge) {
    ClockWidget()
} timeline: {
    AlarmTimelineEntry(
        date: .now,
        upcomingAlarms: [
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Morning Run",
                icon: "figure.run",
                color: .orange,
                nextAlarmTime: Date().addingTimeInterval(7200),
                scheduleType: .daily,
                hour: 7,
                minute: 30,
                hasCountdown: true,
                tickerDataTitle: "Exercise"
            ),
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Team Meeting",
                icon: "briefcase.fill",
                color: .blue,
                nextAlarmTime: Date().addingTimeInterval(14400),
                scheduleType: .oneTime,
                hour: 14,
                minute: 0,
                hasCountdown: false,
                tickerDataTitle: nil
            ),
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Dinner Time",
                icon: "fork.knife",
                color: .red,
                nextAlarmTime: Date().addingTimeInterval(21600),
                scheduleType: .daily,
                hour: 18,
                minute: 0,
                hasCountdown: false,
                tickerDataTitle: nil
            )
        ]
    )
}

#Preview("Clock - No Alarms", as: .systemMedium) {
    ClockWidget()
} timeline: {
    AlarmTimelineEntry(
        date: .now,
        upcomingAlarms: []
    )
}
