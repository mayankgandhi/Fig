//
//  TickerCollectionEditorViewModel.swift
//  fig
//
//  ViewModel for TickerCollectionEditor
//

import Foundation
import SwiftData
import TickerCore
import Factory

@Observable
final class TickerCollectionEditorViewModel {
    // MARK: - Dependencies
    @ObservationIgnored
    @Injected(\.tickerCollectionService) private var tickerCollectionService
    
    private var modelContext: ModelContext
    
    // MARK: - Child ViewModels
    var labelViewModel: LabelEditorViewModel
    var iconPickerViewModel: IconPickerViewModel
    var optionsPillsViewModel: OptionsPillsViewModel
    
    // MARK: - State
    var childTickerData: [CollectionChildTickerData] = []
    var isSaving: Bool = false
    var errorMessage: String?
    var showingError: Bool = false
    let isEditMode: Bool
    private var tickerCollectionToEdit: TickerCollection?
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        tickerCollectionToEdit: TickerCollection? = nil,
        isEditMode: Bool = false
    ) {
        self.modelContext = modelContext
        self.tickerCollectionToEdit = tickerCollectionToEdit
        self.isEditMode = isEditMode
        
        // Initialize child ViewModels
        self.labelViewModel = LabelEditorViewModel()
        self.iconPickerViewModel = IconPickerViewModel()
        self.optionsPillsViewModel = OptionsPillsViewModel()
        
        // Configure OptionsPillsViewModel
        self.optionsPillsViewModel.configure(
            schedule: nil,
            label: labelViewModel,
            countdown: nil,
            sound: nil,
            icon: iconPickerViewModel
        )
        
        // Prefill if editing
        if let collection = tickerCollectionToEdit {
            prefillFromComposite(collection)
        }
    }
    
    // MARK: - Computed Properties
    
    var canSave: Bool {
        labelViewModel.isValid && !childTickerData.isEmpty
    }
    
    var validationMessages: [String] {
        var messages: [String] = []
        
        if !labelViewModel.isValid {
            messages.append("Label must be 50 characters or fewer")
        }
        if childTickerData.isEmpty {
            messages.append("Add at least one child ticker")
        }
        
        return messages
    }
    
    var formattedTime: String {
        // For collection editor, show child count instead of time
        if childTickerData.isEmpty {
            return "No tickers"
        } else if childTickerData.count == 1 {
            return "1 ticker"
        } else {
            return "\(childTickerData.count) tickers"
        }
    }
    
    // MARK: - Child Ticker Data Management

    func addChildTickerData(_ data: CollectionChildTickerData) {
        childTickerData.append(data)
    }

    func updateChildTickerData(_ data: CollectionChildTickerData) {
        if let index = childTickerData.firstIndex(where: { $0.id == data.id }) {
            childTickerData[index] = data
        }
    }

    func removeChildTickerData(_ data: CollectionChildTickerData) {
        childTickerData.removeAll { $0.id == data.id }
    }

    func removeChildTickerData(at index: Int) {
        guard index < childTickerData.count else { return }
        childTickerData.remove(at: index)
    }
    
    // MARK: - Save
    
    func saveTickerCollection() async {
        guard !isSaving else { return }
        guard canSave else {
            errorMessage = "Please check your inputs"
            showingError = true
            return
        }
        
        isSaving = true
        defer {
            isSaving = false
        }
        
        do {
            let label = labelViewModel.labelText.isEmpty ? "Ticker Collection" : labelViewModel.labelText
            let icon = iconPickerViewModel.selectedIcon
            let colorHex = iconPickerViewModel.selectedColorHex

            // Build presentation for child tickers
            let presentation = TickerPresentation(
                tintColorHex: colorHex,
                secondaryButtonType: .none
            )

            // Convert CollectionChildTickerData to Ticker objects
            let tickers = childTickerData.map { data in
                data.toTicker(presentation: presentation, icon: icon, colorHex: colorHex)
            }

            if isEditMode, let existingComposite = tickerCollectionToEdit {
                // Update existing collection
                try await tickerCollectionService.updateCustomTickerCollection(
                    existingComposite,
                    label: label,
                    icon: icon,
                    colorHex: colorHex,
                    childTickers: tickers,
                    modelContext: modelContext
                )
            } else {
                // Create new collection
                _ = try await tickerCollectionService.createCustomTickerCollection(
                    label: label,
                    icon: icon,
                    colorHex: colorHex,
                    childTickers: tickers,
                    modelContext: modelContext
                )
            }

            TickerHaptics.success()
        } catch {
            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    // MARK: - Private Methods
    
    private func prefillFromComposite(_ collection: TickerCollection) {
        // Prefill label
        labelViewModel.setText(collection.label)
        
        // Prefill icon and color
        if let tickerData = collection.tickerData {
            let icon = tickerData.icon ?? "alarm"
            let colorHex = tickerData.colorHex ?? "#8B5CF6"
            iconPickerViewModel.selectIcon(icon, colorHex: colorHex)
        } else {
            iconPickerViewModel.selectIcon("alarm", colorHex: "#8B5CF6")
        }
        
        // Convert existing Tickers to CollectionChildTickerData for editing
        if let children = collection.childTickers {
            childTickerData = children.compactMap { ticker in
                guard let schedule = ticker.schedule else { return nil }
                return CollectionChildTickerData(
                    id: ticker.id,
                    label: ticker.label,
                    schedule: schedule
                )
            }
        }
    }
}

