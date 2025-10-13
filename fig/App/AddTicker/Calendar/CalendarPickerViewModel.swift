//
//  CalendarPickerViewModel.swift
//  fig
//
//  Manages date selection with smart date logic
//

import Foundation

@Observable
final class CalendarPickerViewModel {
    private let calendar: Calendar
    var selectedDate: Date

    // MARK: - Initialization

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.selectedDate = Date()
    }

    // MARK: - Computed Properties

    var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    var isTomorrow: Bool {
        calendar.isDateInTomorrow(selectedDate)
    }

    var displayString: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        return selectedDate.formatted(.dateTime.month(.abbreviated).day())
    }

    // MARK: - Methods

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func updateSmartDate(for hour: Int, minute: Int) {
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute

        guard let todayWithSelectedTime = calendar.date(from: components) else { return }

        if todayWithSelectedTime < now {
            selectedDate = calendar.date(byAdding: .day, value: 1, to: todayWithSelectedTime) ?? todayWithSelectedTime
        } else {
            selectedDate = todayWithSelectedTime
        }
    }

    func reset() {
        selectedDate = Date()
    }
}
