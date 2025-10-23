//
//  EveryConfigView.swift
//  fig
//
//  UI for configuring "every X unit" repetition
//

import SwiftUI

struct EveryConfigView: View {
    @Binding var interval: Int
    @Binding var unit: TickerSchedule.TimeUnit
    @Binding var startTime: Date
    @Binding var endTime: Date?
    @State private var useEndTime: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Unit Picker Section
            configurationSection {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Time Unit")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Picker("Unit", selection: $unit) {
                        ForEach(TickerSchedule.TimeUnit.allCases, id: \.self) { timeUnit in
                            Text(timeUnit.displayName).tag(timeUnit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: unit) { _, _ in
                        TickerHaptics.selection()
                        // Reset interval when unit changes
                        interval = 1
                    }
                }
            }

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
                            ForEach(intervalRange, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 100)
                        .clipped()

                        Text(intervalDisplayText)
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

                    DatePicker("", selection: $startTime, displayedComponents: displayComponents)
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
                            // Set end time based on unit
                            endTime = defaultEndTime
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

                            DatePicker("End Time", selection: endTimeBinding, displayedComponents: displayComponents)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // Helper Text
            Text(summaryText)
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

    // MARK: - Helper Properties

    private var intervalRange: ClosedRange<Int> {
        switch unit {
        case .minutes:
            return 1...60
        case .hours:
            return 1...24
        case .days:
            return 1...30
        case .weeks:
            return 1...52
        }
    }

    private var intervalDisplayText: String {
        interval == 1 ? unit.singularName : unit.displayName.lowercased()
    }

    private var displayComponents: DatePickerComponents {
        switch unit {
        case .minutes, .hours:
            return .hourAndMinute
        case .days, .weeks:
            return [.date, .hourAndMinute]
        }
    }

    private var defaultEndTime: Date {
        let calendar = Calendar.current
        switch unit {
        case .minutes:
            return calendar.date(byAdding: .hour, value: 8, to: startTime) ?? startTime
        case .hours:
            return calendar.date(byAdding: .hour, value: 12, to: startTime) ?? startTime
        case .days:
            return calendar.date(byAdding: .day, value: 7, to: startTime) ?? startTime
        case .weeks:
            return calendar.date(byAdding: .day, value: 30, to: startTime) ?? startTime
        }
    }

    private var summaryText: String {
        let unitName = interval == 1 ? unit.singularName : unit.displayName.lowercased()
        let baseText = "Alarms will repeat every \(interval) \(unitName) from \(formatTime(startTime))"

        if useEndTime, let endTime = endTime {
            return baseText + " until \(formatTime(endTime))"
        } else {
            return baseText
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch unit {
        case .minutes, .hours:
            formatter.dateFormat = "h:mm a"
        case .days, .weeks:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        }
        return formatter.string(from: date)
    }
}

#Preview {
    @Previewable @State var interval = 30
    @Previewable @State var unit = TickerSchedule.TimeUnit.minutes
    @Previewable @State var startTime = Date()
    @Previewable @State var endTime: Date? = nil

    EveryConfigView(interval: $interval, unit: $unit, startTime: $startTime, endTime: $endTime)
        .padding()
}
