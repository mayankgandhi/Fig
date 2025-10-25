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
    let isExpanded: Bool
    let onDismiss: () -> Void
    let onSave: () -> Void
    let onCollapse: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(isEditMode ? "Edit Ticker" : "New Ticker")
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Text(formattedTime)
                    .Caption()
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
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
            }
            .buttonStyle(PlainButtonStyle())
        }

        ToolbarItem(placement: .confirmationAction) {
            SaveButton(
                isSaving: isSaving,
                canSave: canSave,
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
    let isExpanded: Bool
    let onCollapse: () -> Void
    let onSave: () -> Void

    var body: some View {
        Button {
            print("🔘 AddTickerToolbar SaveButton tapped")
            print("   → isExpanded: \(isExpanded)")
            print("   → isSaving: \(isSaving)")
            print("   → canSave: \(canSave)")
            
            if isExpanded {
                print("   → Collapsing expanded field")
                TickerHaptics.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    onCollapse()
                }
            } else {
                print("   → Triggering save action")
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
                        .font(.callout.weight(.bold))
                }
                Text(isSaving ? "Saving..." : "Save")
                    .Body()
            }
            .foregroundStyle(TickerColor.primary)
            .padding(.horizontal, TickerSpacing.lg)
            .padding(.vertical, TickerSpacing.md)
            .scaleEffect(isSaving ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSaving)
        }
        .disabled(isSaving || !canSave)
        .opacity(canSave ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: canSave)
    }
}
