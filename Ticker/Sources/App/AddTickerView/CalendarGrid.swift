//
//  CalendarGrid.swift
//  fig
//
//  Created by Mayank Gandhi on 11/10/25.
//

import SwiftUI
import TickerCore

// MARK: - Calendar Grid

struct CalendarGrid: View {
    @Binding var selectedDate: Date
    var showStartDateLabel: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: TickerSpacing.xs), count: 7)
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
        VStack(spacing: TickerSpacing.md) {
            // Start Date Label (when repeat is selected)
            if showStartDateLabel {
                Text("START DATE")
                    .SmallText()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, TickerSpacing.xs)
            }

            // Month/Year Header with Navigation
            HStack(spacing: TickerSpacing.sm) {
                Button {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .frame(width: TickerSpacing.tapTargetMin, height: TickerSpacing.tapTargetMin)
                }
                .buttonStyle(.plain)

                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .TickerTitle()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .frame(maxWidth: .infinity)

                Button {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .frame(width: TickerSpacing.tapTargetMin, height: TickerSpacing.tapTargetMin)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, TickerSpacing.sm)
            
            // Weekday Headers
            LazyVGrid(columns: columns, spacing: TickerSpacing.xs) {
                ForEach(weekdaySymbols, id: \.id) { symbol in
                    Text(symbol.label)
                        .SmallText()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: TickerSpacing.lg)
                }
            }
            
            // Calendar Days Grid
            LazyVGrid(columns: columns, spacing: TickerSpacing.xs) {
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
                            .frame(height: TickerSpacing.tapTargetMin)
                    }
                }
            }
        }
        .padding(.horizontal, TickerSpacing.md)
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
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: TickerSpacing.tapTargetMin)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    x: 0,
                    y: shadowOffset
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Computed Properties
    
    private var textColor: Color {
        if isSelected {
            return TickerColor.absoluteWhite
        }
        return TickerColor.textPrimary(for: colorScheme)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return TickerColor.primary
        }
        return .clear
    }
    
    private var borderColor: Color {
        if isToday && !isSelected {
            return TickerColor.primary
        }
        return .clear
    }
    
    private var borderWidth: CGFloat {
        if isToday && !isSelected {
            return 2.0
        }
        return 0
    }
    
    private var shadowColor: Color {
        if isSelected {
            return TickerColor.primary.opacity(0.3)
        }
        return .clear
    }
    
    private var shadowRadius: CGFloat {
        if isSelected {
            return 4
        }
        return 0
    }
    
    private var shadowOffset: CGFloat {
        if isSelected {
            return 2
        }
        return 0
    }
}
