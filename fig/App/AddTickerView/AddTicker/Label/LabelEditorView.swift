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
    }
}
