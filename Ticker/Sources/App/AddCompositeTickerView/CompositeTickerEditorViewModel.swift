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
    var childTickerData: [CompositeChildTickerData] = []
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
        // For composite editor, show child count instead of time
        if childTickerData.isEmpty {
            return "No tickers"
        } else if childTickerData.count == 1 {
            return "1 ticker"
        } else {
            return "\(childTickerData.count) tickers"
        }
    }
    
    // MARK: - Child Ticker Data Management

    func addChildTickerData(_ data: CompositeChildTickerData) {
        childTickerData.append(data)
    }

    func updateChildTickerData(_ data: CompositeChildTickerData) {
        if let index = childTickerData.firstIndex(where: { $0.id == data.id }) {
            childTickerData[index] = data
        }
    }

    func removeChildTickerData(_ data: CompositeChildTickerData) {
        childTickerData.removeAll { $0.id == data.id }
    }

    func removeChildTickerData(at index: Int) {
        guard index < childTickerData.count else { return }
        childTickerData.remove(at: index)
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

            // Build presentation for child tickers
            let presentation = TickerPresentation(
                tintColorHex: colorHex,
                secondaryButtonType: .none
            )

            // Convert CompositeChildTickerData to Ticker objects
            let tickers = childTickerData.map { data in
                data.toTicker(presentation: presentation, icon: icon, colorHex: colorHex)
            }

            if isEditMode, let existingComposite = compositeTickerToEdit {
                // Update existing composite
                try await compositeTickerService.updateCustomCompositeTicker(
                    existingComposite,
                    label: label,
                    icon: icon,
                    colorHex: colorHex,
                    childTickers: tickers,
                    modelContext: modelContext
                )
            } else {
                // Create new composite
                _ = try await compositeTickerService.createCustomCompositeTicker(
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
        
        // Convert existing Tickers to CompositeChildTickerData for editing
        if let children = composite.childTickers {
            childTickerData = children.compactMap { ticker in
                guard let schedule = ticker.schedule else { return nil }
                return CompositeChildTickerData(
                    id: ticker.id,
                    label: ticker.label,
                    schedule: schedule
                )
            }
        }
    }
}

