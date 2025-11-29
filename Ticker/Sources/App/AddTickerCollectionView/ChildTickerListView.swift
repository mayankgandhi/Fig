//
//  ChildTickerListView.swift
//  fig
//
//  List view for displaying and managing child tickers in composite editor
//

import SwiftUI
import SwiftData
import TickerCore
import DesignKit

struct ChildTickerListView: View {
    let childTickers: [Ticker]
    let onEdit: (Ticker) -> Void
    let onDelete: (Ticker) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Section header
            HStack {
                Text("TICKERS")
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)
                
                Spacer()
                
                if !childTickers.isEmpty {
                    Text("\(childTickers.count)")
                        .Caption2()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, TickerSpacing.md)
            
            if childTickers.isEmpty {
                emptyStateView
            } else {
                tickerList
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
            
            Text("Add tickers to create a composite alarm")
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
    
    // MARK: - Ticker List
    
    private var tickerList: some View {
        VStack(spacing: TickerSpacing.sm) {
            ForEach(Array(childTickers.enumerated()), id: \.element.id) { index, ticker in
                childTickerRow(ticker: ticker, index: index)
            }
        }
        .padding(.horizontal, TickerSpacing.md)
    }
    
    // MARK: - Child Ticker Row
    
    private func childTickerRow(ticker: Ticker, index: Int) -> some View {
        HStack(spacing: TickerSpacing.md) {
            // Icon
            iconView(ticker: ticker)
            
            // Content
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(ticker.label)
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
                
                if let schedule = ticker.schedule {
                    HStack(spacing: TickerSpacing.xxs) {
                        Image(systemName: schedule.icon)
                            .font(.system(size: 10, weight: .medium))
                        Text(schedule.displaySummary)
                            .Caption()
                    }
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: TickerSpacing.sm) {
                // Edit button
                Button {
                    TickerHaptics.selection()
                    onEdit(ticker)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TickerColor.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(TickerColor.primary.opacity(0.1))
                        )
                }
                
                // Delete button
                Button {
                    TickerHaptics.selection()
                    onDelete(ticker)
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
        .padding(TickerSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColor.surface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .strokeBorder(
                    TickerColor.textTertiary(for: colorScheme).opacity(0.2),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Icon View
    
    @ViewBuilder
    private func iconView(ticker: Ticker) -> some View {
        let iconColor = iconColor(for: ticker)
        let iconName = iconName(for: ticker)
        
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 40, height: 40)
            
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(iconColor)
        }
    }
    
    private func iconColor(for ticker: Ticker) -> Color {
        if let tickerData = ticker.tickerData, let colorHex = tickerData.colorHex {
            return Color(hex: colorHex) ?? TickerColor.primary
        }
        return TickerColor.primary
    }
    
    private func iconName(for ticker: Ticker) -> String {
        if let tickerData = ticker.tickerData, let icon = tickerData.icon {
            return icon
        }
        return "alarm"
    }
}

