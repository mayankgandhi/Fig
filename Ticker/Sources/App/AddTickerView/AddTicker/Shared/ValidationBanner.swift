//
//  ValidationBanner.swift
//  fig
//
//  A reusable validation/warning banner component
//

import SwiftUI
import TickerCore

struct ValidationBanner: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: TickerSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .Subheadline()
                .foregroundStyle(TickerColor.warning)

            Text(message)
                .Footnote()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColor.warning.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .strokeBorder(TickerColor.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ValidationBanner(message: "Selected date doesn't match selected weekdays")
        .padding()
}
