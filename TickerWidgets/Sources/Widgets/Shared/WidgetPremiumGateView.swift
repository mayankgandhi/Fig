//
//  WidgetPremiumGateView.swift
//  TickerWidgets
//
//  Premium gate view for widgets when feature is locked
//

import SwiftUI
import WidgetKit
import TickerCore
import Gate

struct WidgetPremiumGateView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily
    
    let feature: PremiumFeature
    
    var body: some View {
        VStack(spacing: TickerSpacing.sm) {
            // Icon
            Image(systemName: feature.icon)
                .font(
                    .system(
                        size: widgetFamily == .systemSmall ? 24 : 32,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(TickerColor.primary)
                .padding(.bottom, TickerSpacing.xs)

            // Title
            titleView
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Description
            descriptionView
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(widgetFamily == .systemSmall ? 2 : 3)

            // Pro badge
            proBadge
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(TickerSpacing.sm)
        .containerBackground(for: .widget) {
            TickerColor.liquidGlassGradient(for: colorScheme)
        }
    }
}

private extension WidgetPremiumGateView {

    @ViewBuilder
    var titleView: some View {
        if widgetFamily == .systemSmall {
            Text(feature.title)
                .Subheadline()
        } else {
            Text(feature.title)
                .Title3()
        }
    }

    @ViewBuilder
    var descriptionView: some View {
        if widgetFamily == .systemSmall {
            Text(feature.description)
                .Caption2()
        } else {
            Text(feature.description)
                .Footnote()
        }
    }

    @ViewBuilder
    var proBadge: some View {
        HStack(spacing: TickerSpacing.xxs) {
            Image(systemName: "crown.fill")
                .font(
                    .system(
                        size: widgetFamily == .systemSmall ? 10 : 12,
                        weight: .semibold,
                        design: .rounded
                    )
                )

            if widgetFamily == .systemSmall {
                Text("Pro")
                    .Caption2()
            } else {
                Text("Pro")
                    .Caption()
            }
        }
        .foregroundStyle(TickerColor.primary)
        .padding(.horizontal, TickerSpacing.xs)
        .padding(.vertical, TickerSpacing.xxs)
        .background(
            Capsule()
                .fill(TickerColor.primary.opacity(0.15))
        )
    }
}

