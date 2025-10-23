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
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Weekday Selector Section
            configurationSection {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Select Days")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.8)

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

            // Anchor Date Section
            configurationSection {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Starting Week")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    DatePicker("", selection: $anchorDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()

                    Text("The alarm will repeat every other week starting from this date's week")
                        .Caption()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .padding(.top, TickerSpacing.xs)
                }
            }

            // Helper Text
            if !selectedWeekdays.isEmpty {
                let sortedDays = selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
                let dayNames = sortedDays.map { $0.shortDisplayName }.joined(separator: ", ")
                Text("Alarms will repeat every other week on \(dayNames)")
                    .Caption()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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
