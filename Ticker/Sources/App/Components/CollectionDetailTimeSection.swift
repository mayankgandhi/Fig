//
//  CollectionDetailTimeSection.swift
//  fig
//
//  Time section component for TickerCollectionDetailView showing schedule info
//

import SwiftUI
import TickerCore

struct CollectionDetailTimeSection: View {
    let tickerCollection: TickerCollection
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: TickerSpacing.xs) {
            if let config = tickerCollection.sleepScheduleConfig {
                // Sleep schedule: show bedtime and wake time
                VStack(spacing: TickerSpacing.sm) {
                    // Bedtime
                    if let bedtimeTicker = tickerCollection.childTickers?.first(where: { $0.label == "Bedtime" }) {
                        timeRow(
                            label: "Bedtime",
                            time: config.bedtime,
                            icon: "bed.double.fill",
                            color: .blue
                        )
                    }
                    
                    // Wake time
                    if let wakeTicker = tickerCollection.childTickers?.first(where: { $0.label == "Wake Up" }) {
                        timeRow(
                            label: "Wake Up",
                            time: config.wakeTime,
                            icon: "alarm.fill",
                            color: .orange
                        )
                    }
                }
            } else if let children = tickerCollection.childTickers, !children.isEmpty {
                // Custom collection: show next occurrence or summary
                if let firstChild = children.first, let schedule = firstChild.schedule {
                    Text(timeString(for: schedule))
                        .TimeDisplay()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    
                    HStack(spacing: TickerSpacing.xxs) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .Caption()
                        Text("\(children.count) ticker\(children.count == 1 ? "" : "s")")
                            .Footnote()
                    }
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            } else {
                // Empty collection
                Text("No tickers")
                    .Body()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TickerSpacing.md)
        .background(TickerColor.surface(for: colorScheme).opacity(0.5))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func timeRow(label: String, time: TimeOfDay, icon: String, color: Color) -> some View {
        HStack(spacing: TickerSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(label)
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                
                Text(time.formatted(as: .hourMinute))
                    .Title3()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(.horizontal, TickerSpacing.md)
    }
    
    // MARK: - Helper Methods
    
    private func timeString(for schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime(let date):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)

        case .daily(let time), .weekdays(let time, _), .biweekly(let time, _), .monthly(_, let time), .yearly(_, _, let time):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            var components = DateComponents()
            components.hour = time.hour
            components.minute = time.minute
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return "\(time.hour):\(String(format: "%02d", time.minute))"

        case .hourly(let interval, let time):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            var components = DateComponents()
            components.hour = time.hour
            components.minute = time.minute
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return "\(time.hour):\(String(format: "%02d", time.minute))"

        case .every(let interval, let unit, let time):
            switch unit {
            case .minutes, .hours:
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                var components = DateComponents()
                components.hour = time.hour
                components.minute = time.minute
                if let date = Calendar.current.date(from: components) {
                    return formatter.string(from: date)
                }
                return "\(time.hour):\(String(format: "%02d", time.minute))"
            case .days, .weeks:
                let unitName = interval == 1 ? unit.singularName : unit.displayName.lowercased()
                return "Every \(interval) \(unitName)"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CollectionDetailTimeSection(
        tickerCollection: TickerCollection(
            label: "Sleep Schedule",
            collectionType: .sleepSchedule,
            configuration: .sleepSchedule(
                SleepScheduleConfiguration(
                    bedtime: TimeOfDay(hour: 22, minute: 0),
                    wakeTime: TimeOfDay(hour: 6, minute: 30)
                )
            )
        )
    )
    .padding()
}

