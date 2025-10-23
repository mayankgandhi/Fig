//
//  YearlyConfigView.swift
//  fig
//
//  UI for configuring yearly repetition (birthdays, anniversaries, etc.)
//

import SwiftUI

struct YearlyConfigView: View {
    @Binding var month: Int
    @Binding var day: Int
    @Environment(\.colorScheme) private var colorScheme

    private let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.lg) {
            Text("Yearly Repeat")
                .Callout()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

            Text("Perfect for birthdays, anniversaries, and annual events")
                .Footnote()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

            Divider()

            // Month and Day Pickers
            HStack(spacing: TickerSpacing.md) {
                // Month Picker
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Month")
                        .Subheadline()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                    Picker("Month", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text(monthNames[m - 1]).tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .clipped()
                }

                // Day Picker
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Day")
                        .Subheadline()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                    Picker("Day", selection: $day) {
                        ForEach(1...daysInMonth, id: \.self) { d in
                            Text("\(d)").tag(d)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .clipped()
                }
            }

            // Helper Text
            Text("Alarm will repeat every year on \(monthNames[month - 1]) \(day)")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .padding(.top, TickerSpacing.xs)
        }
        .onChange(of: month) { _, _ in
            // Adjust day if it's now invalid for the selected month
            if day > daysInMonth {
                day = daysInMonth
            }
        }
    }

    private var daysInMonth: Int {
        switch month {
        case 2:
            return 29 // Allow Feb 29 for leap years
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }
}

#Preview {
    @Previewable @State var month = 3
    @Previewable @State var day = 15

    YearlyConfigView(month: $month, day: $day)
        .padding()
}
