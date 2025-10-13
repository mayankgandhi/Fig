//
//  NotesEditorView.swift
//  fig
//
//  UI for editing alarm notes
//

import SwiftUI

struct NotesEditorView: View {
    @Bindable var viewModel: NotesEditorViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var binding: Binding<String> {
        Binding(
            get: { viewModel.notesText ?? "" },
            set: { viewModel.notesText = $0.isEmpty ? nil : $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: binding)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .frame(height: 120)
                .scrollContentBackground(.hidden)
                .padding(TickerSpacing.sm)

            // Placeholder text
            if viewModel.notesText == nil || viewModel.notesText!.isEmpty {
                Text("Add notes...")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                    .padding(TickerSpacing.sm)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .fill(TickerColors.surface(for: colorScheme).opacity(0.95))
        )
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
    }
}
