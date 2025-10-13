//
//  RepeatOptionsViewModel.swift
//  fig
//
//  Manages repeat frequency selection (one-time vs daily)
//

import Foundation

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

@Observable
final class RepeatOptionsViewModel {
    var selectedOption: RepeatOption = .noRepeat

    // MARK: - Computed Properties

    var isDailyRepeat: Bool {
        selectedOption == .daily
    }

    var displayIcon: String {
        selectedOption.icon
    }

    var displayText: String {
        selectedOption.rawValue
    }

    // MARK: - Methods

    func selectOption(_ option: RepeatOption) {
        selectedOption = option
    }

    func reset() {
        selectedOption = .noRepeat
    }
}
