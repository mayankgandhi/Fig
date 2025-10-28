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
            timeWindowMinutes: 60,
            alarmTimeWindowHours: 24,
            alarmLimit: nil
        )
    }
}

// MARK: - Clock Widget View

struct ClockWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily
    let entry: AlarmTimelineEntry

    var body: some View {
        ZStack {
            // Clock face centered in the widget
            ClockFaceView(
                currentDate: entry.date,
                upcomingAlarms: entry.upcomingAlarms,
                shouldAnimateAlarms: false,
                showSecondsHand: false,
                showAlarmLabels: widgetFamily != .systemSmall
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(widgetFamily == .systemSmall ? 2 : 4)
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
        .configurationDisplayName("Clock with Tickers")
        .description("View your upcoming alarms on a clock face")
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}

// MARK: - Previews

private let sampleAlarms = [
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

#Preview("Clock - Small", as: .systemSmall) {
    ClockWidget()
} timeline: {
    AlarmTimelineEntry(date: .now, upcomingAlarms: sampleAlarms)
}

#Preview("Clock - Medium", as: .systemMedium) {
    ClockWidget()
} timeline: {
    AlarmTimelineEntry(date: .now, upcomingAlarms: sampleAlarms)
}

#Preview("Clock - Large", as: .systemLarge) {
    ClockWidget()
} timeline: {
    AlarmTimelineEntry(date: .now, upcomingAlarms: sampleAlarms)
}
