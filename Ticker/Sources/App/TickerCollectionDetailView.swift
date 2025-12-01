//
//  TickerCollectionDetailView.swift
//  Ticker
//
//  Detail view for ticker collections showing child alarms
//  Redesigned to match AlarmDetailView design system
//

import SwiftUI
import SwiftData
import TickerCore
import Factory

struct TickerCollectionDetailView: View {
    let tickerCollection: TickerCollection
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Injected(\.tickerService) private var tickerService
    @Injected(\.tickerCollectionService) private var collectionService

    @State private var isToggling = false
    @State private var alarmToShowDetail: Ticker?
    @State private var alarmToDelete: Ticker?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.xl) {
                    // Header with icon and label
                    CollectionDetailHeader(
                        tickerCollection: tickerCollection,
                        tickerService: tickerService
                    )

                    // Options display with enhanced styling
                    CollectionDetailOptionsSection(tickerCollection: tickerCollection)
                        .padding(.top, TickerSpacing.sm)

                    // Child tickers section
                    CollectionChildTickersSection(
                        tickerCollection: tickerCollection,
                        onToggle: { ticker, enabled in
                            await toggleChildTicker(ticker, enabled: enabled)
                        },
                        isToggling: $isToggling,
                        onTickerTap: { ticker in
                            alarmToShowDetail = ticker
                        }
                    )
                    .padding(.top, TickerSpacing.sm)
                }
                .padding(TickerSpacing.md)
                .padding(.bottom, TickerSpacing.xl)
            }
            .background(
                ZStack {
                    TickerColor.liquidGlassGradient(for: colorScheme)
                        .ignoresSafeArea()

                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.1)
                        .ignoresSafeArea()
                }
            )
            .navigationTitle("Collection Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        TickerHaptics.selection()
                        onEdit()
                        dismiss()
                    } label: {
                        Image(systemName: "pencil")
                            .Callout()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    }

                    Button(role: .destructive) {
                        TickerHaptics.selection()
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .Callout()
                            .foregroundStyle(.red)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $alarmToShowDetail) { ticker in
            AlarmDetailView(
                alarm: ticker,
                onEdit: {
                    // For child tickers, we might want to handle editing differently
                    // For now, just dismiss the detail view
                    alarmToShowDetail = nil
                },
                onDelete: {
                    alarmToDelete = ticker
                    showDeleteAlert = true
                }
            )
            .presentationCornerRadius(TickerRadius.large)
            .presentationBackground {
                ZStack {
                    TickerColor.liquidGlassGradient(for: colorScheme)
                    
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                }
            }
        }
        .alert("Delete Ticker", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                alarmToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let ticker = alarmToDelete {
                    TickerHaptics.warning()
                    Task {
                        try? await tickerService.cancelAlarm(id: ticker.id, context: modelContext)
                    }
                }
                alarmToDelete = nil
                alarmToShowDetail = nil
            }
        } message: {
            if let ticker = alarmToDelete {
                Text("Are you sure you want to delete \"\(ticker.label)\"? This action cannot be undone.")
            }
        }
    }

    // MARK: - Actions

    private func toggleChildTicker(_ ticker: Ticker, enabled: Bool) async {
        guard !isToggling else { return }
        isToggling = true
        defer { isToggling = false }

        do {
            try await collectionService.toggleChildTicker(
                tickerCollection,
                childID: ticker.id,
                enabled: enabled,
                modelContext: modelContext
            )
        } catch {
            print("Failed to toggle child ticker: \(error)")
        }
    }
}
