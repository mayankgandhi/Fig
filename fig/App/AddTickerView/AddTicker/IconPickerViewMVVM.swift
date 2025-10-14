//
//  IconPickerViewMVVM.swift
//  fig
//
//  Simple adapter to use IconPickerView with IconPickerViewModel
//

import SwiftUI

struct IconPickerViewMVVM: View {
    @Bindable var viewModel: IconPickerViewModel

    var body: some View {
        IconPickerView(
            selectedIcon: Binding(
                get: { viewModel.selectedIcon },
                set: { viewModel.selectedIcon = $0 }
            ),
            selectedColorHex: Binding(
                get: { viewModel.selectedColorHex },
                set: { viewModel.selectedColorHex = $0 }
            )
        )
    }
}
