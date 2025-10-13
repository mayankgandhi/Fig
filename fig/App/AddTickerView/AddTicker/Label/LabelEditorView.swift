//
//  LabelEditorView.swift
//  fig
//
//  UI for editing alarm label text
//

import SwiftUI

struct LabelEditorView: View {
    @Bindable var viewModel: LabelEditorViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TextField("Enter label", text: $viewModel.labelText)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .padding(TickerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .fill(TickerColor.surface(for: colorScheme).opacity(0.95))
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
