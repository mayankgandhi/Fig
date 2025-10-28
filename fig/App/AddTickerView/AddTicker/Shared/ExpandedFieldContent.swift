//
//  ExpandedFieldContent.swift
//  fig
//
//  Handles rendering of expanded field content based on field type
//  All fields use overlay callout presentation
//

import SwiftUI

struct ExpandedFieldContent: View {
    let field: ExpandableField
    let viewModel: AddTickerViewModel

    var body: some View {
        OverlayCallout(field: field, viewModel: viewModel) {
            fieldContent
        }
    }

    // MARK: - Field Content

    @ViewBuilder
    private var fieldContent: some View {
        switch field {
        case .time:
            // Time picker is not used in AddTickerView (shown directly in main view via TimePickerCard)
            EmptyView()

        case .schedule:
            ScheduleView(viewModel: viewModel.scheduleViewModel)

        case .label:
            LabelEditorView(viewModel: viewModel.labelViewModel)

        case .countdown:
            CountdownConfigView(viewModel: viewModel.countdownViewModel)

        case .sound:
            SoundPickerView(viewModel: viewModel.soundPickerViewModel)

        case .icon:
            IconPickerViewMVVM(viewModel: viewModel.iconPickerViewModel)
        }
    }
}
