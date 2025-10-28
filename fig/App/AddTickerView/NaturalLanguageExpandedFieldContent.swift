//
//  NaturalLanguageExpandedFieldContent.swift
//  fig
//
//  Handles rendering of expanded field content for NaturalLanguageTickerView
//  Mirrors ExpandedFieldContent but works with NaturalLanguageViewModel
//

import SwiftUI

struct NaturalLanguageExpandedFieldContent: View {
    let field: ExpandableField
    let viewModel: NaturalLanguageViewModel

    var body: some View {
        NaturalLanguageOverlayCallout(field: field, viewModel: viewModel) {
            fieldContent
        }
    }

    // MARK: - Field Content

    @ViewBuilder
    private var fieldContent: some View {
        switch field {
        case .time:
            TimePickerCard(viewModel: viewModel.timePickerViewModel)

        case .schedule:
            ScheduleView(viewModel: viewModel.scheduleViewModel)

        case .label:
            LabelEditorView(viewModel: viewModel.labelViewModel)

        case .countdown:
            CountdownConfigView(viewModel: viewModel.countdownViewModel)

        case .icon:
            IconPickerViewMVVM(viewModel: viewModel.iconPickerViewModel)

        case .sound:
            SoundPickerView(viewModel: viewModel.soundPickerViewModel)
        }
    }
}

// MARK: - Overlay Callout for Natural Language

struct NaturalLanguageOverlayCallout<Content: View>: View {
    let field: ExpandableField
    let viewModel: NaturalLanguageViewModel
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background tap area to dismiss overlay
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.optionsPillsViewModel.collapseField()
                    }
                }
            
            // Overlay content
            VStack(spacing: 0) {
                // Header with dismiss button
                HStack {
                    Text(headerTitle)
                        .Headline()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                    Spacer()

                    Button {
                        TickerHaptics.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.optionsPillsViewModel.collapseField()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(.title2, design: .rounded, weight: .regular))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(TickerSpacing.md)

                Divider()

                // Content area with adaptive max height
                ScrollView {
                    content()
                        .padding(TickerSpacing.md)
                }
                .frame(maxHeight: maxContentHeight)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .fill(TickerColor.surface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .strokeBorder(TickerColor.textTertiary(for: colorScheme).opacity(0.15), lineWidth: 1)
            )
            .shadow(
                color: TickerShadow.elevated.color,
                radius: TickerShadow.elevated.radius,
                x: TickerShadow.elevated.x,
                y: TickerShadow.elevated.y
            )
            .padding(TickerSpacing.md)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
        }
    }

    // MARK: - Computed Properties

    private var maxContentHeight: CGFloat {
        switch field {
        case .time:
            // Time picker is compact
            return 400
        case .schedule, .icon:
            // Larger fields need more space
            return 600
        case .label:
            // Label is compact
            return 200
        case .countdown:
            // Countdown needs medium space
            return 350
        case .sound:
            // Sound picker needs medium space
            return 400
        }
    }

    private var headerTitle: String {
        switch field {
        case .time:
            return "Alarm Time"
        case .schedule:
            return "Schedule"
        case .label:
            return "Alarm Label"
        case .countdown:
            return "Pre-Alert Countdown"
        case .icon:
            return "Alarm Icon"
        case .sound:
            return "Alarm Sound"
        }
    }
}
