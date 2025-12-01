//
//  AddToCollectionViewModel.swift
//  fig
//
//  ViewModel for AddToCollectionView
//

import Foundation
import SwiftData
import TickerCore
import Factory

@Observable
final class AddToCollectionViewModel {
    // MARK: - Dependencies
    @ObservationIgnored
    @Injected(\.tickerCollectionService) private var tickerCollectionService
    
    private var modelContext: ModelContext
    private let tickerToAdd: Ticker
    
    // MARK: - State
    var availableCollections: [TickerCollection] = []
    var isSaving: Bool = false
    var errorMessage: String?
    var showingError: Bool = false
    var showCreateNewCollection: Bool = false
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        tickerToAdd: Ticker
    ) {
        self.modelContext = modelContext
        self.tickerToAdd = tickerToAdd
        loadAvailableCollections()
    }
    
    // MARK: - Public Methods
    
    func loadAvailableCollections() {
        let descriptor = FetchDescriptor<TickerCollection>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let allCollections = try modelContext.fetch(descriptor)
            // Filter to only custom collections (exclude sleep schedules)
            availableCollections = allCollections.filter { $0.collectionType == .custom }
        } catch {
            print("❌ Failed to fetch collections: \(error)")
            availableCollections = []
        }
    }
    
    func addToExistingCollection(_ collection: TickerCollection) async {
        guard !isSaving else { return }
        
        isSaving = true
        defer {
            isSaving = false
        }
        
        do {
            try await tickerCollectionService.addTickerToCollection(
                tickerToAdd,
                collection: collection,
                modelContext: modelContext
            )
            
            TickerHaptics.success()
        } catch {
            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func addToNewCollection(
        label: String,
        icon: String,
        colorHex: String
    ) async {
        guard !isSaving else { return }
        
        isSaving = true
        defer {
            isSaving = false
        }
        
        do {
            _ = try await tickerCollectionService.addTickerToNewCollection(
                tickerToAdd,
                label: label,
                icon: icon,
                colorHex: colorHex,
                modelContext: modelContext
            )
            
            // Reload collections after creating new one
            loadAvailableCollections()
            
            TickerHaptics.success()
        } catch {
            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

