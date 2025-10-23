//
//  BiweeklyConfigView.swift
//  fig
//
//  UI for configuring biweekly repetition
//

import SwiftUI

struct BiweeklyConfigView: View {
    @Binding var selectedWeekdays: Array<TickerSchedule.Weekday>
    @Binding var anchorDate: Date
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.lg) {
            Text("Biweekly Repeat")
                .Callout()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

            // Weekday Selector
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
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

            Divider()

            // Anchor Date
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Text("Starting Week")
                    .Subheadline()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                DatePicker("", selection: $anchorDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()

                Text("The alarm will repeat every other week starting from this date's week")
                    .Caption2()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme).opacity(0.8))
            }

            // Helper Text
            if !selectedWeekdays.isEmpty {
                let sortedDays = selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
                let dayNames = sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
                Text("Alarms will repeat every other week on \(dayNames)")
                    .Caption()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .padding(.top, TickerSpacing.xs)
            }
        }
    }

    @ViewBuilder
    private func weekdayButton(for weekday: TickerSchedule.Weekday) -> some View {
        let isSelected = selectedWeekdays.contains(weekday)

        Button {
            TickerHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected, let index = selectedWeekdays.firstIndex(
                    of: weekday
                ) {
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
    @Previewable @State var anchorDate = Date()

    BiweeklyConfigView(selectedWeekdays: $selectedDays, anchorDate: $anchorDate)
        .padding()
}
