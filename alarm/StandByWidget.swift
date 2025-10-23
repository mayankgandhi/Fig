//
//  StandByWidget.swift
//  alarm
//
//  StandBy mode widget optimized for nightstand viewing
//  Large, high-contrast design for distance viewing
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - StandBy Widget Provider

struct StandByWidgetProvider: TimelineProvider {

    struct Entry: TimelineEntry {
        let date: Date
        let nextAlarm: UpcomingAlarmPresentation?
    }

    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), nextAlarm: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = Entry(date: Date(), nextAlarm: nil)
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
                let entry = Entry(date: currentDate, nextAlarm: nil)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
                return
            }

            let nextAlarm = await fetchNextAlarm()

            // Generate timeline entries for the next 30 minutes, updating every minute
            var entries: [Entry] = []
            for minuteOffset in stride(from: 0, through: 30, by: 1) {
                let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: nextMinute)!
                let entry = Entry(date: entryDate, nextAlarm: nextAlarm)
                entries.append(entry)
            }

            // Update policy: Refresh after the last entry
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }

    // MARK: - Data Fetching

    @MainActor
    private func fetchNextAlarm() async -> UpcomingAlarmPresentation? {
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
            return nil
        }

        let context = ModelContext(modelContainer)

        // Fetch all enabled alarms
        let descriptor = FetchDescriptor<Ticker>(
            predicate: #Predicate { $0.isEnabled },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let alarms = try? context.fetch(descriptor) else {
            return nil
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
                // For composite schedules, skip for simplicity
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

        return upcomingAlarms.first
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

// MARK: - StandBy Widget View

struct StandByWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: StandByWidgetProvider.Entry

    var body: some View {
        if let alarm = entry.nextAlarm {
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
    StandByWidgetProvider.Entry(
        date: .now,
        nextAlarm: UpcomingAlarmPresentation(
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
    )
}

#Preview("StandBy - No Alarm", as: .systemExtraLarge) {
    StandByAlarmWidget()
} timeline: {
    StandByWidgetProvider.Entry(
        date: .now,
        nextAlarm: nil
    )
}
