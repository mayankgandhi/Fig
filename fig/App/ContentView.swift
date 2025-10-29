/*
 See the LICENSE.txt file for this sample's licensing information.
 
 Abstract:
 The main content view of the app showing the list of alarms.
 */

import SwiftUI
import SwiftData
import TickerCore

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(TickerService.self) private var tickerService
    
    @State private var showAddSheet = false
    @State private var showNaturalLanguageSheet = false
    @State private var alarmToEdit: Ticker?
    @State private var alarmToDelete: Ticker?
    @State private var alarmToShowDetail: Ticker?
    @State private var showDeleteAlert = false
    @Namespace private var addButtonNamespace
    @Namespace private var editButtonNamespace
    @Namespace private var aiButtonNamespace
    
    @State private var viewModel: TickerListViewModel?
    
    var body: some View {
        NavigationStack {
            if let vm = viewModel {
                content(viewModel: vm)
                    .background(backgroundView)
                    .navigationTitle(Text("Tickers"))
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .searchable(text: Binding(
                        get: { vm.searchText },
                        set: { vm.searchText = $0 }
                    ), prompt: "Search tickers...")
                    .toolbar {
                        ToolbarItemGroup(placement: .primaryAction) {
                            ToolbarButtonsView(
                                showAddSheet: $showAddSheet,
                                showNaturalLanguageSheet: $showNaturalLanguageSheet,
                                namespace: addButtonNamespace
                            )
                        }
                    }
            } else {
                ProgressView()
            }
        }
        .sheet(isPresented: $showNaturalLanguageSheet) {
            NaturalLanguageTickerView()
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationBackground {
                    sheetBackground
                }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTickerView(namespace: addButtonNamespace)
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationBackground {
                    sheetBackground
                }
        }
        .sheet(item: $alarmToEdit) { ticker in
            AddTickerView(namespace: editButtonNamespace, prefillTemplate: ticker, isEditMode: true)
                .presentationCornerRadius(TickerRadius.large)
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
            .presentationCornerRadius(TickerRadius.large)
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
                    TickerHaptics.warning()
                    if let index = viewModel?.displayAlarms.firstIndex(where: { $0.id == ticker.id }) {
                        viewModel?.deleteAlarms(at: IndexSet(integer: index))
                    }
                }
                alarmToDelete = nil
            }
        } message: {
            if let ticker = alarmToDelete {
                Text("Are you sure you want to delete \"\(ticker.label)\"? This action cannot be undone.")
            }
        }
        .tint(TickerColor.primary)
        .onAppear {
            initializeViewModel()
        }
        .onChange(of: tickerService.alarms) { _, _ in
            viewModel?.loadAlarms()
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundView: some View {
        ZStack {
            TickerColor.liquidGlassGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    }
    
    private var sheetBackground: some View {
        ZStack {
            TickerColor.liquidGlassGradient(for: colorScheme)
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        }
    }
    
    // MARK: - Private Methods
    
    private func initializeViewModel() {
        if viewModel == nil {
            viewModel = TickerListViewModel(tickerService: tickerService, modelContext: modelContext)
            viewModel?.loadAlarms()
        }
    }
    
    
    @ViewBuilder
    func content(viewModel: TickerListViewModel) -> some View {
        VStack {
            if !viewModel.filteredAlarms.isEmpty {
                TickerListView(
                    tickers: viewModel.filteredAlarms,
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
            } else if !viewModel.displayAlarms.isEmpty && viewModel.searchText.isEmpty {
                TickerListView(
                    tickers: viewModel.displayAlarms,
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
                    isEmpty: viewModel.searchText.isEmpty,
                    searchText: viewModel.searchText,
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
