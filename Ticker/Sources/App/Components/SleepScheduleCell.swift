//
//  SleepScheduleCell.swift
//  Ticker
//
//  Created by Mayank Gandhi on 26/11/25.
//

import SwiftUI
import DesignKit
import TickerCore

// MARK: - Sleep Schedule Cell

struct SleepScheduleCell: View {
    let compositeItem: CompositeTicker
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var config: SleepScheduleConfiguration? {
        compositeItem.sleepScheduleConfig
    }
    
    private var tintColor: Color {
        compositeItem.presentation.tintColor
    }
    
    var body: some View {
        Button(action: {
            DesignKitHaptics.selection()
            onTap()
        }) {
            HStack(spacing: DesignKit.md) {
                // Sleep icon with background
                sleepIconView
                
                // Main content
                VStack(alignment: .leading, spacing: DesignKit.xs) {
                    // Title
                    HStack(alignment: .firstTextBaseline) {
                        Text(compositeItem.label)
                            .tickerTitle()
                            .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Enabled/disabled indicator
                        if !compositeItem.isEnabled {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(DesignKit.textTertiary(for: colorScheme))
                        }
                    }
                    
                    // Time information - Hero elements
                    HStack(spacing: DesignKit.lg) {
                        // Bedtime
                        timeInfoView(
                            icon: "bed.double.fill",
                            label: "Bedtime",
                            time: config?.bedtime,
                            iconColor: Color(red: 0.4, green: 0.6, blue: 1.0) // Soft blue
                        )
                        
                        // Wake time
                        timeInfoView(
                            icon: "sunrise.fill",
                            label: "Wake Up",
                            time: config?.wakeTime,
                            iconColor: DesignKit.accent // Warm accent color
                        )
                    }
                    .padding(.top, DesignKit.xxs)
                    
                    // Sleep duration
                    if let config = config {
                        HStack(spacing: DesignKit.xxs) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 12, weight: .medium))
                            Text(config.formattedDuration)
                                .detailText()
                        }
                        .foregroundStyle(DesignKit.textSecondary(for: colorScheme))
                        .padding(.top, DesignKit.xxs)
                    }
                }
            }
            .padding(DesignKit.md)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignKit.large))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                radius: 8,
                x: 0,
                y: 2
            )
            .opacity(compositeItem.isEnabled ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var sleepIconView: some View {
        ZStack {
            // Background circle with sleep-themed gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            tintColor.opacity(0.2),
                            tintColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
            
            // Icon
            Image(systemName: "bed.double.fill")
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(tintColor)
                .frame(width: 28, height: 28)
        }
    }
    
    // MARK: - Time Info View
    
    @ViewBuilder
    private func timeInfoView(icon: String, label: String, time: TimeOfDay?, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignKit.xxs) {
            // Label with icon
            HStack(spacing: DesignKit.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(iconColor)
                
                Text(label.uppercased())
                    .SmallText()
                    .foregroundStyle(DesignKit.textSecondary(for: colorScheme))
            }
            
            // Time display - Hero element
            if let time = time {
                Text(time.formatted(as: .hourMinute))
                    .timeDisplay()
                    .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
            } else {
                Text("--:--")
                    .timeDisplay()
                    .foregroundStyle(DesignKit.textTertiary(for: colorScheme))
            }
        }
    }
    
    // MARK: - Card Background
    
    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            // Base material background
            RoundedRectangle(cornerRadius: DesignKit.large)
                .fill(.ultraThinMaterial)
            
            // Subtle color tint based on tint color
            RoundedRectangle(cornerRadius: DesignKit.large)
                .fill(
                    LinearGradient(
                        colors: [
                            tintColor.opacity(colorScheme == .dark ? 0.08 : 0.04),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Subtle border
            RoundedRectangle(cornerRadius: DesignKit.large)
                .strokeBorder(
                    tintColor.opacity(colorScheme == .dark ? 0.15 : 0.1),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Preview

#Preview("Enabled Sleep Schedule") {
    let sleepConfig = SleepScheduleConfiguration(
        bedtime: TimeOfDay(hour: 22, minute: 0),  // 10:00 PM
        wakeTime: TimeOfDay(hour: 6, minute: 30)  // 6:30 AM
    )
    
    let compositeTicker = CompositeTicker(
        label: "Sleep Schedule",
        compositeType: .sleepSchedule,
        configuration: .sleepSchedule(sleepConfig),
        presentation: TickerPresentation(tintColorHex: "#6366F1"),
        tickerData: TickerData(
            name: "Sleep Schedule",
            icon: "bed.double.fill",
            colorHex: "#6366F1"
        ),
        isEnabled: true
    )
    
    return SleepScheduleCell(compositeItem: compositeTicker) {
        print("Tapped sleep schedule")
    }
    .padding()
    .background(
        ZStack {
            DesignKit.liquidGlassGradient(for: .dark)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    )
}

#Preview("Disabled Sleep Schedule") {
    let sleepConfig = SleepScheduleConfiguration(
        bedtime: TimeOfDay(hour: 23, minute: 30),  // 11:30 PM
        wakeTime: TimeOfDay(hour: 7, minute: 0)     // 7:00 AM
    )
    
    let compositeTicker = CompositeTicker(
        label: "Weekend Sleep",
        compositeType: .sleepSchedule,
        configuration: .sleepSchedule(sleepConfig),
        presentation: TickerPresentation(tintColorHex: "#8B5CF6"),
        tickerData: TickerData(
            name: "Weekend Sleep",
            icon: "bed.double.fill",
            colorHex: "#8B5CF6"
        ),
        isEnabled: false
    )
    
    return SleepScheduleCell(compositeItem: compositeTicker) {
        print("Tapped disabled sleep schedule")
    }
    .padding()
    .background(
        ZStack {
            DesignKit.liquidGlassGradient(for: .dark)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    )
}

#Preview("Light Mode") {
    let sleepConfig = SleepScheduleConfiguration(
        bedtime: TimeOfDay(hour: 21, minute: 30),  // 9:30 PM
        wakeTime: TimeOfDay(hour: 6, minute: 0)     // 6:00 AM
    )
    
    let compositeTicker = CompositeTicker(
        label: "Early Sleep Schedule",
        compositeType: .sleepSchedule,
        configuration: .sleepSchedule(sleepConfig),
        presentation: TickerPresentation(tintColorHex: "#6366F1"),
        tickerData: TickerData(
            name: "Early Sleep Schedule",
            icon: "bed.double.fill",
            colorHex: "#6366F1"
        ),
        isEnabled: true
    )
    
    return SleepScheduleCell(compositeItem: compositeTicker) {
        print("Tapped sleep schedule")
    }
    .padding()
    .background(
        ZStack {
            DesignKit.liquidGlassGradient(for: .light)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    )
    .preferredColorScheme(.light)
}
