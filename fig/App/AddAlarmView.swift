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
                                .font(.title2)
                                .fontWeight(.semibold)

                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundStyle(.blue)

                            Spacer()

                            HStack(spacing: 16) {
                                Button {
                                    withAnimation {
                                        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                                    }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }

                                Button {
                                    withAnimation {
                                        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                                    }
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Calendar Grid
                        CalendarGrid(selectedDate: $selectedDate)
                            .padding(.horizontal, 20)

                        // Time Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    // Bottom Controls
                    VStack(spacing: 16) {
                        // Date & Time / Repeat Options
                        HStack(spacing: 12) {
                            // Date & Time Button
                            Button {
                                // Toggle date picker or advanced options
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .font(.body)
                                    Text("Date & time")
                                        .font(.body)
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                            }

                            // Repeat Button
                            Menu {
                                ForEach(RepeatOption.allCases, id: \.self) { option in
                                    Button {
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
                                HStack(spacing: 8) {
                                    Image(systemName: repeatOption.icon)
                                        .font(.body)
                                    Text(repeatOption.rawValue)
                                        .font(.body)
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        // Bottom Action Bar
                        HStack(spacing: 16) {
                            // Advanced Button
                            Button {
                                showingAdvanced.toggle()
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, height: 50)
                                    .background(Color(.secondarySystemBackground))
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
                                            .tint(.white)
                                    }
                                    Text(isSaving ? "Saving..." : "Done")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isSaving ? Color.blue.opacity(0.6) : .blue)
                                .clipShape(Capsule())
                            }
                            .disabled(isSaving)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
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

        let alarm = AlarmItem(
            label: alarmName.isEmpty ? "Alarm" : alarmName,
            isEnabled: true,
            schedule: schedule
        )

        do {
            // Use AlarmService to schedule the alarm
            try await alarmService.scheduleAlarm(from: alarm, context: modelContext)
            dismiss()
        } catch {
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

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: onTap) {
            Text(dayNumber)
                .font(.title3)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? .blue : .clear)
                )
                .overlay(
                    Circle()
                        .strokeBorder(isToday && !isSelected ? .blue : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Advanced Options View

struct AdvancedOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var alarmName: String

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Alarm name", text: $alarmName)
                } header: {
                    Text("Name")
                }

                Section {
                    NavigationLink {
                        Text("Sound picker")
                    } label: {
                        HStack {
                            Text("Sound")
                            Spacer()
                            Text("Default")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle("Vibrate", isOn: .constant(true))
                }

                Section {
                    Toggle("Snooze", isOn: .constant(true))
                } footer: {
                    Text("Allow snoozing when alarm goes off")
                }
            }
            .navigationTitle("Advanced")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddAlarmView()
        .modelContainer(for: [AlarmItem.self])
}

#Preview("Advanced Options") {
    AdvancedOptionsView(alarmName: .constant("Wake Up"))
}
