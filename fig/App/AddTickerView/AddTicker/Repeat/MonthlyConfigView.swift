//
//  MonthlyConfigView.swift
//  fig
//
//  UI for configuring monthly repetition
//

import SwiftUI
import TickerCore

struct MonthlyConfigView: View {
    @Binding var dayType: RepeatOptionsViewModel.MonthlyDayType
    @Binding var fixedDay: Int
    @Binding var weekday: TickerSchedule.Weekday
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Example text
            Text("Perfect for monthly bills, subscriptions")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TickerSpacing.md)

            // Day Type Selector Section
            configurationSection {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Repeat On")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    VStack(spacing: TickerSpacing.sm) {
                        ForEach(RepeatOptionsViewModel.MonthlyDayType.allCases, id: \.self) { type in
                            dayTypeButton(for: type)
                        }
                    }
                }
            }

            // Additional Configuration based on selection
            if dayType == .fixed {
                configurationSection {
                    VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                        Text("Day of Month")
                            .Caption()
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Picker("Day", selection: $fixedDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .clipped()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if dayType == .firstWeekday || dayType == .lastWeekday {
                configurationSection {
                    VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                        Text("Weekday")
                            .Caption()
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                            .textCase(.uppercase)
                            .tracking(0.8)

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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Helper Text
            Text(helperText)
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
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
