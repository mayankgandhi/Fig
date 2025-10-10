//
//  AddTickerView.swift
//  fig
//
//  Created by Mayank Gandhi on 09/10/25.
//

import SwiftUI
import SwiftData

struct AddTickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmService.self) private var alarmService
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedDate = Date()
    @State private var tickerLabel = ""
    @State private var tickerNotes: String?
    @State private var repeatOption: RepeatOption = .noRepeat
    @State private var showingAdvanced = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingError = false

    // Countdown options
    @State private var enableCountdown = false
    @State private var countdownHours = 0
    @State private var countdownMinutes = 5
    @State private var countdownSeconds = 0

    // Presentation options
    @State private var tintColorHex: String?
    @State private var secondaryButtonType: TickerPresentation.SecondaryButtonType = .none

    enum RepeatOption: String, CaseIterable {
        case noRepeat = "No repeat"
        case daily = "Daily"

        var icon: String {
            switch self {
            case .noRepeat: return "calendar"
            case .daily: return "repeat"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Calendar & Time Section
                    VStack(spacing: 24) {
                        // Month/Year Header with Navigation
                        HStack {
                            Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                                .cabinetTitle2()
                                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                            Image(systemName: "chevron.right")
                                .cabinetBody()
                                .foregroundStyle(TickerColors.criticalRed)

                            Spacer()

                            HStack(spacing: TickerSpacing.md) {
                                Button {
                                    TickerHaptics.selection()
                                    withAnimation(TickerAnimation.quick) {
                                        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                                    }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .cabinetBody()
                                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                                }

                                Button {
                                    TickerHaptics.selection()
                                    withAnimation(TickerAnimation.quick) {
                                        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                                    }
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .cabinetBody()
                                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                                }
                            }
                        }
                        .padding(.horizontal, TickerSpacing.md)
                        .padding(.top, TickerSpacing.md)

                        // Calendar Grid
                        CalendarGrid(selectedDate: $selectedDate)
                            .padding(.horizontal, 20)

                        // Time Section
                        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                            Text("Time")
                                .cabinetCaption2()
                                .textCase(.uppercase)
                                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                            DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, TickerSpacing.md)
                    }

                    Spacer()

                    // Bottom Controls
                    VStack(spacing: TickerSpacing.md) {
                        // Date & Time / Repeat Options
                        HStack(spacing: TickerSpacing.sm) {
                            // Date & Time Button
                            Button {
                                TickerHaptics.selection()
                                // Toggle date picker or advanced options
                            } label: {
                                HStack(spacing: TickerSpacing.xs) {
                                    Image(systemName: "clock")
                                        .cabinetSubheadline()
                                    Text("Date & time")
                                        .cabinetSubheadline()
                                }
                                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                                .padding(.horizontal, TickerSpacing.md)
                                .padding(.vertical, TickerSpacing.sm)
                                .background(TickerColors.surface(for: colorScheme))
                                .clipShape(Capsule())
                            }

                            // Repeat Button
                            Menu {
                                ForEach(RepeatOption.allCases, id: \.self) { option in
                                    Button {
                                        TickerHaptics.selection()
                                        repeatOption = option
                                    } label: {
                                        HStack {
                                            Text(option.rawValue)
                                            if repeatOption == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: TickerSpacing.xs) {
                                    Image(systemName: repeatOption.icon)
                                        .cabinetSubheadline()
                                    Text(repeatOption.rawValue)
                                        .cabinetSubheadline()
                                }
                                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                                .padding(.horizontal, TickerSpacing.md)
                                .padding(.vertical, TickerSpacing.sm)
                                .background(TickerColors.surface(for: colorScheme))
                                .clipShape(Capsule())
                            }

                            Spacer()
                        }
                        .padding(.horizontal, TickerSpacing.md)

                        // Bottom Action Bar
                        HStack(spacing: TickerSpacing.md) {
                            // Advanced Button
                            Button {
                                TickerHaptics.selection()
                                showingAdvanced.toggle()
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .cabinetTitle3()
                                    .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                                    .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)
                                    .background(TickerColors.surface(for: colorScheme))
                                    .clipShape(Circle())
                            }

                            // Done Button
                            Button {
                                Task {
                                    await saveTicker()
                                }
                            } label: {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .tint(TickerColors.absoluteWhite)
                                    }
                                    Text(isSaving ? "Saving..." : "Done")
                                }
                            }
                            .tickerPrimaryButton()
                            .disabled(isSaving)
                        }
                        .padding(.horizontal, TickerSpacing.md)
                        .padding(.bottom, TickerSpacing.md)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAdvanced) {
                AdvancedOptionsView(
                    tickerLabel: $tickerLabel,
                    tickerNotes: $tickerNotes,
                    enableCountdown: $enableCountdown,
                    countdownHours: $countdownHours,
                    countdownMinutes: $countdownMinutes,
                    countdownSeconds: $countdownSeconds,
                    tintColorHex: $tintColorHex,
                    secondaryButtonType: $secondaryButtonType
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func saveTicker() async {
        guard !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedDate)

        // Build schedule
        let schedule: TickerSchedule
        if repeatOption == .daily {
            schedule = .daily(time: TickerSchedule.TimeOfDay(
                hour: components.hour ?? 0,
                minute: components.minute ?? 0
            ))
        } else {
            schedule = .oneTime(date: selectedDate)
        }

        // Build countdown (if enabled)
        let countdown: TickerCountdown?
        if enableCountdown {
            let duration = TickerCountdown.CountdownDuration(
                hours: countdownHours,
                minutes: countdownMinutes,
                seconds: countdownSeconds
            )
            countdown = TickerCountdown(preAlert: duration, postAlert: nil)
        } else {
            countdown = nil
        }

        // Build presentation
        let presentation = TickerPresentation(
            tintColorHex: tintColorHex,
            secondaryButtonType: secondaryButtonType
        )

        // Build Ticker
        let ticker = Ticker(
            label: tickerLabel.isEmpty ? "Ticker" : tickerLabel,
            isEnabled: true,
            notes: tickerNotes,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation,
            tickerData: nil
        )

        do {
            // Use AlarmService to schedule the ticker
            try await alarmService.scheduleAlarm(from: ticker, context: modelContext)
            TickerHaptics.success()
            dismiss()
        } catch {
            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Calendar Grid

struct CalendarGrid: View {
    @Binding var selectedDate: Date

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let calendar = Calendar.current
    private let weekdaySymbols = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = monthFirstWeek.start

        while days.count < 42 { // 6 weeks
            if calendar.isDate(currentDate, equalTo: selectedDate, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    var body: some View {
        VStack(spacing: 12) {
            // Weekday Headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Days
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(monthDays.indices, id: \.self) { index in
                    if let date = monthDays[index] {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: {
            TickerHaptics.selection()
            onTap()
        }) {
            Text(dayNumber)
                .cabinetTitle3()
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? TickerColors.absoluteWhite : TickerColors.textPrimary(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: TickerSpacing.tapTargetMin)
                .background(
                    Circle()
                        .fill(isSelected ? TickerColors.criticalRed : .clear)
                )
                .overlay(
                    Circle()
                        .strokeBorder(isToday && !isSelected ? TickerColors.criticalRed : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Advanced Options View

struct AdvancedOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var tickerLabel: String
    @Binding var tickerNotes: String?
    @Binding var enableCountdown: Bool
    @Binding var countdownHours: Int
    @Binding var countdownMinutes: Int
    @Binding var countdownSeconds: Int
    @Binding var tintColorHex: String?
    @Binding var secondaryButtonType: TickerPresentation.SecondaryButtonType

    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section {
                    TextField("Ticker name", text: $tickerLabel)
                        .cabinetBody()
                } header: {
                    Text("Name")
                        .cabinetCaption2()
                        .textCase(.uppercase)
                }

                // Notes Section
                Section {
                    TextEditor(text: Binding(
                        get: { tickerNotes ?? "" },
                        set: { tickerNotes = $0.isEmpty ? nil : $0 }
                    ))
                    .cabinetBody()
                    .frame(minHeight: 80)
                } header: {
                    Text("Notes")
                        .cabinetCaption2()
                        .textCase(.uppercase)
                }

                // Countdown Section
                Section {
                    Toggle("Enable Countdown", isOn: $enableCountdown)
                        .cabinetSubheadline()

                    if enableCountdown {
                        HStack {
                            Picker("Hours", selection: $countdownHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)h").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)

                            Picker("Minutes", selection: $countdownMinutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)m").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)

                            Picker("Seconds", selection: $countdownSeconds) {
                                ForEach(0..<60) { second in
                                    Text("\(second)s").tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                        .frame(height: 120)
                    }
                } header: {
                    Text("Countdown Timer")
                        .cabinetCaption2()
                        .textCase(.uppercase)
                } footer: {
                    Text("Start a countdown before the alarm goes off")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                }

                // Presentation Section
                Section {
                    Picker("Secondary Button", selection: $secondaryButtonType) {
                        Text("None").tag(TickerPresentation.SecondaryButtonType.none)
                        Text("Countdown").tag(TickerPresentation.SecondaryButtonType.countdown)
                        Text("Open App").tag(TickerPresentation.SecondaryButtonType.openApp)
                    }
                    .cabinetSubheadline()
                } header: {
                    Text("Alert Options")
                        .cabinetCaption2()
                        .textCase(.uppercase)
                }

                // Sound & Vibration Section
                Section {
                    NavigationLink {
                        Text("Sound picker")
                    } label: {
                        HStack {
                            Text("Sound")
                                .cabinetSubheadline()
                            Spacer()
                            Text("Default")
                                .cabinetFootnote()
                                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                        }
                    }

                    Toggle("Vibrate", isOn: .constant(true))
                        .cabinetSubheadline()
                }

                // Snooze Section
                Section {
                    Toggle("Snooze", isOn: .constant(true))
                        .cabinetSubheadline()
                } footer: {
                    Text("Allow snoozing when alarm goes off")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                }
            }
            .navigationTitle("Advanced")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        TickerHaptics.selection()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddTickerView()
        .modelContainer(for: [Ticker.self])
}

#Preview("Advanced Options") {
    AdvancedOptionsView(
        tickerLabel: .constant("Wake Up"),
        tickerNotes: .constant("Morning alarm"),
        enableCountdown: .constant(false),
        countdownHours: .constant(0),
        countdownMinutes: .constant(5),
        countdownSeconds: .constant(0),
        tintColorHex: .constant(nil),
        secondaryButtonType: .constant(.none)
    )
}
