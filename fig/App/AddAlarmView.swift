//
//  AddAlarmView.swift
//  fig
//
//  Created by Mayank Gandhi on 09/10/25.
//

import SwiftUI
import SwiftData

struct AddAlarmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmService.self) private var alarmService
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedDate = Date()
    @State private var alarmName = ""
    @State private var repeatOption: RepeatOption = .noRepeat
    @State private var showingAdvanced = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingError = false

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
                                    await saveAlarm()
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
                AdvancedOptionsView(alarmName: $alarmName)
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

    private func saveAlarm() async {
        guard !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedDate)

        let schedule: TickerSchedule
        if repeatOption == .daily {
            schedule = .daily(time: TickerSchedule.TimeOfDay(
                hour: components.hour ?? 0,
                minute: components.minute ?? 0
            ))
        } else {
            schedule = .oneTime(date: selectedDate)
        }

        let alarm = Ticker(
            label: alarmName.isEmpty ? "Alarm" : alarmName,
            isEnabled: true,
            schedule: schedule
        )

        do {
            // Use AlarmService to schedule the alarm
            try await alarmService.scheduleAlarm(from: alarm, context: modelContext)
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
    @Binding var alarmName: String

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Alarm name", text: $alarmName)
                        .cabinetBody()
                } header: {
                    Text("Name")
                        .cabinetCaption2()
                        .textCase(.uppercase)
                }

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
    AddAlarmView()
        .modelContainer(for: [Ticker.self])
}

#Preview("Advanced Options") {
    AdvancedOptionsView(alarmName: .constant("Wake Up"))
}
