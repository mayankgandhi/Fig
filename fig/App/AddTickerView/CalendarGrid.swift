//
//  CalendarGrid.swift
//  fig
//
//  Created by Mayank Gandhi on 11/10/25.
//

import SwiftUI

// MARK: - Calendar Grid

struct CalendarGrid: View {
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let calendar = Calendar.current
    private let weekdaySymbols = [
        (id: "sun", label: "S"),
        (id: "mon", label: "M"),
        (id: "tue", label: "T"),
        (id: "wed", label: "W"),
        (id: "thu", label: "T"),
        (id: "fri", label: "F"),
        (id: "sat", label: "S")
    ]
    
    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while days.count < 42 {
            if calendar.isDate(currentDate, equalTo: selectedDate, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
                
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                
                Button {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.id) { symbol in
                    Text(symbol.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(monthDays.indices, id: \.self) { index in
                    if let date = monthDays[index] {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            TickerHaptics.selection()
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(dayNumber)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? TickerColor.absoluteWhite : TickerColor.textPrimary(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? TickerColor.primary : .clear)
                )
                .overlay(
                    Circle()
                        .strokeBorder(isToday && !isSelected ? TickerColor.primary : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}
