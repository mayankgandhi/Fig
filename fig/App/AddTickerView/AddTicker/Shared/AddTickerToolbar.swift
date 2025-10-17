//
//  AddTickerToolbar.swift
//  fig
//
//  Reusable toolbar configuration for AddTickerView
//

import SwiftUI

struct AddTickerToolbar: ToolbarContent {
    let isEditMode: Bool
    let formattedTime: String
    let isSaving: Bool
    let canSave: Bool
    let hasDateWeekdayMismatch: Bool
    let isExpanded: Bool
    let onDismiss: () -> Void
    let onSave: () -> Void
    let onCollapse: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(isEditMode ? "Edit Ticker" : "New Ticker")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Text(formattedTime)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .opacity(0.8)
            }
        }

        ToolbarItem(placement: .cancellationAction) {
            Button {
                TickerHaptics.selection()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
            }
            .buttonStyle(PlainButtonStyle())
        }

        ToolbarItem(placement: .confirmationAction) {
            SaveButton(
                isSaving: isSaving,
                canSave: canSave,
                hasDateWeekdayMismatch: hasDateWeekdayMismatch,
                isExpanded: isExpanded,
                onCollapse: onCollapse,
                onSave: onSave
            )
        }
    }
}

// MARK: - Save Button Component

private struct SaveButton: View {
    let isSaving: Bool
    let canSave: Bool
    let hasDateWeekdayMismatch: Bool
    let isExpanded: Bool
    let onCollapse: () -> Void
    let onSave: () -> Void

    var body: some View {
        Button {
            if isExpanded {
                TickerHaptics.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    onCollapse()
                }
            } else {
                TickerHaptics.criticalAction()
                onSave()
            }
        } label: {
            HStack(spacing: TickerSpacing.sm) {
                if isSaving {
                    ProgressView()
                        .tint(TickerColor.absoluteWhite)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                }
                Text(isSaving ? "Saving..." : "Save")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(TickerColor.absoluteWhite)
            .padding(.horizontal, TickerSpacing.lg)
            .padding(.vertical, TickerSpacing.md)
            .scaleEffect(isSaving ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSaving)
        }
        .disabled(isSaving || !canSave)
        .opacity(hasDateWeekdayMismatch ? 0.5 : (canSave ? 1.0 : 0.6))
        .animation(.easeInOut(duration: 0.2), value: canSave)
        .animation(.easeInOut(duration: 0.2), value: hasDateWeekdayMismatch)
    }
}
