//
//  EveryConfigView.swift
//  fig
//
//  UI for configuring "every X unit" repetition
//

import SwiftUI

struct EveryConfigView: View {
    @Binding var interval: Int
    @Binding var unit: TickerSchedule.TimeUnit
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Example text
            Text("Perfect for custom intervals")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TickerSpacing.md)
            
            // Unit Picker Section
            configurationSection {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Time Unit")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.8)
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(TickerSchedule.TimeUnit.allCases, id: \.self) { timeUnit in
                            Text(timeUnit.displayName).tag(timeUnit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: unit) { _, _ in
                        TickerHaptics.selection()
                        // Reset interval when unit changes
                        interval = 1
                    }
                }
            }
            
            // Interval Picker Section
            configurationSection {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    Text("Repeat Every")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.8)
                    
                    HStack(spacing: TickerSpacing.sm) {
                        Picker("Interval", selection: $interval) {
                            ForEach(intervalRange, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 100)
                        .clipped()
                        
                        Text(intervalDisplayText)
                            .Body()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    }
                }
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
    
    // MARK: - Helper Properties
    
    private var intervalRange: ClosedRange<Int> {
        switch unit {
            case .minutes:
                return 1...60
            case .hours:
                return 1...24
            case .days:
                return 1...30
            case .weeks:
                return 1...52
        }
    }
    
    private var intervalDisplayText: String {
        interval == 1 ? unit.singularName : unit.displayName.lowercased()
    }
}

#Preview {
    @Previewable @State var interval = 30
    @Previewable @State var unit = TickerSchedule.TimeUnit.minutes
    
    EveryConfigView(interval: $interval, unit: $unit)
        .padding()
}
