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
    }
}
