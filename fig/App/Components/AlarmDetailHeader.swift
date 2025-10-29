//
//  AlarmDetailHeader.swift
//  fig
//
//  Header component for AlarmDetailView showing icon, label, and status
//

import SwiftUI
import TickerCore

struct AlarmDetailHeader: View {
    let alarm: Ticker
    let tickerService: TickerService
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: TickerSpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: iconSymbol)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                // Label
                Text(alarm.label)
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                // Status badge
                Text(statusLabel)
                    .Caption2()
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, TickerSpacing.xs)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(TickerSpacing.sm)
        .background(TickerColor.surface(for: colorScheme).opacity(0.5))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
    }
    
    // MARK: - Helper Properties
    
    private var iconSymbol: String {
        alarm.tickerData?.icon ?? "alarm"
    }

    private var iconColor: Color {
        if let colorHex = alarm.tickerData?.colorHex {
            return Color(hex: colorHex) ?? TickerColor.primary
        }
        return TickerColor.primary
    }

    private var statusLabel: String {
        if tickerService.getTicker(id: alarm.id) != nil {
            return "Active"
        }
        return alarm.isEnabled ? "Scheduled" : "Disabled"
    }

    private var statusColor: Color {
        if tickerService.getTicker(id: alarm.id) != nil {
            return TickerColor.scheduled
        }
        return alarm.isEnabled ? TickerColor.scheduled : TickerColor.disabled
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var tickerService = TickerService()
    
    AlarmDetailHeader(
        alarm: Ticker(
            label: "Morning Workout",
            isEnabled: true,
            schedule: .daily(
                time: TickerSchedule.TimeOfDay(hour: 6, minute: 30)
            ),
            tickerData: TickerData(
                name: "Fitness & Health",
                icon: "figure.run",
                colorHex: "#FF6B35"
            )
        ),
        tickerService: tickerService
    )
    .environment(tickerService)
}
