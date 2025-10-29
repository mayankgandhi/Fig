//
//  IconPickerViewModel.swift
//  fig
//
//  Manages icon and color selection
//

import SwiftUI
import TickerCore

@Observable
final class IconPickerViewModel {
    var selectedIcon: String = "alarm"
    var selectedColorHex: String = "#8B5CF6"

    // MARK: - Computed Properties

    var selectedColor: Color {
        Color(hex: selectedColorHex) ?? TickerColor.primary
    }

    // MARK: - Methods

    func selectIcon(_ icon: String, colorHex: String) {
        selectedIcon = icon
        selectedColorHex = colorHex
    }

    func reset() {
        selectedIcon = "alarm"
        selectedColorHex = "#8B5CF6"
    }
}
