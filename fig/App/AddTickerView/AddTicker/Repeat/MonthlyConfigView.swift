//
//  MonthlyConfigView.swift
//  fig
//
//  UI for configuring monthly repetition
//

import SwiftUI

struct MonthlyConfigView: View {
    @Binding var dayType: RepeatOptionsViewModel.MonthlyDayType
    @Binding var fixedDay: Int
    @Binding var weekday: TickerSchedule.Weekday
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.lg) {
            Text("Repeat On")
                .Callout()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

            // Day Type Selector
            VStack(spacing: TickerSpacing.sm) {
                ForEach(RepeatOptionsViewModel.MonthlyDayType.allCases, id: \.self) { type in
                    dayTypeButton(for: type)
                }
            }

            // Additional Configuration based on selection
            if dayType == .fixed {
                Divider()

                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Day of Month")
                        .Subheadline()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                    Picker("Day", selection: $fixedDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .clipped()
                }
            } else if dayType == .firstWeekday || dayType == .lastWeekday {
                Divider()

                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Weekday")
                        .Subheadline()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                    Picker("Weekday", selection: $weekday) {
                        ForEach(TickerSchedule.Weekday.allCases, id: \.self) { day in
                            Text(day.displayName).tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .clipped()
                }
            }

            // Helper Text
            Text(helperText)
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .padding(.top, TickerSpacing.xs)
        }
    }

    @ViewBuilder
    private func dayTypeButton(for type: RepeatOptionsViewModel.MonthlyDayType) -> some View {
        let isSelected = dayType == type

        Button {
            TickerHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dayType = type
            }
        } label: {
            HStack {
                Text(type.rawValue)
                    .Subheadline()
                    .foregroundStyle(isSelected ? TickerColor.absoluteWhite : TickerColor.textPrimary(for: colorScheme))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .Subheadline()
                        .foregroundStyle(TickerColor.absoluteWhite)
                }
            }
            .padding(.horizontal, TickerSpacing.md)
            .padding(.vertical, TickerSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.small)
                    .fill(isSelected ? TickerColor.primary : TickerColor.surface(for: colorScheme))
            )
        }
    }

    private var helperText: String {
        switch dayType {
        case .fixed:
            return "Alarm will repeat on day \(fixedDay) of every month"
        case .firstWeekday:
            return "Alarm will repeat on the first \(weekday.displayName) of every month"
        case .lastWeekday:
            return "Alarm will repeat on the last \(weekday.displayName) of every month"
        case .firstOfMonth:
            return "Alarm will repeat on the 1st of every month"
        case .lastOfMonth:
            return "Alarm will repeat on the last day of every month"
        }
    }
}

#Preview {
    @Previewable @State var dayType: RepeatOptionsViewModel.MonthlyDayType = .fixed
    @Previewable @State var fixedDay = 15
    @Previewable @State var weekday: TickerSchedule.Weekday = .monday

    MonthlyConfigView(dayType: $dayType, fixedDay: $fixedDay, weekday: $weekday)
        .padding()
}
