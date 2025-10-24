//
//  AlarmWidgets.swift
//  alarm
//
//  Home Screen widgets displaying upcoming alarms
//  Refactored to use shared components and reduce duplication
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Shared Provider

struct AlarmWidgetProvider: TimelineProvider {

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
            timeWindowMinutes: 60,
            alarmTimeWindowHours: 24,
            alarmLimit: nil
        )
    }
}

// MARK: - Next Alarm Widget (Small)

struct NextAlarmWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: AlarmTimelineEntry

    var body: some View {
        if let nextAlarm = entry.upcomingAlarms.first {
            VStack(spacing: 6) {
                // Time display
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%d", nextAlarm.hour % 12 == 0 ? 12 : nextAlarm.hour % 12))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(nextAlarm.color)

                    Text(":")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(nextAlarm.color.opacity(0.7))

                    Text(String(format: "%02d", nextAlarm.minute))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(nextAlarm.color)

                    Text(nextAlarm.hour < 12 ? "AM" : "PM")
                        .ButtonText()
                        .foregroundStyle(nextAlarm.color.opacity(0.8))
                        .offset(y: -2)
                }

                // Alarm info
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: nextAlarm.icon)
                            .Caption2()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                        Text(nextAlarm.displayName)
                            .Caption2()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Text(nextAlarm.timeUntilAlarm(from: entry.date))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .containerBackground(for: .widget) {
                TickerColor.liquidGlassGradient(for: colorScheme)
            }
        } else {
            // No alarms
            VStack(spacing: 8) {
                Image(systemName: "alarm")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                Text("No Alarms")
                    .ButtonText()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                TickerColor.liquidGlassGradient(for: colorScheme)
            }
        }
    }
}

struct NextAlarmWidget: Widget {
    let kind: String = "NextAlarmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AlarmWidgetProvider()) { entry in
            NextAlarmWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Alarm")
        .description("Shows your next upcoming alarm")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Alarm List Widget (Medium)

struct AlarmListWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: AlarmTimelineEntry

    var body: some View {
        if !entry.upcomingAlarms.isEmpty {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Upcoming Alarms")
                            .SmallText()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                        Text("\(entry.upcomingAlarms.count) scheduled")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "alarm.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TickerColor.primary)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)

                // Alarm list (show up to 2 for better fit)
                VStack(spacing: 6) {
                    ForEach(entry.upcomingAlarms.prefix(2)) { alarm in
                        CompactAlarmRow(alarm: alarm, currentDate: entry.date, colorScheme: colorScheme)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                TickerColor.liquidGlassGradient(for: colorScheme)
            }
        } else {
            // No alarms
            VStack(spacing: 12) {
                Image(systemName: "alarm")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                Text("No Alarms Scheduled")
                    .ButtonText()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                TickerColor.liquidGlassGradient(for: colorScheme)
            }
        }
    }
}

struct AlarmListWidget: Widget {
    let kind: String = "AlarmListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AlarmWidgetProvider()) { entry in
            AlarmListWidgetView(entry: entry)
        }
        .configurationDisplayName("Alarm List")
        .description("Shows your upcoming alarms in a list")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Detailed Alarm List Widget (Large)

struct DetailedAlarmListWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: AlarmTimelineEntry

    var body: some View {
        if !entry.upcomingAlarms.isEmpty {
            VStack(spacing: 0) {
                // Header with stats
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upcoming Alarms")
                            .TickerTitle()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                        HStack(spacing: 4) {
                            Text("\(entry.upcomingAlarms.count)")
                                .Footnote()
                                .foregroundStyle(TickerColor.primary)

                            Text("scheduled")
                                .Footnote()
                                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        }
                    }

                    Spacer()

                    // Next alarm indicator
                    if let nextAlarm = entry.upcomingAlarms.first {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Next")
                                .Caption2()
                                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                            Text(nextAlarm.timeUntilAlarm(from: entry.date))
                                .ButtonText()
                                .foregroundStyle(nextAlarm.color)
                        }
                        .frame(width: 80, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Alarm list (show up to 6)
                VStack(spacing: 10) {
                    ForEach(entry.upcomingAlarms.prefix(6)) { alarm in
                        DetailedAlarmRow(alarm: alarm, currentDate: entry.date, colorScheme: colorScheme)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                TickerColor.liquidGlassGradient(for: colorScheme)
            }
        } else {
            // No alarms
            VStack(spacing: 16) {
                Image(systemName: "alarm")
                    .font(.system(size: 60, weight: .regular))
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                VStack(spacing: 4) {
                    Text("No Alarms Scheduled")
                        .TickerTitle()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                    Text("Tap to add a new alarm")
                        .DetailText()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                TickerColor.liquidGlassGradient(for: colorScheme)
            }
        }
    }
}

struct DetailedAlarmListWidget: Widget {
    let kind: String = "DetailedAlarmListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AlarmWidgetProvider()) { entry in
            DetailedAlarmListWidgetView(entry: entry)
        }
        .configurationDisplayName("Detailed Alarms")
        .description("Shows detailed view of your upcoming alarms")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Previews

#Preview("Next Alarm - Small", as: .systemSmall) {
    NextAlarmWidget()
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
            )
        ]
    )
}

#Preview("Alarm List - Medium", as: .systemMedium) {
    AlarmListWidget()
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
                tickerDataTitle: nil
            ),
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Meeting",
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
                displayName: "Dinner",
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

#Preview("Detailed List - Large", as: .systemLarge) {
    DetailedAlarmListWidget()
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
                tickerDataTitle: nil
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
            ),
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Bedtime",
                icon: "bed.double.fill",
                color: .purple,
                nextAlarmTime: Date().addingTimeInterval(32400),
                scheduleType: .daily,
                hour: 22,
                minute: 0,
                hasCountdown: true,
                tickerDataTitle: nil
            )
        ]
    )
}
