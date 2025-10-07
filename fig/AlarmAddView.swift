/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view for adding and configuring a new alarm.
*/

import AlarmKit
import SwiftUI
import WalnutDesignSystem

struct AlarmAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ViewModel.self) private var viewModel

    @State private var userInput = AlarmForm()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    textfield
                    countdownSection
                    scheduleSection
                    secondaryButtonSection
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
            }
            .navigationTitle("Add Alarm")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.scheduleAlarm(with: userInput)
                        dismiss()
                    } label: {
                        Text("Add")
                    }
                    .disabled(!userInput.isValidAlarm)
                }
            }
        }
    }

    var textfield: some View {
        TextFieldItem(
            icon: "character.cursor.ibeam",
            title: "Alarm Label",
            text: $userInput.label,
            placeholder: "Enter alarm name",
            iconColor: .blue
        )
    }

    var countdownSection: some View {
        VStack(spacing: Spacing.small) {
            ToggleItem(
                icon: "timer",
                title: "Countdown (Pre-Alert)",
                subtitle: "Set a pre-alert countdown timer",
                isOn: $userInput.preAlertEnabled,
                iconColor: .orange
            )

            if userInput.preAlertEnabled {
                TimePickerView(hour: $userInput.selectedPreAlert.hour, min: $userInput.selectedPreAlert.min, sec: $userInput.selectedPreAlert.sec)
                    .padding(.horizontal, Spacing.small)
            }
        }
    }

    var scheduleSection: some View {
        VStack(spacing: Spacing.small) {
            ToggleItem(
                icon: "calendar",
                title: "Schedule",
                subtitle: "Set a scheduled alarm time",
                isOn: $userInput.scheduleEnabled,
                iconColor: .blue
            )

            if userInput.scheduleEnabled {
                DatePicker("", selection: $userInput.selectedDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.horizontal, Spacing.small)

                daysOfTheWeekSection
                    .padding(.horizontal, Spacing.small)
            }
        }
    }

    var daysOfTheWeekSection: some View {
        HStack(spacing: -3) {
            ForEach(Locale.autoupdatingCurrent.orderedWeekdays, id: \.self) { weekday in
                Button(action: {
                    if userInput.isSelected(day: weekday) {
                        userInput.selectedDays.remove(weekday)
                    } else {
                        userInput.selectedDays.insert(weekday)
                    }
                }) {
                    Text(weekday.rawValue.localizedUppercase)
                        .font(.caption2)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.5)
                        .frame(width: 26, height: 26)
                }
                .tint(
                    .blue.opacity(userInput.isSelected(day: weekday) ? 1 : 0.4)
                )
                .buttonBorderShape(.circle)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    var secondaryButtonSection: some View {
        VStack(spacing: Spacing.small) {
            MenuPickerItem(
                icon: "button.programmable",
                title: "Secondary Button",
                selectedOption: $userInput.selectedSecondaryButton,
                options: AlarmForm.SecondaryButtonOption.allCases,
                placeholder: "Select button type",
                helperText: helperTextForSecondaryButton,
                iconColor: .purple
            )

            if userInput.selectedSecondaryButton == .countdown {
                TimePickerView(hour: $userInput.selectedPostAlert.hour, min: $userInput.selectedPostAlert.min, sec: $userInput.selectedPostAlert.sec)
                    .padding(.horizontal, Spacing.small)
            }
        }
    }

    private var helperTextForSecondaryButton: String {
        switch userInput.selectedSecondaryButton {
        case .some(.none): fallthrough
        case .none: "Only the Stop button is displayed in the alarm alert."
        case .countdown: "Displays the Repeat option when the alarm is triggered."
        case .openApp: "Displays the Open App button when the alarm is triggered."
        }
    }
}
