//
//  AlarmDetailView.swift
//  fig
//
//  Detailed view showing comprehensive alarm information
//

import SwiftUI
import SwiftData

struct AlarmDetailView: View {
    let alarm: Ticker
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleEnabled: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AlarmService.self) private var alarmService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.lg) {
                    // Header with icon and label
                    headerSection

                    // Time display
                    timeSection

                    // Schedule details
                    scheduleSection

                    // Countdown section
                    if alarm.countdown?.preAlert != nil {
                        countdownSection
                    }

                    // Notes section
                    if let notes = alarm.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }

                    // Metadata section
                    metadataSection

                    // Action buttons
                    actionButtonsSection
                }
                .padding(TickerSpacing.md)
            }
            .background(
                ZStack {
                    TickerColors.liquidGlassGradient(for: colorScheme)
                        .ignoresSafeArea()

                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.1)
                        .ignoresSafeArea()
                }
            )
            .navigationTitle("Alarm Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: TickerSpacing.md) {
            // Large icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: iconSymbol)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            // Label
            Text(alarm.label)
                .cabinetLargeTitle()
                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                .multilineTextAlignment(.center)

            // Status badge
            Text(statusLabel)
                .tickerStatusBadge(color: statusColor)
        }
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(spacing: TickerSpacing.sm) {
            if let schedule = alarm.schedule {
                Text(timeString(for: schedule))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                HStack(spacing: TickerSpacing.xxs) {
                    Image(systemName: scheduleIcon(for: schedule))
                        .font(.system(size: 14))
                    Text(scheduleTypeLabel(for: schedule))
                        .cabinetSubheadline()
                }
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(TickerSpacing.md)
        .background(TickerColors.surface(for: colorScheme).opacity(0.95))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            Text("Schedule")
                .cabinetHeadline()
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

            if let schedule = alarm.schedule {
                HStack {
                    Image(systemName: scheduleIcon(for: schedule))
                        .font(.system(size: 16))
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                    Text(scheduleDescription(for: schedule))
                        .cabinetBody()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TickerSpacing.md)
        .background(TickerColors.surface(for: colorScheme).opacity(0.95))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Countdown Section

    private var countdownSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            Text("Countdown")
                .cabinetHeadline()
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

            if let countdown = alarm.countdown?.preAlert {
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 16))
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                    Text(formatCountdown(countdown))
                        .cabinetBody()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                    Spacer()

                    Text("before alarm")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TickerSpacing.md)
        .background(TickerColors.surface(for: colorScheme).opacity(0.95))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            Text("Notes")
                .cabinetHeadline()
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

            Text(notes)
                .cabinetBody()
                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TickerSpacing.md)
        .background(TickerColors.surface(for: colorScheme).opacity(0.95))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            Text("Details")
                .cabinetHeadline()
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

            // Category
            if let tickerData = alarm.tickerData, let name = tickerData.name, name != alarm.label {
                HStack {
                    Text("Category")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Spacer()

                    Text(name)
                        .cabinetBody()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                }
            }

            // Created date
            HStack {
                Text("Created")
                    .cabinetFootnote()
                    .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                Spacer()

                Text(alarm.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .cabinetBody()
                    .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TickerSpacing.md)
        .background(TickerColors.surface(for: colorScheme).opacity(0.95))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: TickerSpacing.sm) {
            // Enable/Disable toggle
            Button {
                TickerHaptics.selection()
                onToggleEnabled()
            } label: {
                HStack {
                    Image(systemName: alarm.isEnabled ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(alarm.isEnabled ? "Disable Alarm" : "Enable Alarm")
                        .cabinetHeadline()
                }
                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, TickerSpacing.md)
                .background(TickerColors.surface(for: colorScheme).opacity(0.95))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            // Edit button
            Button {
                TickerHaptics.selection()
                onEdit()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Edit Alarm")
                        .cabinetHeadline()
                }
                .foregroundStyle(TickerColors.absoluteWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TickerSpacing.md)
                .background(TickerColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
                .shadow(color: TickerColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            // Delete button
            Button(role: .destructive) {
                TickerHaptics.selection()
                onDelete()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Delete Alarm")
                        .cabinetHeadline()
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TickerSpacing.md)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }

    // MARK: - Helper Properties

    private var iconSymbol: String {
        alarm.tickerData?.icon ?? "alarm"
    }

    private var iconColor: Color {
        if let colorHex = alarm.tickerData?.colorHex {
            return Color(hex: colorHex) ?? TickerColors.primary
        }
        return TickerColors.primary
    }

    private var statusLabel: String {
        if alarmService.getTicker(id: alarm.id) != nil {
            return "Active"
        }
        return alarm.isEnabled ? "Scheduled" : "Disabled"
    }

    private var statusColor: Color {
        if alarmService.getTicker(id: alarm.id) != nil {
            return TickerColors.scheduled
        }
        return alarm.isEnabled ? TickerColors.scheduled : TickerColors.disabled
    }

    // MARK: - Helper Methods

    private func timeString(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime(let date):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)

        case .daily(let time):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            var components = DateComponents()
            components.hour = time.hour
            components.minute = time.minute
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return "\(time.hour):\(String(format: "%02d", time.minute))"
        }
    }

    private func scheduleIcon(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime: return "calendar"
        case .daily: return "repeat"
        }
    }

    private func scheduleTypeLabel(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime: return "One-time alarm"
        case .daily: return "Daily alarm"
        }
    }

    private func scheduleDescription(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime(let date):
            return date.formatted(date: .long, time: .omitted)
        case .daily:
            return "Repeats every day"
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
    @Previewable @State var alarmService = AlarmService()

    AlarmDetailView(
        alarm: Ticker(
            label: "Morning Workout",
            isEnabled: true,
            notes: "Remember to stretch before starting!",
            schedule: .daily(time: TickerSchedule.TimeOfDay(hour: 6, minute: 30)),
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
        onEdit: {},
        onDelete: {},
        onToggleEnabled: {}
    )
    .environment(alarmService)
}
