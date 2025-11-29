//
//  ChildTickerDataListView.swift
//  fig
//
//  List view for displaying and managing child ticker data in collection editor
//  Works with CollectionChildTickerData instead of full Ticker objects
//

import SwiftUI
import TickerCore
import DesignKit

struct ChildTickerDataListView: View {
    let childData: [CollectionChildTickerData]
    let icon: String
    let colorHex: String
    let onEdit: (CollectionChildTickerData) -> Void
    let onDelete: (CollectionChildTickerData) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Section header
            HStack {
                Text("TICKER LIST")
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer()

                if !childData.isEmpty {
                    Text("\(childData.count)")
                        .Caption2()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, TickerSpacing.md)

            if childData.isEmpty {
                emptyStateView
            } else {
                dataList
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

            Text("Add tickers to create a collection")
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

    // MARK: - Data List

    private var dataList: some View {
        VStack(spacing: TickerSpacing.sm) {
            ForEach(Array(childData.enumerated()), id: \.element.id) { index, data in
                childDataRow(data: data, index: index)
            }
        }
        .padding(.horizontal, TickerSpacing.md)
    }

    // MARK: - Child Data Row

    private func childDataRow(data: CollectionChildTickerData, index: Int) -> some View {
        HStack(spacing: TickerSpacing.md) {
            // Icon (inherited from parent)
            iconView

            // Content
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(data.label)
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .lineLimit(1)

                HStack(spacing: TickerSpacing.xxs) {
                    Image(systemName: data.schedule.icon)
                        .font(.system(size: 10, weight: .medium))
                    Text(data.schedule.displaySummary)
                        .Caption()
                }
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }

            Spacer()

            // Actions
            HStack(spacing: TickerSpacing.sm) {
                // Edit button
                Button {
                    TickerHaptics.selection()
                    onEdit(data)
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
                    onDelete(data)
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
    private var iconView: some View {
        let iconColor = Color(hex: colorHex) ?? TickerColor.primary

        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(iconColor)
        }
    }
}

// MARK: - Preview

#Preview {
    ChildTickerDataListView(
        childData: [
            CollectionChildTickerData(
                label: "Wake up",
                schedule: .daily(time: TimeOfDay(hour: 7, minute: 0))
            ),
            CollectionChildTickerData(
                label: "Bedtime",
                schedule: .daily(time: TimeOfDay(hour: 22, minute: 30))
            )
        ],
        icon: "moon.stars",
        colorHex: "#8B5CF6",
        onEdit: { _ in },
        onDelete: { _ in }
    )
    .padding()
}
