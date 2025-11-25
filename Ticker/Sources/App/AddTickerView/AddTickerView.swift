//
//  AddTickerView.swift
//  fig
//
//  Main view for creating and editing ticker alarms
//  Refactored to use modular components and Liquid Glass design system
//

import SwiftUI
import SwiftData
import TickerCore
import Factory

struct AddTickerView: View {
    // MARK: - Properties

    let namespace: Namespace.ID
    let prefillTickerId: PersistentIdentifier?
    let isEditMode: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: AddTickerViewModel?
    @State private var prefillTemplate: Ticker?

    // MARK: - Initialization

    init(namespace: Namespace.ID, prefillTickerId: PersistentIdentifier? = nil, isEditMode: Bool = false) {
        self.namespace = namespace
        self.prefillTickerId = prefillTickerId
        self.isEditMode = isEditMode
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            }
        }
        .navigationTransition(.zoom(sourceID: "addButton", in: namespace))
        .onAppear {
            // Initialize ViewModel with modelContext
            if viewModel == nil {
                // Fetch ticker from local context if editing
                if let tickerId = prefillTickerId {
                    prefillTemplate = modelContext.model(for: tickerId) as? Ticker
                }
                viewModel = AddTickerViewModel(
                    modelContext: modelContext,
                    prefillTemplate: prefillTemplate,
                    isEditMode: isEditMode
                )
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: AddTickerViewModel) -> some View {
        ScrollView {
                VStack(spacing: TickerSpacing.xl) {
                    // Time Picker Card
                    TimePickerCard(viewModel: viewModel.timePickerViewModel)

                    // Inline validation banner
                    if let message = viewModel.validationMessages.first {
                        ValidationBanner(message: message)
                            .padding(.horizontal, TickerSpacing.md)
                    }

                    // Options Pills with enhanced spacing
                    OptionsPillsView(
                        viewModel: viewModel.optionsPillsViewModel,
                        selectedIcon: viewModel.iconPickerViewModel.selectedIcon,
                        selectedColorHex: viewModel.iconPickerViewModel.selectedColorHex
                    )
                    .padding(.top, TickerSpacing.sm)

                    Spacer(minLength: 300)
                }
                .padding(.top, TickerSpacing.md)
            }
            // Overlay presentation for all expandable fields
            .overlay(alignment: .top) {
                if let field = viewModel.optionsPillsViewModel.expandedField {
                    ExpandedFieldContent(field: field, viewModel: viewModel)
                        .zIndex(100)
                }
            }
            .background(backgroundView)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AddTickerToolbar(
                    isEditMode: isEditMode,
                    formattedTime: viewModel.timePickerViewModel.formattedTime,
                    isSaving: viewModel.isSaving,
                    canSave: viewModel.canSave,
                    isExpanded: viewModel.optionsPillsViewModel.expandedField != nil,
                    onDismiss: { dismiss() },
                    onSave: {
                        print("💾 AddTickerView onSave triggered")
                        print("   → viewModel.isSaving: \(viewModel.isSaving)")
                        print("   → viewModel.canSave: \(viewModel.canSave)")
                        print("   → viewModel.showingError: \(viewModel.showingError)")
                        print("   → isEditMode: \(isEditMode)")
                        
                        Task {
                            print("   → Starting saveTicker() task")
                            await viewModel.saveTicker()
                            print("   → saveTicker() completed")
                            print("   → viewModel.showingError after save: \(viewModel.showingError)")
                            if !viewModel.showingError {
                                print("   → Dismissing view")
                                dismiss()
                            } else {
                                print("   → Error occurred, not dismissing")
                            }
                        }
                    },
                    onCollapse: {
                        viewModel.optionsPillsViewModel.collapseField()
                    }
                )
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Error", isPresented: Binding(
                get: { viewModel.showingError },
                set: { viewModel.showingError = $0 }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: viewModel.timePickerViewModel.selectedHour) { _, _ in
                TickerHaptics.selection()
                viewModel.updateSmartDate()
            }
            .onChange(of: viewModel.timePickerViewModel.selectedMinute) { _, _ in
                TickerHaptics.selection()
                viewModel.updateSmartDate()
            }
            .onChange(of: viewModel.scheduleViewModel.selectedDate) { _, _ in
                // Trigger validation update when date changes
            }
            .onChange(of: viewModel.scheduleViewModel.selectedWeekdays) { _, _ in
                // Trigger validation update when weekdays change
            }
    }

    // MARK: - Background View

    private var backgroundView: some View {
        ZStack {
            TickerColor.liquidGlassGradient(for: colorScheme)
                .ignoresSafeArea()

            // Subtle overlay for glass effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @Namespace var namespace
    @Previewable @Injected(\.tickerService) var tickerService
    AddTickerView(namespace: namespace)
        .modelContainer(for: [Ticker.self])
        .environment(tickerService)
}
