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

            // Large widget: Full layout with detailed ticker list
            VStack(spacing: 16) {
                // Enhanced header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upcoming Alarms")
                            .ButtonText()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                        Text("\(entry.upcomingAlarms.count) scheduled")
                            .Caption2()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    // Next alarm indicator with enhanced styling
                    if let nextAlarm = entry.upcomingAlarms.first {
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .SmallText()
                                    .foregroundStyle(nextAlarm.color)

                                Text("Next")
                                    .Caption2()
                                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                            }

                            Text(nextAlarm.timeUntilAlarm(from: entry.date))
                                .SmallText()
                                .foregroundStyle(nextAlarm.color)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(nextAlarm.color.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(nextAlarm.color.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Clock and ticker list layout
                HStack(spacing: 16) {
                    // Clock view - optimized for large widget, uses ClockFaceView for proper updates
                    ClockFaceView(
                        currentDate: entry.date,
                        upcomingAlarms: entry.upcomingAlarms,
                        shouldAnimateAlarms: false,
                        showSecondsHand: false
                    )
                    .frame(width: 120, height: 120)

                    // Detailed ticker list
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(entry.upcomingAlarms.prefix(4).enumerated()), id: \.element.id) { index, alarm in
                            DetailedAlarmRow(
                                alarm: alarm,
                                currentDate: entry.date,
                                colorScheme: colorScheme
                            )
                            .scaleEffect(0.9) // Slightly smaller for widget
                        }

                        if entry.upcomingAlarms.count > 4 {
                            HStack {
                                Spacer()
                                Text("+\(entry.upcomingAlarms.count - 4) more")
                                    .Caption2()
                                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(TickerColor.textTertiary(for: colorScheme).opacity(0.2))
                                    )
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
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
        .configurationDisplayName("Clock with Alarms")
        .description("View your upcoming alarms on a clock face with detailed list")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Previews

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
