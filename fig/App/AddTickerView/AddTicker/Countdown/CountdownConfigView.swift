//
//  CountdownConfigView.swift
//  fig
//
//  UI for configuring countdown pre-alert
//

import SwiftUI

struct CountdownConfigView: View {
    @Bindable var viewModel: CountdownConfigViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Enable Toggle
            Toggle(isOn: $viewModel.isEnabled) {
                VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                    Text("Enable Pre-Alert")
                        .Subheadline()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                    Text("Get notified before the alarm")
                        .Caption()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            .tint(TickerColor.primary)
            .onChange(of: viewModel.isEnabled) { _, _ in
                TickerHaptics.selection()
            }

            // Time Picker (shown when enabled)
            if viewModel.isEnabled {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Countdown Duration")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    HStack(spacing: 0) {
                        Picker("Hours", selection: $viewModel.hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)

                        Picker("Minutes", selection: $viewModel.minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)m").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)

                        Picker("Seconds", selection: $viewModel.seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)s").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(height: 140)

                    // Summary text
                    if viewModel.totalSeconds > 0 {
                        Text("Alert will trigger \(viewModel.displayText.lowercased()) before the alarm")
                            .Caption()
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
