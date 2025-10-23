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
        VStack(alignment: .leading, spacing: TickerSpacing.lg) {
            // Interval Picker
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Text("Repeat Every")
                    .Subheadline()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

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
                        .Callout()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                }
            }

            Divider()

            // Start Time
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Text("Start Time")
                    .Subheadline()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            Divider()

            // End Time Toggle
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Toggle(isOn: $useEndTime) {
                    Text("Set End Time")
                        .Subheadline()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                }
                .tint(TickerColor.primary)
                .onChange(of: useEndTime) { _, newValue in
                    if newValue {
                        // Set end time to 8 hours after start
                        endTime = Calendar.current.date(byAdding: .hour, value: 8, to: startTime)
                    } else {
                        endTime = nil
                    }
                }

                if useEndTime, let endTimeBinding = Binding($endTime) {
                    DatePicker("End Time", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }

            // Helper Text
            Text("Alarms will repeat every \(interval) hour\(interval == 1 ? "" : "s") from \(formatTime(startTime))\(useEndTime && endTime != nil ? " until \(formatTime(endTime!))" : "")")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .padding(.top, TickerSpacing.xs)
        }
        .onAppear {
            useEndTime = endTime != nil
        }
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
