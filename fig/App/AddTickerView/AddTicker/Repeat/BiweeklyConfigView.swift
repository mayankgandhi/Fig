//
//  BiweeklyConfigView.swift
//  fig
//
//  UI for configuring biweekly repetition
//

import SwiftUI

struct BiweeklyConfigView: View {
    @Binding var selectedWeekdays: Set<TickerSchedule.Weekday>
    @Binding var anchorDate: Date
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text("Biweekly Repeat")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

            // Weekday Selector
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Text("Select Days")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
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
                .background(Color.white.opacity(0.1))

            // Anchor Date
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Text("Starting Week")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                DatePicker("", selection: $anchorDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()

                Text("The alarm will repeat every other week starting from this date's week")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme).opacity(0.8))
            }

            // Helper Text
            if !selectedWeekdays.isEmpty {
                let sortedDays = selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
                let dayNames = sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
                Text("Alarms will repeat every other week on \(dayNames)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .padding(.top, TickerSpacing.xs)
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
    @Previewable @State var anchorDate = Date()

    BiweeklyConfigView(selectedWeekdays: $selectedDays, anchorDate: $anchorDate)
        .padding()
}
