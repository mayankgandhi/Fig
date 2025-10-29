//
//  LabelEditorView.swift
//  fig
//
//  UI for editing alarm label text
//

import SwiftUI
import TickerCore

struct LabelEditorView: View {
    @Bindable var viewModel: LabelEditorViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Text input field
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                Text("Label Text")
                    .Caption()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)

                TextField("e.g., Morning Workout, Team Meeting, Coffee Break", text: $viewModel.labelText)
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .padding(TickerSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: TickerRadius.small)
                            .fill(TickerColor.background(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TickerRadius.small)
                            .strokeBorder(
                                isTextFieldFocused ? TickerColor.primary : TickerColor.textTertiary(for: colorScheme).opacity(0.2),
                                lineWidth: isTextFieldFocused ? 2 : 1
                            )
                    )
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
            }

            // Helper text
            Text("Add a custom label to help identify this alarm. Leave blank to use the default time display.")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
        }
        .onAppear {
            // Auto-focus the text field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
}
