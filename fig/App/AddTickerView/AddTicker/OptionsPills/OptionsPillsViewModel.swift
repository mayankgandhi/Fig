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

    // References to other view models for reactive display
    private(set) weak var scheduleViewModel: ScheduleViewModel?
    private(set) weak var labelViewModel: LabelEditorViewModel?
    private(set) weak var countdownViewModel: CountdownConfigViewModel?

    // MARK: - Computed Display Values

    var displaySchedule: String {
        scheduleViewModel?.displaySchedule ?? "Today"
    }

    var displayLabel: String {
        labelViewModel?.displayText ?? "Label"
    }

    var displayCountdown: String {
        countdownViewModel?.displayText ?? "Countdown"
    }

    // Computed value flags
    var hasScheduleValue: Bool {
        scheduleViewModel?.hasScheduleValue ?? false
    }

    var hasLabelValue: Bool {
        !(labelViewModel?.isEmpty ?? true)
    }

    var hasCountdownValue: Bool {
        countdownViewModel?.isEnabled ?? false
    }

    var hasAnyActiveOptions: Bool {
        hasScheduleValue || hasLabelValue || hasCountdownValue
    }

    var activeOptionsCount: Int {
        var count = 0
        if hasScheduleValue { count += 1 }
        if hasLabelValue { count += 1 }
        if hasCountdownValue { count += 1 }
        return count
    }

    // MARK: - Methods

    func configure(
        schedule: ScheduleViewModel,
        label: LabelEditorViewModel,
        countdown: CountdownConfigViewModel
    ) {
        self.scheduleViewModel = schedule
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
        case .time: return false // Time is handled separately in Natural Language view
        case .schedule: return hasScheduleValue
        case .label: return hasLabelValue
        case .countdown: return hasCountdownValue
        case .icon: return false
        }
    }
}
