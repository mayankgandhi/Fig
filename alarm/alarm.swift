//
//  alarm.swift
//  alarm
//
//  Alarm widgets for Home Screen displaying upcoming alarms
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Shared Provider

struct AlarmWidgetProvider: TimelineProvider {

    struct Entry: TimelineEntry {
        let date: Date
        let upcomingAlarms: [UpcomingAlarmPresentation]
    }

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

            // Generate timeline entries for the next hour, updating every minute
            var entries: [Entry] = []
            for minuteOffset in stride(from: 0, through: 60, by: 1) {
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

    private func fetchUpcomingAlarms() async -> [UpcomingAlarmPresentation] {
        // Create ModelContainer for SwiftData access with App Groups support
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

        // Filter for upcoming alarms (next 24 hours)
        let now = Date()
        let next24Hours = now.addingTimeInterval(24 * 60 * 60)
        let calendar = Calendar.current

        let upcomingAlarms = alarms.compactMap { alarm -> UpcomingAlarmPresentation? in
            guard let schedule = alarm.schedule else { return nil }

            let nextAlarmTime: Date

            switch schedule {
            case .oneTime(let date):
                guard date >= now && date <= next24Hours else { return nil }
                nextAlarmTime = date

            case .daily(let time, _):
                let nextOccurrence = getNextOccurrence(for: time, from: now, calendar: calendar)
                guard nextOccurrence <= next24Hours else { return nil }
                nextAlarmTime = nextOccurrence

            case .hourly, .weekdays, .biweekly, .monthly, .yearly, .every:
                // For composite schedules, skip in widgets for simplicity
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
                baseAlarmId: alarm.id,
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

// MARK: - Next Alarm Widget (Small)

struct NextAlarmWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: AlarmWidgetProvider.Entry

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
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(nextAlarm.color.opacity(0.8))
                        .offset(y: -2)
                }

                // Alarm info
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: nextAlarm.icon)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                        Text(nextAlarm.displayName)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
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
    let entry: AlarmWidgetProvider.Entry

    var body: some View {
        if !entry.upcomingAlarms.isEmpty {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Upcoming Alarms")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
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
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
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
    let entry: AlarmWidgetProvider.Entry

    var body: some View {
        if !entry.upcomingAlarms.isEmpty {
            VStack(spacing: 0) {
                // Header with stats
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upcoming Alarms")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                        HStack(spacing: 4) {
                            Text("\(entry.upcomingAlarms.count)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(TickerColor.primary)

                            Text("scheduled")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        }
                    }

                    Spacer()

                    // Next alarm indicator
                    if let nextAlarm = entry.upcomingAlarms.first {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Next")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                            Text(nextAlarm.timeUntilAlarm(from: entry.date))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
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
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                    Text("Tap to add a new alarm")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
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

// MARK: - Alarm Row Components

struct AlarmRow: View {
    let alarm: UpcomingAlarmPresentation
    let currentDate: Date
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(alarm.color)

                    Text(alarm.hour < 12 ? "AM" : "PM")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(alarm.color.opacity(0.7))
                }

                Text(alarm.timeUntilAlarm(from: currentDate))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
            }

            Spacer()

            // Alarm info
            HStack(spacing: 6) {
                Image(systemName: alarm.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(alarm.color)

                Text(alarm.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
        )
    }
}

struct CompactAlarmRow: View {
    let alarm: UpcomingAlarmPresentation
    let currentDate: Date
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 8) {
            // Time
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(alarm.color)

                Text(alarm.hour < 12 ? "AM" : "PM")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(alarm.color.opacity(0.7))
            }

            Spacer()

            // Alarm info
            HStack(spacing: 4) {
                Image(systemName: alarm.icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(alarm.color)

                Text(alarm.displayName)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground).opacity(0.4))
        )
    }
}

struct DetailedAlarmRow: View {
    let alarm: UpcomingAlarmPresentation
    let currentDate: Date
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon and color indicator
            ZStack {
                Circle()
                    .fill(alarm.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: alarm.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(alarm.color)
            }

            // Alarm details
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text(alarm.scheduleType.badgeText)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(alarm.scheduleType.badgeColor)
                        )

                    if alarm.hasCountdown {
                        Image(systemName: "timer")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    }
                }
            }

            // Time and countdown - Fixed width for consistent alignment
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(String(format: "%d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(alarm.color)

                    Text(alarm.hour < 12 ? "AM" : "PM")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(alarm.color.opacity(0.7))
                }

                Text(alarm.timeUntilAlarm(from: currentDate))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(alarm.color.opacity(0.8))
                    .multilineTextAlignment(.trailing)
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
        )
    }
}

// MARK: - Previews

#Preview("Next Alarm - Small", as: .systemSmall) {
    NextAlarmWidget()
} timeline: {
    AlarmWidgetProvider.Entry(
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
    AlarmWidgetProvider.Entry(
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
    AlarmWidgetProvider.Entry(
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
