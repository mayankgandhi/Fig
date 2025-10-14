//
//  OptionsPillsViewModel.swift
//  fig
//
//  Manages pill button display and expandable field state
//

import Foundation

@Observable
final class OptionsPillsViewModel {
    var expandedField: ExpandableField? = nil
    var enableSnooze: Bool = true

    // References to other view models for reactive display
    private(set) weak var calendarViewModel: CalendarPickerViewModel?
    private(set) weak var repeatViewModel: RepeatOptionsViewModel?
    private(set) weak var labelViewModel: LabelEditorViewModel?
    private(set) weak var countdownViewModel: CountdownConfigViewModel?

    // MARK: - Computed Display Values

    var displayDate: String {
        calendarViewModel?.displayString ?? "Today"
    }

    var displayRepeat: String {
        repeatViewModel?.displayText ?? "No repeat"
    }

    var displayLabel: String {
        labelViewModel?.displayText ?? "Label"
    }

    var displayCountdown: String {
        countdownViewModel?.displayText ?? "Countdown"
    }

    // Computed value flags
    var hasCalendarValue: Bool {
        !(calendarViewModel?.isToday ?? true)
    }

    var hasLabelValue: Bool {
        !(labelViewModel?.isEmpty ?? true)
    }

    var hasCountdownValue: Bool {
        countdownViewModel?.isEnabled ?? false
    }

    var hasAnyActiveOptions: Bool {
        hasCalendarValue || hasLabelValue || hasCountdownValue || (repeatViewModel?.selectedOption != .noRepeat) || enableSnooze
    }

    // MARK: - Methods

    func configure(
        calendar: CalendarPickerViewModel,
        repeat: RepeatOptionsViewModel,
        label: LabelEditorViewModel,
        countdown: CountdownConfigViewModel
    ) {
        self.calendarViewModel = calendar
        self.repeatViewModel = `repeat`
        self.labelViewModel = label
        self.countdownViewModel = countdown
    }

    func toggleField(_ field: ExpandableField) {
        if expandedField == field {
            expandedField = nil
        } else {
            expandedField = field
        }
    }

    func collapseField() {
        expandedField = nil
    }

    func hasValue(for field: ExpandableField) -> Bool {
        switch field {
        case .calendar: return hasCalendarValue
        case .label: return hasLabelValue
        case .countdown: return hasCountdownValue
        case .repeat: return repeatViewModel?.selectedOption != .noRepeat
        case .icon: return false
        }
    }
}
