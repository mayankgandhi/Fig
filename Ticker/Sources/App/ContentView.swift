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
import Factory

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Injected(\.tickerService) private var tickerService
    @Injected(\.tickerCollectionService) private var tickerCollectionService
    @EnvironmentObject private var modelContextObserver: ModelContextObserver

    // Direct SwiftData queries - auto-updates when data changes
    @Query(sort: \Ticker.createdAt, order: .reverse) private var allTickers: [Ticker]
    @Query(sort: \TickerCollection.createdAt, order: .reverse) private var allTickerCollections: [TickerCollection]

    @State private var showAddSheet = false
    @State private var showNaturalLanguageSheet = false
    @State private var showAddSleepScheduleSheet = false
    @State private var showAddCollectionSheet = false
    @State private var alarmToEdit: Ticker?
    @State private var alarmToDelete: Ticker?
    @State private var alarmToShowDetail: Ticker?
    @State private var collectionToShowDetail: TickerCollection?
    @State private var collectionToEdit: TickerCollection?
    @State private var collectionToDelete: TickerCollection?
    @State private var showDeleteAlert = false
    @State private var showDeleteCompositeAlert = false
    @State private var searchText = ""
    
    @Namespace private var addButtonNamespace
    @Namespace private var editButtonNamespace
    @Namespace private var aiButtonNamespace
    @Namespace private var collectionButtonNamespace

    // Type alias for cleaner code
    private typealias AlarmListItem = UnifiedAlarmListView.AlarmListItem

    // Filter standalone tickers (exclude children of ticker collections)
    private var standaloneTickers: [Ticker] {
        allTickers.filter { $0.parentTickerCollection == nil }
    }

    // Combined and sorted alarm items
    private var allAlarmItems: [AlarmListItem] {
        var items: [AlarmListItem] = []

        // Add standalone tickers
        items.append(contentsOf: standaloneTickers.map { .ticker($0) })

        // Add ticker collections
        items.append(contentsOf: allTickerCollections.map { .collection($0) })

        // Sort by creation date (most recent first)
        return items.sorted { item1, item2 in
            let date1: Date
            let date2: Date

            switch item1 {
            case .ticker(let ticker): date1 = ticker.createdAt
            case .collection(let collection): date1 = collection.createdAt
            }

            switch item2 {
            case .ticker(let ticker): date2 = ticker.createdAt
            case .collection(let collection): date2 = collection.createdAt
            }

            return date1 > date2
        }
    }

    // Filter alarm items based on search text
    private var filteredAlarmItems: [AlarmListItem] {
        guard !searchText.isEmpty else { return allAlarmItems }
        return allAlarmItems.filter { item in
            let label: String
            switch item {
            case .ticker(let ticker): label = ticker.label
            case .collection(let collection): label = collection.label
            }
            return label.localizedCaseInsensitiveContains(searchText)
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
                            showAddSleepScheduleSheet: $showAddSleepScheduleSheet,
                            showAddCollectionSheet: $showAddCollectionSheet,
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
        .sheet(item: $collectionToShowDetail) { collection in
            NavigationStack {
                TickerCollectionDetailContainerView(tickerCollection: collection)
            }
            .presentationCornerRadius(DesignKit.large)
            .presentationBackground {
                sheetBackground
            }
        }
        .sheet(isPresented: $showAddSleepScheduleSheet) {
            SleepScheduleEditor(
                viewModel: SleepScheduleViewModel()
            )
            .presentationCornerRadius(DesignKit.large)
            .presentationDragIndicator(.visible)
            .presentationBackground {
                sheetBackground
            }
        }
        .sheet(item: $collectionToEdit) { collection in
            if collection.collectionType == .sleepSchedule,
               let config = collection.sleepScheduleConfig {
                SleepScheduleEditor(
                    viewModel: SleepScheduleViewModel(
                        bedtime: config.bedtime,
                        wakeTime: config.wakeTime,
                        presentation: collection.presentation,
                        tickerCollectionToUpdate: collection
                    )
                )
                .presentationCornerRadius(DesignKit.large)
                .presentationDragIndicator(.visible)
                .presentationBackground {
                    sheetBackground
                }
            } else if collection.collectionType == .custom {
                TickerCollectionEditor(
                    namespace: collectionButtonNamespace,
                    tickerCollection: collection,
                    isEditMode: true
                )
                .presentationCornerRadius(DesignKit.large)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationBackground {
                    sheetBackground
                }
            }
        }
        .sheet(isPresented: $showAddCollectionSheet) {
            TickerCollectionEditor(namespace: collectionButtonNamespace)
                .presentationCornerRadius(DesignKit.large)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
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
        .alert("Delete Sleep Schedule", isPresented: $showDeleteCompositeAlert) {
            Button("Cancel", role: .cancel) {
                collectionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let collection = collectionToDelete {
                    DesignKitHaptics.warning()
                    Task {
                        try? await tickerCollectionService.deleteTickerCollection(
                            collection,
                            modelContext: modelContext
                        )
                    }
                }
                collectionToDelete = nil
            }
        } message: {
            if let collection = collectionToDelete {
                Text("Are you sure you want to delete \"\(collection.label)\"? This action cannot be undone.")
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
            if !filteredAlarmItems.isEmpty {
                UnifiedAlarmListView(
                    alarmItems: filteredAlarmItems,
                    onTickerTap: { ticker in
                        alarmToShowDetail = ticker
                    },
                    onCompositeTap: { collection in
                        collectionToShowDetail = collection
                    },
                    onEdit: { ticker in
                        alarmToEdit = ticker
                    },
                    onDelete: { ticker in
                        alarmToDelete = ticker
                        showDeleteAlert = true
                    },
                    onEditComposite: { collection in
                        if collection.collectionType == .sleepSchedule || collection.collectionType == .custom {
                            collectionToEdit = collection
                        } else {
                            // For other collection types, open detail view
                            collectionToShowDetail = collection
                        }
                    },
                    onDeleteComposite: { collection in
                        collectionToDelete = collection
                        showDeleteCompositeAlert = true
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
    @Previewable @Injected(\.tickerService) var tickerService
    ContentView()
        .environment(tickerService)
}
