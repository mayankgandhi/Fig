//
//  NotesEditorViewModel.swift
//  fig
//
//  Manages notes text editor state
//

import Foundation

@Observable
final class NotesEditorViewModel {
    var notesText: String? = nil

    // MARK: - Computed Properties

    var hasNotes: Bool {
        notesText != nil && !(notesText?.isEmpty ?? true)
    }

    var displayText: String {
        guard let notes = notesText, !notes.isEmpty else { return "Notes" }
        return String(notes.prefix(15)) + (notes.count > 15 ? "..." : "")
    }

    var characterCount: Int {
        notesText?.count ?? 0
    }

    // MARK: - Methods

    func setNotes(_ text: String?) {
        notesText = text
    }

    func clear() {
        notesText = nil
    }

    func reset() {
        notesText = nil
    }
}
