//
//  OverlayCallout.swift
//  fig
//
//  Overlay callout container for non-distracting inline field editing
//  Used for all expandable field configurations (schedule, label, countdown, icon)
//

import SwiftUI
import TickerCore

struct OverlayCallout<Content: View>: View {
    let field: ExpandableField
    let viewModel: AddTickerViewModel
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
            // Time picker (not used in AddTickerView)
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
