/*
 See the LICENSE.txt file for this sample's licensing information.
 
 Abstract:
 The main content view of the app showing the list of alarms.
 */

import SwiftUI
import SwiftData
import TickerCore
import Gate
import DesignKit

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(TickerService.self) private var tickerService
    @EnvironmentObject private var modelContextObserver: ModelContextObserver

    // Direct SwiftData query - auto-updates when data changes
    @Query(sort: \Ticker.createdAt, order: .reverse) private var allTickers: [Ticker]

    @State private var showAddSheet = false
    @State private var showNaturalLanguageSheet = false
    @State private var alarmToEdit: Ticker?
    @State private var alarmToDelete: Ticker?
    @State private var alarmToShowDetail: Ticker?
    @State private var showDeleteAlert = false
    @State private var searchText = ""
    @Namespace private var addButtonNamespace
    @Namespace private var editButtonNamespace
    @Namespace private var aiButtonNamespace

    // Filter tickers based on search text
    private var filteredTickers: [Ticker] {
        guard !searchText.isEmpty else { return allTickers }
        return allTickers.filter { ticker in
            ticker.label.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            content
                .background(backgroundView)
                .navigationTitle(Text("Tickers"))
                .toolbarTitleDisplayMode(.inlineLarge)
                .searchable(text: $searchText, prompt: "Search tickers...")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        ToolbarButtonsView(
                            showAddSheet: $showAddSheet,
                            showNaturalLanguageSheet: $showNaturalLanguageSheet,
                            namespace: addButtonNamespace
                        )
                    }
                }
        }
        .sheet(isPresented: $showNaturalLanguageSheet) {
            SubscriptionGate(feature: .aiAlarmCreation) {
                NaturalLanguageTickerView()
            }
            .presentationCornerRadius(DesignKit.large)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
            .presentationBackground {
                sheetBackground
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTickerView(namespace: addButtonNamespace)
                .presentationCornerRadius(DesignKit.large)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationBackground {
                    sheetBackground
                }
        }
        .sheet(item: $alarmToEdit) { ticker in
            AddTickerView(namespace: editButtonNamespace, prefillTickerId: ticker.persistentModelID, isEditMode: true)
                .presentationCornerRadius(DesignKit.large)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationBackground {
                    sheetBackground
                }
        }
        .sheet(item: $alarmToShowDetail) { ticker in
            AlarmDetailView(
                alarm: ticker,
                onEdit: {
                    alarmToEdit = ticker
                },
                onDelete: {
                    alarmToDelete = ticker
                    showDeleteAlert = true
                }
            )
            .presentationCornerRadius(DesignKit.large)
            .presentationBackground {
                sheetBackground
            }
        }
        .alert("Delete Ticker", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                alarmToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let ticker = alarmToDelete {
                    DesignKitHaptics.warning()
                    Task {
                        try? await tickerService.cancelAlarm(id: ticker.id, context: modelContext)
                    }
                }
                alarmToDelete = nil
            }
        } message: {
            if let ticker = alarmToDelete {
                Text("Are you sure you want to delete \"\(ticker.label)\"? This action cannot be undone.")
            }
        }
        .tint(DesignKit.primary)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundView: some View {
        ZStack {
            DesignKit.liquidGlassGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    }
    
    private var sheetBackground: some View {
        ZStack {
            DesignKit.liquidGlassGradient(for: colorScheme)
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        }
    }
    
    // MARK: - Private Methods

    @ViewBuilder
    private var content: some View {
        VStack {
            if !filteredTickers.isEmpty {
                TickerListView(
                    tickers: filteredTickers,
                    onTap: { ticker in
                        alarmToShowDetail = ticker
                    },
                    onEdit: { ticker in
                        alarmToEdit = ticker
                    },
                    onDelete: { ticker in
                        alarmToDelete = ticker
                        showDeleteAlert = true
                    }
                )
            } else {
                EmptyStateView(
                    isEmpty: searchText.isEmpty,
                    searchText: searchText,
                    onAddTicker: {
                        showAddSheet = true
                    }
                )
            }
        }
    }
    
}

#Preview {
    ContentView()
        .environment(TickerService())
}
