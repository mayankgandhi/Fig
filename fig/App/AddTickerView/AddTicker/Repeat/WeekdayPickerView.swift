//
//  WeekdayPickerView.swift
//  fig
//
//  UI for selecting specific weekdays
//

import SwiftUI

struct WeekdayPickerView: View {
    @Binding var selectedWeekdays: Set<TickerSchedule.Weekday>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text("Select Days")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: TickerSpacing.sm) {
                ForEach(TickerSchedule.Weekday.allCases, id: \.self) { weekday in
                    weekdayButton(for: weekday)
                }
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

    @ViewBuilder
    private func weekdayButton(for weekday: TickerSchedule.Weekday) -> some View {
        let isSelected = selectedWeekdays.contains(weekday)

        Button {
            TickerHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selectedWeekdays.remove(weekday)
                } else {
                    selectedWeekdays.insert(weekday)
                }
            }
        } label: {
            VStack(spacing: TickerSpacing.xxs) {
                Text(weekday.shortDisplayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? TickerColor.absoluteWhite : TickerColor.textPrimary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
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
}

#Preview {
    @Previewable @State var selectedDays: Set<TickerSchedule.Weekday> = [.monday, .wednesday, .friday]
    WeekdayPickerView(selectedWeekdays: $selectedDays)
        .padding()
}
