//
//  CalendarPickerView.swift
//  fig
//
//  UI wrapper for calendar date selection
//

import SwiftUI

struct CalendarPickerView: View {
    @Bindable var viewModel: CalendarPickerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        CalendarGrid(selectedDate: $viewModel.selectedDate)
    }
}
