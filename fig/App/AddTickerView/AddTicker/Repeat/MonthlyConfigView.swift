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
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text("Repeat On")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
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
                    .background(Color.white.opacity(0.1))

                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Day of Month")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
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
                    .background(Color.white.opacity(0.1))

                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Weekday")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
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
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .padding(.top, TickerSpacing.xs)
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
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? TickerColor.absoluteWhite : TickerColor.textPrimary(for: colorScheme))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(TickerColor.absoluteWhite)
                }
            }
            .padding(.horizontal, TickerSpacing.md)
            .padding(.vertical, TickerSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.small)
                    .fill(isSelected ? TickerColor.primary : TickerColor.surface(for: colorScheme).opacity(0.5))
            )
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.small)
                    .fill(.ultraThinMaterial.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.small)
                    .strokeBorder(
                        isSelected ? TickerColor.primary.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
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
