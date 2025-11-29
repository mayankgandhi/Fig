//
//  CollectionChildTickersSection.swift
//  fig
//
//  Styled section for displaying child tickers in collection detail view
//

import SwiftUI
import SwiftData
import TickerCore
import Factory

struct CollectionChildTickersSection: View {
    let tickerCollection: TickerCollection
    let onToggle: (Ticker, Bool) async -> Void
    let onTickerTap: ((Ticker) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isToggling: Bool
    
    init(
        tickerCollection: TickerCollection,
        onToggle: @escaping (Ticker, Bool) async -> Void,
        isToggling: Binding<Bool>,
        onTickerTap: ((Ticker) -> Void)? = nil
    ) {
        self.tickerCollection = tickerCollection
        self.onToggle = onToggle
        self._isToggling = isToggling
        self.onTickerTap = onTickerTap
    }
    
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
                
                if let children = tickerCollection.childTickers, !children.isEmpty {
                    Text("\(children.count)")
                        .Caption2()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, TickerSpacing.md)
            
            if let children = tickerCollection.childTickers, !children.isEmpty {
                VStack(spacing: TickerSpacing.sm) {
                    ForEach(children) { child in
                        AlarmCell(
                            alarmItem: child,
                            onTap: {
                                onTickerTap?(child)
                            }
                        )
                    }
                }
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: TickerSpacing.sm) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
            
            Text("No tickers")
                .Headline()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(TickerSpacing.xl)
        .background(TickerColor.surface(for: colorScheme).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isToggling = false
    
    CollectionChildTickersSection(
        tickerCollection: TickerCollection(
            label: "Sleep Schedule",
            collectionType: .sleepSchedule
        ),
        onToggle: { _, _ in },
        isToggling: $isToggling,
        onTickerTap: nil
    )
    .padding()
}

