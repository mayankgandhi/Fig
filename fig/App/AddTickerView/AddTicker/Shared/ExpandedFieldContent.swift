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
        VStack(spacing: 0) {
            // Dismiss button
            dismissButton

            // Field-specific content with Liquid Glass
            fieldContent
                .padding(TickerSpacing.lg)
                .glassEffect(in: .rect(cornerRadius: TickerRadius.large))
                .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        HStack {
            Spacer()
            Button {
                TickerHaptics.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.optionsPillsViewModel.collapseField()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(TickerColor.surface(for: colorScheme).opacity(0.9))
                        .frame(width: 28, height: 28)

                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .frame(width: 28, height: 28)

                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(TickerSpacing.md)
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
