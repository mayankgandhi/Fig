//
//  CompositeTickerEditorViewModel.swift
//  fig
//
//  ViewModel for CompositeTickerEditor
//

import Foundation
import SwiftData
import TickerCore
import Factory

@Observable
final class CompositeTickerEditorViewModel {
    // MARK: - Dependencies
    @ObservationIgnored
    @Injected(\.compositeTickerService) private var compositeTickerService
    
    private var modelContext: ModelContext
    
    // MARK: - Child ViewModels
    var labelViewModel: LabelEditorViewModel
    var iconPickerViewModel: IconPickerViewModel
    var optionsPillsViewModel: OptionsPillsViewModel
    
    // MARK: - State
    var childTickers: [Ticker] = []
    var isSaving: Bool = false
    var errorMessage: String?
    var showingError: Bool = false
    let isEditMode: Bool
    private var compositeTickerToEdit: CompositeTicker?
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        compositeTickerToEdit: CompositeTicker? = nil,
        isEditMode: Bool = false
    ) {
        self.modelContext = modelContext
        self.compositeTickerToEdit = compositeTickerToEdit
        self.isEditMode = isEditMode
        
        // Initialize child ViewModels
        self.labelViewModel = LabelEditorViewModel()
        self.iconPickerViewModel = IconPickerViewModel()
        self.optionsPillsViewModel = OptionsPillsViewModel()
        
        // Configure OptionsPillsViewModel
        self.optionsPillsViewModel.configure(
            schedule: ScheduleViewModel(), // Not used but required
            label: labelViewModel,
            countdown: CountdownConfigViewModel(), // Not used but required
            sound: SoundPickerViewModel(), // Not used but required
            icon: iconPickerViewModel
        )
        
        // Prefill if editing
        if let composite = compositeTickerToEdit {
            prefillFromComposite(composite)
        }
    }
    
    // MARK: - Computed Properties
    
    var canSave: Bool {
        labelViewModel.isValid && !childTickers.isEmpty
    }
    
    var validationMessages: [String] {
        var messages: [String] = []
        
        if !labelViewModel.isValid {
            messages.append("Label must be 50 characters or fewer")
        }
        if childTickers.isEmpty {
            messages.append("Add at least one child ticker")
        }
        
        return messages
    }
    
    var formattedTime: String {
        // For composite editor, show child count instead of time
        if childTickers.isEmpty {
            return "No tickers"
        } else if childTickers.count == 1 {
            return "1 ticker"
        } else {
            return "\(childTickers.count) tickers"
        }
    }
    
    // MARK: - Child Ticker Management
    
    func addChildTicker(_ ticker: Ticker) {
        // Create a copy to avoid issues with SwiftData context
        // The ticker will be properly inserted when the composite is saved
        childTickers.append(ticker)
    }
    
    func updateChildTicker(_ ticker: Ticker) {
        if let index = childTickers.firstIndex(where: { $0.id == ticker.id }) {
            childTickers[index] = ticker
        }
    }
    
    func removeChildTicker(_ ticker: Ticker) {
        childTickers.removeAll { $0.id == ticker.id }
    }
    
    func removeChildTicker(at index: Int) {
        guard index < childTickers.count else { return }
        childTickers.remove(at: index)
    }
    
    // MARK: - Save
    
    func saveCompositeTicker() async {
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
            let label = labelViewModel.labelText.isEmpty ? "Composite Ticker" : labelViewModel.labelText
            let icon = iconPickerViewModel.selectedIcon
            let colorHex = iconPickerViewModel.selectedColorHex
            
            if isEditMode, let existingComposite = compositeTickerToEdit {
                // Update existing composite
                try await compositeTickerService.updateCustomCompositeTicker(
                    existingComposite,
                    label: label,
                    icon: icon,
                    colorHex: colorHex,
                    childTickers: childTickers,
                    modelContext: modelContext
                )
            } else {
                // Create new composite
                _ = try await compositeTickerService.createCustomCompositeTicker(
                    label: label,
                    icon: icon,
                    colorHex: colorHex,
                    childTickers: childTickers,
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
    
    private func prefillFromComposite(_ composite: CompositeTicker) {
        // Prefill label
        labelViewModel.setText(composite.label)
        
        // Prefill icon and color
        if let tickerData = composite.tickerData {
            let icon = tickerData.icon ?? "alarm"
            let colorHex = tickerData.colorHex ?? "#8B5CF6"
            iconPickerViewModel.selectIcon(icon, colorHex: colorHex)
        } else {
            iconPickerViewModel.selectIcon("alarm", colorHex: "#8B5CF6")
        }
        
        // Prefill child tickers
        if let children = composite.childTickers {
            childTickers = children
        }
    }
}

