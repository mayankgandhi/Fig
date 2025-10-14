//
//  TimePickerView.swift
//  fig
//
//  UI for selecting hour and minute
//

import SwiftUI

struct TimePickerView: View {
    @Bindable var viewModel: TimePickerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: TickerSpacing.lg) {
            // Title with better hierarchy
            VStack(spacing: TickerSpacing.xs) {
                Text("Set Time")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                
                Text(viewModel.formattedTime)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }

            // Time Pickers with enhanced styling
            HStack(spacing: TickerSpacing.sm) {
                // Hour Picker
                VStack(spacing: TickerSpacing.xs) {
                    Text("HOUR")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Picker("Hour", selection: $viewModel.selectedHour) {
                        ForEach(0..<24) { hour in
                            Text(String(format: "%02d", hour))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: 80)
                    .clipped()
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

                // Minute Picker
                VStack(spacing: TickerSpacing.xs) {
                    Text("MIN")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Picker("Minute", selection: $viewModel.selectedMinute) {
                        ForEach(0..<60) { minute in
                            Text(String(format: "%02d", minute))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: 80)
                    .clipped()
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
