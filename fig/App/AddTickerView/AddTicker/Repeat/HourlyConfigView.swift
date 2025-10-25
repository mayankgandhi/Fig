//
//  HourlyConfigView.swift
//  fig
//
//  UI for configuring hourly repetition
//

import SwiftUI

struct HourlyConfigView: View {
    @Binding var interval: Int
    @Binding var startTime: Date
    @Binding var endTime: Date?
    @State private var useEndTime: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Example text
            Text("Perfect for regular reminders")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Interval Picker Section
            configurationSection {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Repeat Every")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    HStack(spacing: TickerSpacing.sm) {
                        Picker("Interval", selection: $interval) {
                            ForEach(1...12, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 100)
                        .clipped()

                        Text(interval == 1 ? "hour" : "hours")
                            .Body()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    }
                }
            }

            // Start Time Section
            configurationSection {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Start Time")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }

            // End Time Section
            configurationSection {
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Toggle(isOn: $useEndTime) {
                        Text("Set End Time")
                            .Subheadline()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    }
                    .tint(TickerColor.primary)
                    .onChange(of: useEndTime) { _, newValue in
                        TickerHaptics.selection()
                        if newValue {
                            // Set end time to 8 hours after start
                            endTime = Calendar.current.date(byAdding: .hour, value: 8, to: startTime)
                        } else {
                            endTime = nil
                        }
                    }

                    if useEndTime, let endTimeBinding = Binding($endTime) {
                        VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                            Text("End Time")
                                .Caption()
                                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                                .textCase(.uppercase)
                                .tracking(0.8)

                            DatePicker("End Time", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // Helper Text
            Text("Alarms will repeat every \(interval) hour\(interval == 1 ? "" : "s") from \(formatTime(startTime))\(useEndTime && endTime != nil ? " until \(formatTime(endTime!))" : "")")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            useEndTime = endTime != nil
        }
    }

    // MARK: - Configuration Section Container

    @ViewBuilder
    private func configurationSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(TickerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .fill(TickerColor.surface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .strokeBorder(TickerColor.textTertiary(for: colorScheme).opacity(0.1), lineWidth: 1)
            )
            .shadow(
                color: TickerShadow.subtle.color,
                radius: TickerShadow.subtle.radius,
                x: TickerShadow.subtle.x,
                y: TickerShadow.subtle.y
            )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    @Previewable @State var interval = 2
    @Previewable @State var startTime = Date()
    @Previewable @State var endTime: Date? = nil

    HourlyConfigView(interval: $interval, startTime: $startTime, endTime: $endTime)
        .padding()
}
