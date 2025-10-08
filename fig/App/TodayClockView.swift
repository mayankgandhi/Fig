//
//  TodayClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 07/10/25.
//

import SwiftUI
import SwiftData
import WalnutDesignSystem

struct TodayClockView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Ticker> { alarm in
        alarm.isEnabled == true
    }, sort: \Ticker.createdAt) private var alarms: [Ticker]

    @State private var showSettings: Bool = false

    private var upcomingAlarms: [Ticker] {
        let now = Date()
        let next12Hours = now.addingTimeInterval(12 * 60 * 60)

        return alarms.filter { alarm in
            guard let schedule = alarm.schedule else { return false }

            switch schedule {
            case .oneTime(let date):
                return date >= now && date <= next12Hours

            case .daily(let time):
                // Check if this time occurs in the next 12 hours
                let nextOccurrence = getNextOccurrence(for: time, from: now)
                return nextOccurrence <= next12Hours
            }
        }.sorted { alarm1, alarm2 in
            let time1 = getNextAlarmTime(for: alarm1)
            let time2 = getNextAlarmTime(for: alarm2)
            return time1 < time2
        }
    }

    private var events: [ClockView.TimeBlock] {
        upcomingAlarms.compactMap { alarm -> ClockView.TimeBlock? in
            guard let schedule = alarm.schedule else { return nil }

            let (hour, minute) = extractTime(from: schedule)
            let color = extractColor(from: alarm)
            let label = alarm.displayName

            return ClockView.TimeBlock(
                id: alarm.id,
                city: label,
                hour: hour,
                minute: minute,
                color: color
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Clock View
                    ClockView(events: events)
                        .frame(height: UIScreen.main.bounds.width)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Upcoming Alarms Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Next 12 Hours")
                                .font(.title2)
                                .fontWeight(.bold)

                            Spacer()

                            Text("\(upcomingAlarms.count)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        if upcomingAlarms.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.tertiary)

                                Text("No upcoming alarms")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Text("Alarms scheduled for the next 12 hours will appear here")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(upcomingAlarms) { alarm in
                                    UpcomingAlarmRow(alarm: alarm)
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Today")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationCornerRadius(Spacing.large)
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Helper Functions

    private func extractTime(from schedule: TickerSchedule) -> (hour: Int, minute: Int) {
        switch schedule {
        case .oneTime(let date):
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            return (components.hour ?? 0, components.minute ?? 0)

        case .daily(let time):
            return (time.hour, time.minute)
        }
    }

    private func extractColor(from alarm: Ticker) -> Color {
        // Try to get color from ticker data
        if let colorHex = alarm.tickerData?.colorHex,
           let color = Color(hex: colorHex) {
            return color
        }

        // Try to get color from presentation
        if let tintHex = alarm.presentation.tintColorHex,
           let color = Color(hex: tintHex) {
            return color
        }

        // Default to accent color
        return .accentColor
    }

    private func getNextOccurrence(for time: TickerSchedule.TimeOfDay, from date: Date) -> Date {
        let calendar = Calendar.current
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

    private func getNextAlarmTime(for alarm: Ticker) -> Date {
        guard let schedule = alarm.schedule else { return Date.distantFuture }

        switch schedule {
        case .oneTime(let date):
            return date
        case .daily(let time):
            return getNextOccurrence(for: time, from: Date())
        }
    }
}

// MARK: - Upcoming Alarm Row

struct UpcomingAlarmRow: View {
    let alarm: Ticker

    private var nextAlarmTime: Date {
        guard let schedule = alarm.schedule else { return Date() }

        switch schedule {
        case .oneTime(let date):
            return date
        case .daily(let time):
            let calendar = Calendar.current
            let now = Date()
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = time.hour
            components.minute = time.minute
            components.second = 0

            guard let todayOccurrence = calendar.date(from: components) else {
                return now
            }

            if todayOccurrence <= now {
                return calendar.date(byAdding: .day, value: 1, to: todayOccurrence) ?? todayOccurrence
            }

            return todayOccurrence
        }
    }

    private var timeUntilAlarm: String {
        let interval = nextAlarmTime.timeIntervalSince(Date())
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }

    private var alarmColor: Color {
        if let colorHex = alarm.tickerData?.colorHex {
            return Color(hex: colorHex) ?? .accentColor
        }
        if let tintHex = alarm.presentation.tintColorHex {
            return Color(hex: tintHex) ?? .accentColor
        }
        return .accentColor
    }

    var body: some View {
        HStack(spacing: 16) {
            // Color indicator and icon
            ZStack {
                Circle()
                    .fill(alarmColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: alarm.tickerData?.icon ?? "alarm")
                    .font(.system(size: 22))
                    .foregroundStyle(alarmColor)
            }

            // Alarm details
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text(nextAlarmTime, style: .time)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(timeUntilAlarm)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Schedule type badge
            if let schedule = alarm.schedule {
                switch schedule {
                case .oneTime:
                    Text("Once")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                case .daily:
                    Text("Daily")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }
}

#Preview {
    TodayClockView()
        .modelContainer(for: [Ticker.self, TemplateCategory.self])
}
