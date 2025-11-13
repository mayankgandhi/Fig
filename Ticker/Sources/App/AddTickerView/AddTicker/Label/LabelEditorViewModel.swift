//
//  LabelEditorViewModel.swift
//  fig
//
//  Manages ticker label text input and validation
//

import Foundation

@Observable
final class LabelEditorViewModel {
    var labelText: String = ""

    // MARK: - Computed Properties

    var isEmpty: Bool {
        labelText.isEmpty
    }

    var displayText: String {
        isEmpty ? "Label" : labelText
    }

    var characterCount: Int {
        labelText.count
    }

    var isValid: Bool {
        characterCount <= 50
    }

    // MARK: - Methods

    func setText(_ text: String) {
        labelText = text
    }

    func clear() {
        labelText = ""
    }

    func reset() {
        labelText = ""
    }
}
