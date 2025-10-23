//
//  WeekdayPickerView.swift
//  fig
//
//  UI for selecting specific weekdays
//

import SwiftUI

struct WeekdayPickerView: View {
    @Binding var selectedWeekdays: Array<TickerSchedule.Weekday>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text("Select Days")
                .Subheadline()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

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
    }

    @ViewBuilder
    private func weekdayButton(for weekday: TickerSchedule.Weekday) -> some View {
        let isSelected = selectedWeekdays.contains(weekday)

        Button {
            TickerHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected, let index = selectedWeekdays.firstIndex(of: weekday) {
                    selectedWeekdays.remove(at: index)
                } else {
                    selectedWeekdays.append(weekday)
                }
            }
        } label: {
            Text(weekday.shortDisplayName)
                .Subheadline()
                .foregroundStyle(isSelected ? TickerColor.absoluteWhite : TickerColor.textPrimary(for: colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, TickerSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: TickerRadius.small)
                        .fill(isSelected ? TickerColor.primary : TickerColor.surface(for: colorScheme))
                )
        }
    }
}

#Preview {
    @Previewable @State var selectedDays: Array<TickerSchedule.Weekday> = [.monday, .wednesday, .friday]
    WeekdayPickerView(selectedWeekdays: $selectedDays)
        .padding()
}
