//
//  TimePickerViewModel.swift
//  fig
//
//  Manages hour and minute selection
//

import Foundation

@Observable
final class TimePickerViewModel {
    var selectedHour: Int
    var selectedMinute: Int

    // MARK: - Initialization

    init() {
        let now = Date()
        self.selectedHour = Calendar.current.component(.hour, from: now)
        self.selectedMinute = Calendar.current.component(.minute, from: now)
    }

    // MARK: - Computed Properties

    var formattedTime: String {
        String(format: "%02d:%02d", selectedHour, selectedMinute)
    }

    var isAM: Bool {
        selectedHour < 12
    }

    var hour12Format: Int {
        selectedHour == 0 ? 12 : (selectedHour > 12 ? selectedHour - 12 : selectedHour)
    }

    // MARK: - Methods

    func setTime(hour: Int, minute: Int) {
        selectedHour = hour
        selectedMinute = minute
    }

    func setTimeFromDate(_ date: Date) {
        let calendar = Calendar.current
        selectedHour = calendar.component(.hour, from: date)
        selectedMinute = calendar.component(.minute, from: date)
    }

    func reset() {
        let now = Date()
        selectedHour = Calendar.current.component(.hour, from: now)
        selectedMinute = Calendar.current.component(.minute, from: now)
    }
}
