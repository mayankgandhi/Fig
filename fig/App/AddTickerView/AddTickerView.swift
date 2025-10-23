//
//  AddTickerView.swift
//  fig
//
//  Main view for creating and editing ticker alarms
//  Refactored to use modular components and Liquid Glass design system
//

import SwiftUI
import SwiftData

struct AddTickerView: View {
    // MARK: - Properties

    let namespace: Namespace.ID
    let prefillTemplate: Ticker?
    let isEditMode: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(TickerService.self) private var tickerService
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: AddTickerViewModel?

    // MARK: - Initialization

    init(namespace: Namespace.ID, prefillTemplate: Ticker? = nil, isEditMode: Bool = false) {
        self.namespace = namespace
        self.prefillTemplate = prefillTemplate
        self.isEditMode = isEditMode
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            if let viewModel = viewModel {
                contentView
            } else {
                ProgressView()
                    .onAppear {
                        initializeViewModel()
                    }
            }
        }
        .navigationTransition(.zoom(sourceID: "addButton", in: namespace))
    }
    
    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if let viewModel = viewModel {
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
            .sheet(isPresented: Binding(
                get: { viewModel.optionsPillsViewModel.expandedField != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.optionsPillsViewModel.collapseField()
                    }
                }
            )) {
                if let field = viewModel.optionsPillsViewModel.expandedField {
                    ExpandedFieldContent(field: field, viewModel: viewModel)
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
                    hasDateWeekdayMismatch: viewModel.hasDateWeekdayMismatch,
                    isExpanded: viewModel.optionsPillsViewModel.expandedField != nil,
                    onDismiss: { dismiss() },
                    onSave: {
                        Task {
                            await viewModel.saveTicker()
                            if !viewModel.showingError {
                                dismiss()
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

    // MARK: - Initialization

    private func initializeViewModel() {
        viewModel = AddTickerViewModel(
            modelContext: modelContext,
            tickerService: tickerService,
            prefillTemplate: prefillTemplate,
            isEditMode: isEditMode
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @Namespace var namespace
    AddTickerView(namespace: namespace)
        .modelContainer(for: [Ticker.self])
        .environment(TickerService())
}
