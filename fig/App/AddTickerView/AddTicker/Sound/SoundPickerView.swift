//
//  SoundPickerView.swift
//  fig
//
//  UI for selecting alarm sounds with preview
//

import SwiftUI

struct SoundPickerView: View {
    @Bindable var viewModel: SoundPickerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Header
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                Text("Alarm Sound")
                    .Caption()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }

            // Sound list
            ScrollView {
                VStack(spacing: TickerSpacing.xs) {
                    ForEach(viewModel.availableSounds) { sound in
                        SoundCell(
                            sound: sound,
                            isSelected: viewModel.selectedSound == sound.id,
                            onSelect: {
                                selectSound(sound)
                            },
                            onPreview: {
                                previewSound(sound)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 320)

            // Helper text
            Text("Choose a sound that will play when your alarm goes off. Tap the play button to preview each sound.")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
        }
    }

    private func selectSound(_ sound: AlarmSound) {
        TickerHaptics.selection()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            viewModel.selectSound(sound.id)
        }
    }

    private func previewSound(_ sound: AlarmSound) {
        TickerHaptics.light()
        viewModel.previewSound(sound.fileName)
    }
}

// MARK: - Sound Cell

private struct SoundCell: View {
    let sound: AlarmSound
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: TickerSpacing.md) {
                // Sound name
                Text(sound.displayName)
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Spacer()

                // Preview button (only for non-default sounds)
                if sound.fileName != nil {
                    Button(action: onPreview) {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(TickerColor.primary)
                    }
                    .buttonStyle(.plain)
                }

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(TickerColor.primary)
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme).opacity(0.3))
                }
            }
            .padding(TickerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.small)
                    .fill(isSelected ? TickerColor.primary.opacity(0.1) : TickerColor.background(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.small)
                    .strokeBorder(
                        isSelected ? TickerColor.primary : TickerColor.textTertiary(for: colorScheme).opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var viewModel = SoundPickerViewModel()

    SoundPickerView(viewModel: viewModel)
        .padding()
}
