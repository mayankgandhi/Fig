//
//  AlarmDetailView.swift
//  fig
//
//  Detailed view showing comprehensive ticker information in a compact bottom sheet
//

import SwiftUI
import SwiftData

struct AlarmDetailView: View {
    let alarm: Ticker
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(TickerService.self) private var tickerService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.md) {
                    // Header with icon and label
                    headerSection

                    // Time display
                    timeSection

                    // Options display (using same icons as Add Ticker)
                    optionsSection
                }
                .padding(TickerSpacing.md)
                .padding(.bottom, TickerSpacing.xl)
            }
            .background(
                ZStack {
                    TickerColor.liquidGlassGradient(for: colorScheme)
                        .ignoresSafeArea()

                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.1)
                        .ignoresSafeArea()
                }
            )
            .navigationTitle("Ticker Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        TickerHaptics.selection()
                        onEdit()
                        dismiss()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    }

                    Button(role: .destructive) {
                        TickerHaptics.selection()
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: TickerSpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: iconSymbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                // Label
                Text(alarm.label)
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                // Status badge
                Text(statusLabel)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, TickerSpacing.xs)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(TickerSpacing.sm)
        .background(TickerColor.surface(for: colorScheme).opacity(0.5))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(spacing: TickerSpacing.xs) {
            if let schedule = alarm.schedule {
                Text(timeString(for: schedule))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                HStack(spacing: TickerSpacing.xxs) {
                    Image(systemName: scheduleIcon(for: schedule))
                        .font(.system(size: 12))
                    Text(scheduleTypeLabel(for: schedule))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TickerSpacing.md)
        .background(TickerColor.surface(for: colorScheme).opacity(0.5))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.xs) {
            Text("OPTIONS")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

            FlowLayout(spacing: TickerSpacing.xs) {
                // Calendar/Date option
                if let schedule = alarm.schedule {
                    optionPill(
                        icon: "calendar",
                        title: dateDisplayText(for: schedule)
                    )
                }

                // Repeat option
                if let schedule = alarm.schedule {
                    optionPill(
                        icon: "repeat",
                        title: repeatDisplayText(for: schedule)
                    )
                }

                // Label option
                optionPill(
                    icon: "tag",
                    title: alarm.label
                )

                // Countdown option
                if let countdown = alarm.countdown?.preAlert {
                    optionPill(
                        icon: "timer",
                        title: formatCountdown(countdown)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Option Pill

    private func optionPill(icon: String, title: String) -> some View {
        HStack(spacing: TickerSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
        }
        .padding(.horizontal, TickerSpacing.sm)
        .padding(.vertical, TickerSpacing.xs)
        .background(TickerColor.surface(for: colorScheme).opacity(0.7))
        .background(.ultraThinMaterial.opacity(0.3))
        .clipShape(Capsule())
    }

    // MARK: - Helper Properties

    private var iconSymbol: String {
        alarm.tickerData?.icon ?? "alarm"
    }

    private var iconColor: Color {
        if let colorHex = alarm.tickerData?.colorHex {
            return Color(hex: colorHex) ?? TickerColor.primary
        }
        return TickerColor.primary
    }

    private var statusLabel: String {
        if tickerService.getTicker(id: alarm.id) != nil {
            return "Active"
        }
        return alarm.isEnabled ? "Scheduled" : "Disabled"
    }

    private var statusColor: Color {
        if tickerService.getTicker(id: alarm.id) != nil {
            return TickerColor.scheduled
        }
        return alarm.isEnabled ? TickerColor.scheduled : TickerColor.disabled
    }

    // MARK: - Helper Methods

    private func timeString(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime(let date):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)

        case .daily(let time, _), .weekdays(let time, _, _), .biweekly(let time, _, _), .monthly(_, let time, _), .yearly(_, _, let time, _):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            var components = DateComponents()
            components.hour = time.hour
            components.minute = time.minute
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return "\(time.hour):\(String(format: "%02d", time.minute))"

        case .hourly:
            // For hourly schedules, show a generic time indicator
            return "Hourly"
        }
    }

    private func scheduleIcon(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime: return "calendar"
        case .daily: return "repeat"
        case .hourly: return "clock"
        case .weekdays: return "calendar.badge.clock"
        case .biweekly: return "calendar.badge.clock"
        case .monthly: return "calendar.circle"
        case .yearly: return "calendar.badge.exclamationmark"
        }
    }

    private func scheduleTypeLabel(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime: return "One-time ticker"
        case .daily: return "Daily ticker"
        case .hourly: return "Hourly ticker"
        case .weekdays: return "Weekly ticker"
        case .biweekly: return "Biweekly ticker"
        case .monthly: return "Monthly ticker"
        case .yearly: return "Yearly ticker"
        }
    }

    private func dateDisplayText(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime(let date):
            return date.formatted(date: .abbreviated, time: .omitted)
        case .daily:
            return "Every day"
        case .hourly(let interval, _, _):
            return "Every \(interval)h"
        case .weekdays(_, let days, _):
            let sortedDays = days.sorted { $0.rawValue < $1.rawValue }
            return sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
        case .biweekly(_, let weekdays, _):
            let sortedDays = weekdays.sorted { $0.rawValue < $1.rawValue }
            return "Biweekly " + sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
        case .monthly(let day, _, _):
            switch day {
            case .fixed(let d): return "Day \(d)"
            case .firstWeekday(let weekday): return "First \(weekday.shortDisplayName)"
            case .lastWeekday(let weekday): return "Last \(weekday.shortDisplayName)"
            case .firstOfMonth: return "1st of month"
            case .lastOfMonth: return "Last of month"
            }
        case .yearly(let month, let day, _, _):
            let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return "\(monthNames[month - 1]) \(day)"
        }
    }

    private func repeatDisplayText(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime:
            return "Once"
        case .daily:
            return "Daily"
        case .hourly:
            return "Hourly"
        case .weekdays:
            return "Weekdays"
        case .biweekly:
            return "Biweekly"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }

    private func formatCountdown(_ countdown: TickerCountdown.CountdownDuration) -> String {
        var parts: [String] = []

        if countdown.hours > 0 {
            parts.append("\(countdown.hours)h")
        }
        if countdown.minutes > 0 {
            parts.append("\(countdown.minutes)m")
        }
        if countdown.seconds > 0 {
            parts.append("\(countdown.seconds)s")
        }

        return parts.isEmpty ? "0s" : parts.joined(separator: " ")
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var tickerService = TickerService()

    AlarmDetailView(
        alarm: Ticker(
            label: "Morning Workout",
            isEnabled: true,
            schedule: 
                    .daily(
                        time: TickerSchedule.TimeOfDay(hour: 6, minute: 30),
                        startDate: .now
                    ),
            countdown: TickerCountdown(
                preAlert: TickerCountdown.CountdownDuration(hours: 0, minutes: 5, seconds: 0),
                postAlert: nil
            ),
            tickerData: TickerData(
                name: "Fitness & Health",
                icon: "figure.run",
                colorHex: "#FF6B35"
            )
        ),
        onEdit: {
},
        onDelete: {}
    )
    .environment(tickerService)
}
