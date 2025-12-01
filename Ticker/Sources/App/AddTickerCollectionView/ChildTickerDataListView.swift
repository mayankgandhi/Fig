//
//  ChildTickerDataListView.swift
//  fig
//
//  List view for displaying and managing child ticker data in collection editor
//  Works with CollectionChildTickerData instead of full Ticker objects
//

import SwiftUI
import TickerCore
import DesignKit

struct ChildTickerDataListView: View {
    let childData: [CollectionChildTickerData]
    let icon: String
    let colorHex: String
    let onEdit: (CollectionChildTickerData) -> Void
    let onDelete: (CollectionChildTickerData) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Section header
            HStack {
                Text("TICKER LIST")
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer()

                if !childData.isEmpty {
                    Text("\(childData.count)")
                        .Caption2()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, TickerSpacing.md)

            if childData.isEmpty {
                emptyStateView
            } else {
                dataList
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: TickerSpacing.md) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

            Text("No tickers")
                .Body()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

            Text("Add tickers to create a collection")
                .Caption()
                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TickerSpacing.xl)
        .padding(.horizontal, TickerSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColor.surface(for: colorScheme).opacity(0.5))
        )
        .padding(.horizontal, TickerSpacing.md)
    }

    // MARK: - Data List

    private var dataList: some View {
        VStack(spacing: TickerSpacing.sm) {
            ForEach(Array(childData.enumerated()), id: \.element.id) { index, data in
                childDataRow(data: data, index: index)
            }
        }
        .padding(.horizontal, TickerSpacing.md)
    }

    // MARK: - Child Data Row

    private func childDataRow(data: CollectionChildTickerData, index: Int) -> some View {
        HStack(spacing: DesignKit.md) {
            // Icon with background circle (matching AlarmCell design)
            categoryIconView(for: data)
            
            // Content (matching AlarmCell design)
            VStack(alignment: .leading, spacing: DesignKit.xs) {
                Text(data.label)
                    .tickerTitle()
                    .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.leading)
                
                scheduleInfoView(for: data)
                    .caption2()
                    .foregroundStyle(DesignKit.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Time display (matching AlarmCell design)
            VStack {
                scheduleText(for: data.schedule)
                    .Title2()
                    .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.leading)
            }
            
            // Actions
            HStack(spacing: TickerSpacing.sm) {
                // Edit button
                Button {
                    DesignKitHaptics.selection()
                    onEdit(data)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignKit.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(DesignKit.primary.opacity(0.1))
                        )
                }

                // Delete button
                Button {
                    DesignKitHaptics.selection()
                    onDelete(data)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
        }
        .padding(DesignKit.md)
        .background(cardBackground(for: data))
        .clipShape(RoundedRectangle(cornerRadius: DesignKit.large))
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
            radius: 8,
            x: 0,
            y: 2
        )
    }
    
    // MARK: - Card Background (matching AlarmCell design)
    
    @ViewBuilder
    private func cardBackground(for data: CollectionChildTickerData) -> some View {
        let iconColor = iconColor(for: data)
        
        ZStack {
            // Base material background
            RoundedRectangle(cornerRadius: DesignKit.large)
                .fill(.ultraThinMaterial)
            
            // Subtle color tint based on icon color
            RoundedRectangle(cornerRadius: DesignKit.large)
                .fill(
                    LinearGradient(
                        colors: [
                            iconColor.opacity(colorScheme == .dark ? 0.08 : 0.04),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Subtle border
            RoundedRectangle(cornerRadius: DesignKit.large)
                .strokeBorder(
                    iconColor.opacity(colorScheme == .dark ? 0.15 : 0.1),
                    lineWidth: 1
                )
        }
    }
    
    // MARK: - Icon View (matching AlarmCell design)
    
    @ViewBuilder
    private func categoryIconView(for data: CollectionChildTickerData) -> some View {
        let iconColor = iconColor(for: data)
        let iconName = iconName(for: data)
        
        ZStack {
            // Background circle
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 48, height: 48)
            
            // Icon
            Image(systemName: iconName)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
        }
    }
    
    private func iconColor(for data: CollectionChildTickerData) -> Color {
        // Use child-specific color if provided, otherwise fall back to collection color
        if let childColorHex = data.colorHex, let color = Color(hex: childColorHex) {
            return color
        }
        
        // Fall back to collection color
        if let collectionColor = Color(hex: colorHex) {
            return collectionColor
        }
        
        // Default to primary
        return DesignKit.primary
    }
    
    private func iconName(for data: CollectionChildTickerData) -> String {
        // Use child-specific icon if provided, otherwise fall back to collection icon
        return data.icon ?? icon
    }
    
    @ViewBuilder
    private func scheduleInfoView(for data: CollectionChildTickerData) -> some View {
        HStack(spacing: DesignKit.xxs) {
            Image(systemName: data.schedule.icon)
                .font(.system(size: 12, weight: .medium))
            Text(data.schedule.displaySummary)
        }
    }
    
    @ViewBuilder
    private func scheduleText(for schedule: TickerSchedule) -> some View {
        switch schedule {
        case .oneTime(let date):
            Text(date, style: .time)
        case .daily(let time), .weekdays(let time, _), .biweekly(let time, _), .monthly(_, let time), .yearly(_, _, let time):
            Text(formatTime(time))
        case .hourly(let interval, let time):
            Text(formatTime(time))
        case .every(_, _, let time):
            // Always show time for all repeat schedules
            Text(formatTime(time))
        }
    }
    
    private func formatTime(_ time: TimeOfDay) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(time.hour):\(String(format: "%02d", time.minute))"
    }
}

// MARK: - Preview

#Preview {
    ChildTickerDataListView(
        childData: [
            CollectionChildTickerData(
                label: "Wake up",
                schedule: .daily(time: TimeOfDay(hour: 7, minute: 0))
            ),
            CollectionChildTickerData(
                label: "Bedtime",
                schedule: .daily(time: TimeOfDay(hour: 22, minute: 30))
            )
        ],
        icon: "moon.stars",
        colorHex: "#8B5CF6",
        onEdit: { _ in },
        onDelete: { _ in }
    )
    .padding()
}
