//
//  ClockWidget.swift
//  alarm
//
//  Clock widget displaying upcoming alarms on a clock face
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Clock Widget Provider

struct ClockWidgetProvider: TimelineProvider {

    // MARK: - Timeline Entry

    struct Entry: TimelineEntry {
        let date: Date
        let upcomingAlarms: [UpcomingAlarmPresentation]
    }

    // MARK: - Provider Methods

    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), upcomingAlarms: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = Entry(date: Date(), upcomingAlarms: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let calendar = Calendar.current
            let currentDate = Date()

            // Calculate the start of the next minute
            let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
            guard let currentMinute = calendar.date(from: currentComponents),
                  let nextMinute = calendar.date(byAdding: .minute, value: 1, to: currentMinute) else {
                let entry = Entry(date: currentDate, upcomingAlarms: [])
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
                return
            }

            let upcomingAlarms = await fetchUpcomingAlarms()

            // Generate timeline entries
            var entries: [Entry] = []

            // Create entries for the next 2 hours, updating every minute
            for minuteOffset in stride(from: 0, through: 120, by: 1) {
                let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: nextMinute)!
                let entry = Entry(date: entryDate, upcomingAlarms: upcomingAlarms)
                entries.append(entry)
            }

            // Update policy: Refresh after the last entry
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }

    // MARK: - Data Fetching

    @MainActor
    private func fetchUpcomingAlarms() async -> [UpcomingAlarmPresentation] {
        // Create ModelContainer for SwiftData access with App Groups support
        // This ensures we get the latest data from the shared container
        let schema = Schema([Ticker.self])
        
        // Try to use shared container first, fallback to local if not available
        let modelConfiguration: ModelConfiguration
        if let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.m.fig") {
            modelConfiguration = ModelConfiguration(schema: schema, url: sharedURL.appendingPathComponent("Ticker.sqlite"))
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        guard let modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            return []
        }

        let context = ModelContext(modelContainer)

        // Fetch all enabled alarms
        let descriptor = FetchDescriptor<Ticker>(
            predicate: #Predicate { $0.isEnabled },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let alarms = try? context.fetch(descriptor) else {
            return []
        }

        // Filter for upcoming alarms (next 12 hours)
        let now = Date()
        let next12Hours = now.addingTimeInterval(12 * 60 * 60)
        let calendar = Calendar.current

        let upcomingAlarms = alarms.compactMap { alarm -> UpcomingAlarmPresentation? in
            guard let schedule = alarm.schedule else { return nil }

            let nextAlarmTime: Date

            switch schedule {
            case .oneTime(let date):
                guard date >= now && date <= next12Hours else { return nil }
                nextAlarmTime = date

            case .daily(let time, _):
                let nextOccurrence = getNextOccurrence(for: time, from: now, calendar: calendar)
                guard nextOccurrence <= next12Hours else { return nil }
                nextAlarmTime = nextOccurrence

            case .hourly, .weekdays, .biweekly, .monthly, .yearly, .every:
                // For composite schedules, we could expand them, but for simplicity
                // we'll skip them in the widget for now
                return nil
            }

            let hour = calendar.component(.hour, from: nextAlarmTime)
            let minute = calendar.component(.minute, from: nextAlarmTime)

            let scheduleType: UpcomingAlarmPresentation.ScheduleType = {
                switch schedule {
                case .oneTime: return .oneTime
                case .daily: return .daily
                default: return .oneTime
                }
            }()

            return UpcomingAlarmPresentation(
                id: alarm.id,
                displayName: alarm.displayName,
                icon: alarm.tickerData?.icon ?? "alarm",
                color: extractColor(from: alarm),
                nextAlarmTime: nextAlarmTime,
                scheduleType: scheduleType,
                hour: hour,
                minute: minute,
                hasCountdown: alarm.countdown?.preAlert != nil,
                tickerDataTitle: alarm.tickerData?.name
            )
        }
        .sorted { $0.nextAlarmTime < $1.nextAlarmTime }

        return upcomingAlarms
    }

    private func getNextOccurrence(for time: TickerSchedule.TimeOfDay, from date: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0

        guard let todayOccurrence = calendar.date(from: components) else {
            return date
        }

        // If today's occurrence has passed, return tomorrow's
        if todayOccurrence <= date {
            return calendar.date(byAdding: .day, value: 1, to: todayOccurrence) ?? todayOccurrence
        }

        return todayOccurrence
    }

    private func extractColor(from alarm: Ticker) -> Color {
        // Try ticker data first
        if let colorHex = alarm.tickerData?.colorHex,
           let color = Color(hex: colorHex) {
            return color
        }

        // Try presentation tint
        if let tintHex = alarm.presentation.tintColorHex,
           let color = Color(hex: tintHex) {
            return color
        }

        // Default to accent
        return .accentColor
    }
}

// MARK: - Clock Widget View

struct ClockWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: ClockWidgetProvider.Entry

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

// MARK: - Preview

#Preview(as: .systemMedium) {
    ClockWidget()
} timeline: {
    ClockWidgetProvider.Entry(
        date: .now,
        upcomingAlarms: [
            UpcomingAlarmPresentation(
                id: UUID(),
                displayName: "Morning Alarm",
                icon: "sunrise.fill",
                color: .orange,
                nextAlarmTime: Date().addingTimeInterval(3600),
                scheduleType: .daily,
                hour: 8,
                minute: 0,
                hasCountdown: false,
                tickerDataTitle: nil
            ),
            UpcomingAlarmPresentation(
                id: UUID(),
                displayName: "Lunch",
                icon: "fork.knife",
                color: .green,
                nextAlarmTime: Date().addingTimeInterval(7200),
                scheduleType: .daily,
                hour: 12,
                minute: 0,
                hasCountdown: true,
                tickerDataTitle: "Lunch Break"
            )
        ]
    )
}
