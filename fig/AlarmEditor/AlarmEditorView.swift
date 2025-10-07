//
//  AlarmEditorView.swift
//  fig
//
//  Fully customizable alarm editor using Walnut Design System
//

import SwiftUI
import SwiftData
import WalnutDesignSystem

struct AlarmEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: AlarmEditorViewModel
    @State private var showError = false
    @State private var errorMessage = ""

    private let isEditing: Bool

    init(alarm: AlarmItem? = nil) {
        self.isEditing = alarm != nil
        self._viewModel = State(initialValue: AlarmEditorViewModel(alarm: alarm))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    basicInfoSection
                    categorySpecificSection
                    scheduleSection
                    countdownSection
                    postAlertSection
                    notesSection
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
            }
            .navigationTitle(isEditing ? "Edit Alarm" : "New Alarm")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        saveAlarm()
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(spacing: Spacing.small) {
            TextFieldItem(
                icon: "character.cursor.ibeam",
                title: "Alarm Label",
                text: $viewModel.label,
                placeholder: "Enter alarm name",
                helperText: "Give your alarm a descriptive name",
                iconColor: .blue
            )

            MenuPickerItem(
                icon: categoryIcon,
                title: "Category",
                selectedOption: .constant(viewModel.getCategoryType()),
                options: ["General", "Birthday", "Bill Payment", "Credit Card", "Subscription", "Appointment", "Medication", "Custom"],
                placeholder: "Select category",
                helperText: "Choose the type of alarm",
                iconColor: categoryColor
            )
            .onChange(of: viewModel.getCategoryType()) { _, newValue in
                viewModel.updateCategory(newValue)
            }

            ColorPickerItem(
                icon: "paintpalette.fill",
                title: "Theme Color",
                selectedColorHex: $viewModel.tintColorHex,
                helperText: "Customize your alarm's appearance",
                iconColor: .purple
            )
        }
    }

    // MARK: - Category-Specific Section

    @ViewBuilder
    private var categorySpecificSection: some View {
        let categoryType = viewModel.getCategoryType()

        VStack(spacing: Spacing.small) {
            switch categoryType {
            case "Birthday":
                TextFieldItem(
                    icon: "gift",
                    title: "Person's Name",
                    text: $viewModel.personName,
                    placeholder: "e.g., John Doe",
                    isRequired: true,
                )

            case "Bill Payment", "Credit Card", "Subscription":
                TextFieldItem(
                    icon: "building.columns",
                    title: categoryType == "Credit Card" ? "Card Name" : categoryType == "Subscription" ? "Service Name" : "Account Name",
                    text: $viewModel.accountName,
                    placeholder: "e.g., Electric Company",
                    isRequired: true,
                )

                TextFieldItem(
                    icon: "dollarsign.circle",
                    title: "Amount",
                    text: $viewModel.amount,
                    placeholder: "0.00",
                    keyboardType: .decimalPad,
                )

            case "Appointment":
                TextFieldItem(
                    icon: "mappin.circle",
                    title: "Location",
                    text: $viewModel.location,
                    placeholder: "e.g., 123 Main St",
                    iconColor: .blue
                )

            case "Medication":
                TextFieldItem(
                    icon: "pills",
                    title: "Medication Name",
                    text: $viewModel.medicationName,
                    placeholder: "e.g., Aspirin",
                    isRequired: true,
                )

                TextFieldItem(
                    icon: "syringe",
                    title: "Dosage",
                    text: $viewModel.dosage,
                    placeholder: "e.g., 500mg",
                    iconColor: .red
                )

            case "Custom":
                TextFieldItem(
                    icon: "star",
                    title: "Custom Icon Name",
                    text: $viewModel.customIcon,
                    placeholder: "e.g., heart.fill",
                    helperText: "SF Symbol name",
                    iconColor: .orange
                )

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(spacing: Spacing.small) {
            MenuPickerItem(
                icon: "calendar",
                title: "Schedule Type",
                selectedOption: $viewModel.scheduleType,
                options: AlarmEditorViewModel.ScheduleType.allCases,
                placeholder: "Select schedule",
                helperText: scheduleHelperText,
                iconColor: .blue
            )

            schedulePickerView
        }
    }

    @ViewBuilder
    private var schedulePickerView: some View {
        switch viewModel.scheduleType {
        case .oneTime:
            DatePickerItem(
                icon: "clock",
                title: "Date & Time",
                selectedDate: $viewModel.selectedDate,
                iconColor: .blue,
                isRequired: true,
                displayedComponents: [.date, .hourAndMinute]
            )

        case .daily:
            DatePickerItem(
                icon: "clock",
                title: "Time",
                selectedDate: $viewModel.selectedTime,
                iconColor: .blue,
                isRequired: true,
                displayedComponents: [.hourAndMinute]
            )

//        case .weekly:
//            DatePickerItem(
//                icon: "clock",
//                title: "Time",
//                selectedDate: $viewModel.selectedTime,
//                iconColor: .blue,
//                isRequired: true,
//                displayedComponents: [.hourAndMinute]
//            )
//
//            weekdaySelector

        case .monthly:
            DatePickerItem(
                icon: "clock",
                title: "Time",
                selectedDate: $viewModel.selectedTime,
                iconColor: .blue,
                isRequired: true,
                displayedComponents: [.hourAndMinute]
            )

            TextFieldItem(
                icon: "calendar.badge.clock",
                title: "Day of Month",
                text: Binding(
                    get: { String(viewModel.monthlyDay) },
                    set: { viewModel.monthlyDay = Int($0) ?? 1 }
                ),
                placeholder: "1-31",
                keyboardType: .numberPad,
            )

        case .yearly:
            DatePickerItem(
                icon: "clock",
                title: "Time",
                selectedDate: $viewModel.selectedTime,
                iconColor: .blue,
                isRequired: true,
                displayedComponents: [.hourAndMinute]
            )

            TextFieldItem(
                icon: "calendar",
                title: "Month",
                text: Binding(
                    get: { String(viewModel.yearlyMonth) },
                    set: { viewModel.yearlyMonth = Int($0) ?? 1 }
                ),
                placeholder: "1-12",
                helperText: "Month number (1=Jan, 12=Dec)",
                keyboardType: .numberPad,
            )

            TextFieldItem(
                icon: "calendar.badge.clock",
                title: "Day",
                text: Binding(
                    get: { String(viewModel.yearlyDay) },
                    set: { viewModel.yearlyDay = Int($0) ?? 1 }
                ),
                placeholder: "1-31",
                keyboardType: .numberPad,
            )
            case .none:
                EmptyView()
        }
    }

    private var weekdaySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat On")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.medium)

            HStack(spacing: 8) {
                ForEach(TickerSchedule.Weekday.allCases, id: \.self) { weekday in
                    WeekdayButton(
                        weekday: weekday,
                        isSelected: viewModel.selectedWeekdays.contains(weekday)
                    ) {
                        if let index = viewModel.selectedWeekdays.firstIndex(of:
                            weekday
                        ) {
                            viewModel.selectedWeekdays.remove(at: index)
                        } else {
                            viewModel.selectedWeekdays.append(weekday)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
    }

    // MARK: - Countdown Section

    private var countdownSection: some View {
        VStack(spacing: Spacing.small) {
            ToggleItem(
                icon: "timer",
                title: "Pre-Alert Countdown",
                subtitle: "Get notified before the alarm",
                isOn: $viewModel.preAlertEnabled,
                helperText: "Start a countdown timer before the alarm",
                iconColor: .orange
            )

            if viewModel.preAlertEnabled {
                TimePickerView(
                    hour: $viewModel.preAlertHours,
                    min: $viewModel.preAlertMinutes,
                    sec: $viewModel.preAlertSeconds
                )
                .padding(.horizontal, Spacing.small)
            }
        }
    }

    // MARK: - Post-Alert Section

    private var postAlertSection: some View {
        VStack(spacing: Spacing.small) {
            MenuPickerItem(
                icon: "arrow.clockwise",
                title: "Post-Alert Action",
                selectedOption: $viewModel.postAlertType,
                options: AlarmEditorViewModel.PostAlertType.allCases,
                placeholder: "Select action",
                helperText: postAlertHelperText,
                iconColor: .green
            )

            if viewModel.postAlertType == .snooze || viewModel.postAlertType == .repeat {
                TimePickerView(
                    hour: $viewModel.postAlertHours,
                    min: $viewModel.postAlertMinutes,
                    sec: $viewModel.postAlertSeconds
                )
                .padding(.horizontal, Spacing.small)
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        TextFieldItem(
            icon: "note.text",
            title: "Notes",
            text: $viewModel.notes,
            placeholder: "Additional notes...",
            helperText: "Optional notes for this alarm",
            iconColor: .gray
        )
    }

    // MARK: - Helpers

    private var categoryIcon: String {
        switch viewModel.getCategoryType() {
        case "General": return "alarm"
        case "Birthday": return "gift"
        case "Bill Payment": return "dollarsign.circle"
        case "Credit Card": return "creditcard"
        case "Subscription": return "arrow.clockwise"
        case "Appointment": return "calendar"
        case "Medication": return "pills"
        case "Custom": return "star"
        default: return "alarm"
        }
    }

    private var categoryColor: Color {
        switch viewModel.getCategoryType() {
        case "Birthday": return .pink
        case "Bill Payment", "Credit Card", "Subscription": return .green
        case "Appointment": return .blue
        case "Medication": return .red
        case "Custom": return .orange
        default: return .blue
        }
    }

    private var scheduleHelperText: String {
        switch viewModel.scheduleType {
        case .oneTime: return "Alarm triggers once at the specified date and time"
        case .daily: return "Repeats every day at the same time"
//        case .weekly: return "Repeats on selected days each week"
        case .monthly: return "Repeats on the same day each month"
        case .yearly: return "Repeats on the same date each year"
        case nil: return "Please select"
        }
    }

    private var postAlertHelperText: String {
        switch viewModel.postAlertType {
        case nil: return "Please select"
        case .some(.none): return "Only the stop button will be shown"
        case .snooze: return "Allows snoozing the alarm for a set duration"
        case .repeat: return "Allows repeating the countdown"
        case .openApp: return "Shows a button to open the app"
        }
    }

    // MARK: - Actions

    private func saveAlarm() {
        do {
            try viewModel.saveAlarm(context: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Weekday Button Component

private struct WeekdayButton: View {
    let weekday: TickerSchedule.Weekday
    let isSelected: Bool
    let action: () -> Void

    private var label: String {
        switch weekday {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
    }
}

// MARK: - Preview

#Preview {
    AlarmEditorView()
        .modelContainer(for: AlarmItem.self, inMemory: true)
}

#Preview("Edit Birthday Alarm") {
    let alarm = AlarmItem(
        label: "Mom's Birthday",
        category: .birthday(personName: "Mom", notes: "Buy flowers"),
        schedule: .yearly(month: 3, day: 15, time: .init(hour: 9, minute: 0)),
        countdown: .init(preAlert: .init(hours: 0, minutes: 30, seconds: 0))
    )

    return AlarmEditorView(alarm: alarm)
        .modelContainer(for: AlarmItem.self, inMemory: true)
}
