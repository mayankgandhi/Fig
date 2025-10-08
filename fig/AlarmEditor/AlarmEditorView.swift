//
//  AlarmEditorView.swift
//  fig
//
//  Simplified alarm editor using Walnut Design System
//

import SwiftUI
import SwiftData
import WalnutDesignSystem

struct AlarmEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AlarmService.self) private var alarmService

    @State private var viewModel: AlarmEditorViewModel
    @State private var showError = false
    @State private var errorMessage = ""

    private let isEditing: Bool

    init(alarm: AlarmItem? = nil, alarmService: AlarmService) {
        self.isEditing = alarm != nil
        self._viewModel = State(initialValue: AlarmEditorViewModel(alarm: alarm, alarmService: alarmService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    basicInfoSection
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

            ColorPickerItem(
                icon: "paintpalette.fill",
                title: "Theme Color",
                selectedColorHex: $viewModel.tintColorHex,
                helperText: "Customize your alarm's appearance",
                iconColor: .purple
            )
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

        case .none:
            EmptyView()
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

    private var scheduleHelperText: String {
        switch viewModel.scheduleType {
        case .oneTime: return "Alarm triggers once at the specified date and time"
        case .daily: return "Repeats every day at the same time"
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
        Task {
            do {
                try await viewModel.saveAlarm(context: modelContext)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let alarmService = AlarmService()
    return AlarmEditorView(alarmService: alarmService)
        .modelContainer(for: AlarmItem.self, inMemory: true)
        .environment(alarmService)
}

#Preview("Edit Alarm") {
    let alarmService = AlarmService()
    let alarm = AlarmItem(
        label: "Morning Workout",
        notes: "Don't forget water bottle",
        schedule: .daily(time: .init(hour: 6, minute: 30)),
        countdown: .init(preAlert: .init(hours: 0, minutes: 30, seconds: 0))
    )

    return AlarmEditorView(alarm: alarm, alarmService: alarmService)
        .modelContainer(for: AlarmItem.self, inMemory: true)
        .environment(alarmService)
}
