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
        VStack(spacing: TickerSpacing.md) {
            Toggle("Enable Countdown", isOn: $viewModel.isEnabled)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .tint(TickerColor.primary)

            if viewModel.isEnabled {
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
                .frame(height: 120)
            }
        }
        .padding(TickerSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .fill(TickerColor.surface(for: colorScheme).opacity(0.95))
        )
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
    }
}
