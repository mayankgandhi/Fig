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
import TickerCore
import Gate

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

    // Check subscription status
    private var hasAccess: Bool {
        // Always show content in widget gallery previews (snapshots/placeholders)
        if entry.isPreview {
            return true
        }
        
        
        return SubscriptionService.shared.isSubscribed
    }

    var body: some View {
        if hasAccess {
            widgetContent
        } else {
            // Show premium gate view
            WidgetPremiumGateView(feature: .accountabilityWidgets)
        }
    }

    @ViewBuilder
    private var widgetContent: some View {
        if let nextAlarm = entry.upcomingAlarms.first {
            VStack(spacing: TickerSpacing.xs) {
                // Icon with ticker color
                ZStack {
                    Circle()
                        .fill(nextAlarm.color.opacity(colorScheme == .dark ? 0.2 : 0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: nextAlarm.icon)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundStyle(nextAlarm.color)
                }
                
                // Alarm name
                Text(nextAlarm.displayName)
                    .Title3()
                    .fontWeight(.medium)
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                VStack(spacing: TickerSpacing.xxs) {
                    
                    // Time display with ticker color
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(String(format: "%d", nextAlarm.hour % 12 == 0 ? 12 : nextAlarm.hour % 12))
                            .Title()
                            .bold()
                            .foregroundStyle(nextAlarm.color)
                        
                        Text(":")
                            .Title()
                            .bold()
                            .foregroundStyle(nextAlarm.color.opacity(0.6))
                        
                        Text(String(format: "%02d", nextAlarm.minute))
                            .Title()
                            .bold()
                            .foregroundStyle(nextAlarm.color)
                        
                        Text(nextAlarm.hour < 12 ? "AM" : "PM")
                            .Subheadline()
                            .fontWeight(.semibold)
                            .foregroundStyle(nextAlarm.color.opacity(0.8))
                    }
                    
                    // Countdown
                    Text(nextAlarm.timeUntilAlarm(from: entry.date))
                        .Caption2()
                        .fontWeight(.medium)
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .lineLimit(1)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
            .padding(TickerSpacing.xxs)
            .containerBackground(for: .widget) {
                TickerColor.liquidGlassGradient(for: colorScheme)
            }
        } else {
            // No alarms
            VStack(spacing: TickerSpacing.sm) {
                Image(systemName: "alarm")
                    .font(.system(.title2, design: .rounded, weight: .regular))
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                
                Text("No Tickers")
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Alarm List Widget (Medium)

struct AlarmListWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: AlarmTimelineEntry

    // Check subscription status
    private var hasAccess: Bool {
        // Always show content in widget gallery previews (snapshots/placeholders)
        if entry.isPreview {
            return true
        }
        
        
        return SubscriptionService.shared.isSubscribed
    }

    var body: some View {
        if hasAccess {
            widgetContent
        } else {
            // Show premium gate view
            WidgetPremiumGateView(feature: .accountabilityWidgets)
        }
    }

    @ViewBuilder
    private var widgetContent: some View {
        if !entry.upcomingAlarms.isEmpty {
            VStack(spacing: TickerSpacing.xs) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upcoming Tickers")
                            .Headline()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        
                        Text("\(entry.upcomingAlarms.count) scheduled")
                            .Subheadline()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "alarm.fill")
                        .Headline()
                        .foregroundStyle(TickerColor.primary)
                }
                
                // Alarm list (show up to 3 for better fit)
                HStack(spacing: TickerSpacing.sm) {
                    ForEach(entry.upcomingAlarms.prefix(3)) { alarm in
                        CompactAlarmRow(alarm: alarm, currentDate: entry.date, colorScheme: colorScheme)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(TickerSpacing.xs)
            .containerBackground(for: .widget) {
                TickerColor.liquidGlassGradient(for: colorScheme)
            }
        } else {
            // No alarms
            VStack(spacing: TickerSpacing.sm) {
                Image(systemName: "alarm")
                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
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

    // Check subscription status
    private var hasAccess: Bool {
        // Always show content in widget gallery previews (snapshots/placeholders)
        if entry.isPreview {
            return true
        }
        
        
        return SubscriptionService.shared.isSubscribed
    }

    var body: some View {
        if hasAccess {
            widgetContent
        } else {
            // Show premium gate view
            WidgetPremiumGateView(feature: .accountabilityWidgets)
        }
    }

    @ViewBuilder
    private var widgetContent: some View {
        if !entry.upcomingAlarms.isEmpty {
            VStack(spacing: TickerSpacing.xs) {
                // Header with stats
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Upcoming Tickers")
                            .TickerTitle()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        
                        Text("\(entry.upcomingAlarms.count) scheduled")
                                .Footnote()
                                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    // Next alarm indicator with ticker color
                    if let nextAlarm = entry.upcomingAlarms.first {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Next")
                                .Caption2()
                                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                            
                            Text(nextAlarm.timeUntilAlarm(from: entry.date))
                                .ButtonText()
                                .fontWeight(.semibold)
                                .foregroundStyle(nextAlarm.color)
                        }
                    }
                }
                
                Divider()
                
                // Alarm list (show up to 5)
                VStack(spacing: TickerSpacing.xs) {
                    ForEach(entry.upcomingAlarms.prefix(5)) { alarm in
                        DetailedAlarmRow(alarm: alarm, currentDate: entry.date, colorScheme: colorScheme)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
            .padding(TickerSpacing.xxs)
            .containerBackground(for: .widget) {
                TickerColor.liquidGlassGradient(for: colorScheme)
            }
        } else {
            // No alarms
            VStack(spacing: TickerSpacing.md) {
                Image(systemName: "alarm")
                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
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
        .configurationDisplayName("Detailed Tickers")
        .description("Shows detailed view of your upcoming Tickers")
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
                displayName: "Morning Run On the Kheda",
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

#Preview("Next Alarm - Small", as: .systemMedium) {
    NextAlarmWidget()
} timeline: {
    AlarmTimelineEntry(
        date: .now,
        upcomingAlarms: [
            UpcomingAlarmPresentation(
                baseAlarmId: UUID(),
                displayName: "Morning Run On the Kheda",
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
                displayName: "Run",
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
