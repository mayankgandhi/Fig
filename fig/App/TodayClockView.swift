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
    @Environment(\.colorScheme) private var colorScheme
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
                    VStack(alignment: .leading, spacing: TickerSpacing.md) {
                        HStack {
                            Text("Next 12 Hours")
                                .cabinetTitle()
                                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                            Spacer()

                            Text("\(upcomingAlarms.count)")
                                .cabinetTitle2()
                                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                        }
                        .padding(.horizontal, TickerSpacing.md)
                        .padding(.top, TickerSpacing.lg)

                        if upcomingAlarms.isEmpty {
                            VStack(spacing: TickerSpacing.sm) {
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.system(size: 64))
                                    .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                                Text("No upcoming alarms")
                                    .cabinetTitle2()
                                    .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                                Text("Alarms scheduled for the next 12 hours will appear here")
                                    .cabinetFootnote()
                                    .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, TickerSpacing.xxl)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TickerSpacing.xxl)
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
            .background(
                ZStack {
                    TickerColors.liquidGlassGradient(for: colorScheme)
                        .ignoresSafeArea()

                    // Subtle overlay for glass effect
                    Rectangle()
                        .fill(.ultraThinMaterial)
.opacity(0.1)
                        .ignoresSafeArea()
                }
            )
            .navigationTitle("Today")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        TickerHaptics.selection()
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationCornerRadius(TickerRadius.large)
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
    @Environment(\.colorScheme) private var colorScheme

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
        HStack(spacing: TickerSpacing.md) {
            // Color indicator and icon
            ZStack {
                Circle()
                    .fill(alarmColor.opacity(0.15))
                    .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)

                Image(systemName: alarm.tickerData?.icon ?? "alarm")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(alarmColor)
            }

            // Alarm details
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(alarm.displayName)
                    .cabinetTitle3()
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                HStack(spacing: TickerSpacing.xs) {
                    Text(nextAlarmTime, style: .time)
                        .cabinetSubheadline()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                    Text("•")
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text(timeUntilAlarm)
                        .cabinetSubheadline()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                }
            }

            Spacer()

            // Schedule type badge
            if let schedule = alarm.schedule {
                switch schedule {
                case .oneTime:
                    Text("Once")
                        .tickerStatusBadge(color: TickerColors.scheduled)
                case .daily:
                    Text("Daily")
                        .tickerStatusBadge(color: TickerColors.running)
                }
            }
        }
        .padding(TickerSpacing.md)
        .background(TickerColors.background(for: colorScheme))
    }
}

#Preview {
    TodayClockView()
        .modelContainer(for: [Ticker.self, TemplateCategory.self])
}
