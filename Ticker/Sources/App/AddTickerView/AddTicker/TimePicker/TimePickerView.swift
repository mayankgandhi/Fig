//
//  TimePickerView.swift
//  fig
//
//  UI for selecting hour and minute
//

import SwiftUI
import TickerCore

struct TimePickerView: View {
    @Bindable var viewModel: TimePickerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: TickerSpacing.lg) {
            // Title with better hierarchy
            VStack(spacing: TickerSpacing.xs) {
                Text("Set Time")
                    .TickerTitle()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.formattedTime)
                    .DetailText()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .accessibilityLabel("Selected time")
            }

            // Time Pickers with enhanced styling
            HStack(spacing: TickerSpacing.sm) {
                // Hour Picker
                VStack(spacing: TickerSpacing.xs) {
                    Text("HOUR")
                        .Caption2()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .accessibilityHidden(true)

                    Picker("Hour", selection: $viewModel.selectedHour) {
                        ForEach(0..<24) { hour in
                            Text(String(format: "%02d", hour))
                                .TimeDisplay()
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: 80)
                    .clipped()
                    .accessibilityLabel("Hour")
                    .accessibilityValue("\(viewModel.selectedHour) \(viewModel.selectedHour == 1 ? "hour" : "hours")")
                    .accessibilityHint("Swipe up or down to change the hour")
                }
                .background(
                    RoundedRectangle(cornerRadius: TickerRadius.medium)
                        .fill(TickerColor.surface(for: colorScheme).opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: TickerRadius.medium)
                                .strokeBorder(
                                    TickerColor.primary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.vertical, TickerSpacing.sm)

                // Separator with enhanced styling
                VStack {
                    Circle()
                        .fill(TickerColor.primary.opacity(0.3))
                        .frame(width: 6, height: 6)

                    Circle()
                        .fill(TickerColor.primary.opacity(0.6))
                        .frame(width: 8, height: 8)

                    Circle()
                        .fill(TickerColor.primary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                .padding(.vertical, TickerSpacing.lg)
                .accessibilityHidden(true)

                // Minute Picker
                VStack(spacing: TickerSpacing.xs) {
                    Text("MIN")
                        .Caption2()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .accessibilityHidden(true)

                    Picker("Minute", selection: $viewModel.selectedMinute) {
                        ForEach(0..<60) { minute in
                            Text(String(format: "%02d", minute))
                                .TimeDisplay()
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: 80)
                    .clipped()
                    .accessibilityLabel("Minute")
                    .accessibilityValue("\(viewModel.selectedMinute) \(viewModel.selectedMinute == 1 ? "minute" : "minutes")")
                    .accessibilityHint("Swipe up or down to change the minute")
                }
                .background(
                    RoundedRectangle(cornerRadius: TickerRadius.medium)
                        .fill(TickerColor.surface(for: colorScheme).opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: TickerRadius.medium)
                                .strokeBorder(
                                    TickerColor.primary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.vertical, TickerSpacing.sm)
            }
            .frame(height: 180)
        }
    }
}
