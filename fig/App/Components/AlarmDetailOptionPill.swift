//
//  AlarmDetailOptionPill.swift
//  fig
//
//  Option pill component for displaying individual alarm options
//

import SwiftUI
import TickerCore

struct AlarmDetailOptionPill: View {
    let icon: String
    let title: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: TickerSpacing.xxs) {
            Image(systemName: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

            Text(title)
                .Footnote()
                .lineLimit(1)
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
        }
        .padding(.horizontal, TickerSpacing.sm)
        .padding(.vertical, TickerSpacing.xs)
        .background(TickerColor.surface(for: colorScheme).opacity(0.7))
        .background(.ultraThinMaterial.opacity(0.3))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: TickerSpacing.sm) {
        AlarmDetailOptionPill(icon: "calendar", title: "Every day")
        AlarmDetailOptionPill(icon: "repeat", title: "Daily")
        AlarmDetailOptionPill(icon: "tag", title: "Morning Workout")
        AlarmDetailOptionPill(icon: "timer", title: "5m")
    }
    .padding()
}
