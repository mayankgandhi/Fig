//
//  HourlyConfigView.swift
//  fig
//
//  UI for configuring hourly repetition
//

import SwiftUI
import TickerCore

struct HourlyConfigView: View {
    @Binding var interval: Int
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Example text
            Text("Perfect for regular reminders")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
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
                            ForEach(1...12, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 100)
                        .clipped()
                        
                        Text(interval == 1 ? "hour" : "hours")
                            .Body()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    }
                }
            }
            
            // Helper Text
            Text("Alarms will repeat every \(interval) hour\(interval == 1 ? "" : "s")")
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
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
    
}

#Preview {
    @Previewable @State var interval = 2
    
    HourlyConfigView(interval: $interval)
        .padding()
}
