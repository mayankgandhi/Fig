//
//  ExpandedFieldContent.swift
//  fig
//
//  Handles rendering of expanded field content based on field type
//

import SwiftUI

struct ExpandedFieldContent: View {
    let field: ExpandableField
    let viewModel: AddTickerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Field-specific content with Liquid Glass
                fieldContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        TickerHaptics.selection()
                        viewModel.optionsPillsViewModel.collapseField()
                    }
                }
            }
        }
    }


    // MARK: - Field Content

    @ViewBuilder
    private var fieldContent: some View {
        switch field {
        case .schedule:
            ScheduleView(viewModel: viewModel.scheduleViewModel)

        case .label:
            LabelEditorView(viewModel: viewModel.labelViewModel)

        case .countdown:
            CountdownConfigView(viewModel: viewModel.countdownViewModel)

        case .icon:
            IconPickerViewMVVM(viewModel: viewModel.iconPickerViewModel)
        }
    }
}
