/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view for adding and configuring a new alarm.
*/

import AlarmKit
import SwiftUI

struct AlarmAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ViewModel.self) private var viewModel

    @State private var userInput = AlarmForm()

    var body: some View {
        NavigationStack {
            Form {
                textfield
                countdownSection
                scheduleSection
                secondaryButtonSection
            }
            .navigationTitle("Add Alarm")
            .navigationBarTitleDisplayMode(.inline)
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
        Label(title: {
            TextField("Label", text: $userInput.label)
        }, icon: {
            Image(systemName: "character.cursor.ibeam")
        })
    }

    var countdownSection: some View {
        VStack {
            Toggle("Countdown (Pre-Alert)", systemImage: "timer", isOn: $userInput.preAlertEnabled)
            if userInput.preAlertEnabled {
                TimePickerView(hour: $userInput.selectedPreAlert.hour, min: $userInput.selectedPreAlert.min, sec: $userInput.selectedPreAlert.sec)
            }
        }
    }

    var scheduleSection: some View {
        VStack {
            Toggle("Schedule", systemImage: "calendar", isOn: $userInput.scheduleEnabled)
            if userInput.scheduleEnabled {
                DatePicker("", selection: $userInput.selectedDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                daysOfTheWeekSection
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
        VStack {
            Picker("Secondary Button", systemImage: "button.programmable", selection: $userInput.selectedSecondaryButton) {
                ForEach(AlarmForm.SecondaryButtonOption.allCases, id: \.self) { button in
                    Text(button.rawValue).tag(button)
                }
            }

            if userInput.selectedSecondaryButton == .countdown {
                TimePickerView(hour: $userInput.selectedPostAlert.hour, min: $userInput.selectedPostAlert.min, sec: $userInput.selectedPostAlert.sec)
            }

            let callout = switch userInput.selectedSecondaryButton {
            case .none: "Only the Stop button is displayed in the alarm alert."
            case .countdown: "Displays the Repeat option when the alarm is triggered."
            case .openApp: "Displays the Open App button when the alarm is triggered."
            }

            Text(callout)
                .font(.callout)
                .fontWeight(.light)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 4)
        }
    }
}
