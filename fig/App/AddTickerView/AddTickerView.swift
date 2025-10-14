//
//  AddTickerView.swift
//  fig
//
//  Created by Mayank Gandhi on 09/10/25.
//

import SwiftUI
import SwiftData

struct AddTickerView: View {
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
                VStack(spacing: TickerSpacing.lg) {
                    // Time Picker Card
                    timePickerCard

                    // Options Pills
                    OptionsPillsView(
                        viewModel: viewModel.optionsPillsViewModel,
                        selectedIcon: viewModel.iconPickerViewModel.selectedIcon,
                        selectedColorHex: viewModel.iconPickerViewModel.selectedColorHex
                    )

                    Spacer(minLength: 300)
                }
            }
        .overlay(alignment: .bottom) {
            // Expanded content overlay
            ExpandableOverlayContainer(
                isPresented: viewModel.optionsPillsViewModel.expandedField != nil,
                onDismiss: {
                    viewModel.optionsPillsViewModel.collapseField()
                }
            ) {
                if let field = viewModel.optionsPillsViewModel.expandedField {
                    expandedContentForField(field)
                        .padding(.horizontal, TickerSpacing.md)
                        .padding(.bottom, TickerSpacing.lg)
                }
            }
        }
        .background(
            ZStack {
                TickerColor.liquidGlassGradient(for: colorScheme)
                    .ignoresSafeArea()

                // Subtle overlay for glass effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.1)
                    .ignoresSafeArea()
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isEditMode ? "Edit Ticker" : "New Ticker")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
            }

            ToolbarItem(placement: .cancellationAction) {
                Button {
                    TickerHaptics.selection()
                    // If expanded content is visible, collapse it first
                    if viewModel.optionsPillsViewModel.expandedField != nil {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.optionsPillsViewModel.collapseField()
                        }
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme).opacity(0.7))
                        .symbolRenderingMode(.hierarchical)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    // If expanded content is visible, collapse it first
                    if viewModel.optionsPillsViewModel.expandedField != nil {
                        TickerHaptics.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.optionsPillsViewModel.collapseField()
                        }
                    } else {
                        Task {
                            TickerHaptics.selection()
                            await viewModel.saveTicker()
                            if !viewModel.showingError {
                                dismiss()
                            }
                        }
                    }
                } label: {
                    HStack(spacing: TickerSpacing.xs) {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(TickerColor.absoluteWhite)
                                .scaleEffect(0.75)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                        }
                        Text(viewModel.isSaving ? "Saving..." : "Save")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(TickerColor.absoluteWhite)
                    .padding(.horizontal, TickerSpacing.md)
                    .padding(.vertical, TickerSpacing.sm)
                    .background(
                        Capsule()
                            .fill(
                                viewModel.isSaving ?
                                LinearGradient(
                                        colors: [TickerColor.primary.opacity(0.7)],
                                        startPoint: .center,
                                        endPoint: .center
                                    ) :
                                    LinearGradient(
                                        colors: [
                                            TickerColor.primary,
                                            TickerColor.primary.opacity(0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                    )
                    .shadow(
                        color: TickerColor.primary.opacity(viewModel.isSaving ? 0.2 : 0.4),
                        radius: viewModel.isSaving ? 4 : 8,
                        x: 0,
                        y: 4
                    )
                }
                .disabled(viewModel.isSaving || !viewModel.canSave)
                .opacity(viewModel.hasDateWeekdayMismatch ? 0.6 : 1.0)
            }
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
            viewModel.updateSmartDate()
        }
        .onChange(of: viewModel.timePickerViewModel.selectedMinute) { _, _ in
            viewModel.updateSmartDate()
        }
        .onChange(of: viewModel.calendarViewModel.selectedDate) { _, _ in
            // Trigger validation update when date changes
        }
        .onChange(of: viewModel.repeatViewModel.selectedWeekdays) { _, _ in
            // Trigger validation update when weekdays change
        }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private var timePickerCard: some View {
        if let viewModel = viewModel {
            TimePickerView(viewModel: viewModel.timePickerViewModel)
                .padding(.horizontal, TickerSpacing.md)
                .padding(.vertical, TickerSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: TickerRadius.large)
                        .fill(TickerColor.surface(for: colorScheme).opacity(0.6))
                )
                .background(
                    RoundedRectangle(cornerRadius: TickerRadius.large)
                        .fill(.ultraThinMaterial)
                )
                .overlay(timePickerCardBorder)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                .shadow(color: TickerColor.primary.opacity(0.1), radius: 30, x: 0, y: 15)
                .padding(.horizontal, TickerSpacing.md)
                .padding(.top, TickerSpacing.md)
        }
    }

    private var timePickerCardBorder: some View {
        RoundedRectangle(cornerRadius: TickerRadius.large)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        TickerColor.primary.opacity(0.3),
                        TickerColor.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private func expandedContentForField(_ field: ExpandableField) -> some View {
        if let viewModel = viewModel {
            Group {
                switch field {
                case .calendar:
                    CalendarPickerView(viewModel: viewModel.calendarViewModel)

                case .repeat:
                    RepeatOptionsView(
                        viewModel: viewModel.repeatViewModel,
                        validationMessage: viewModel.dateWeekdayMismatchMessage,
                        onFixMismatch: viewModel.hasDateWeekdayMismatch ? {
                            viewModel.adjustDateToMatchWeekdays()
                        } : nil
                    )

                case .label:
                    LabelEditorView(viewModel: viewModel.labelViewModel)

                case .countdown:
                    CountdownConfigView(viewModel: viewModel.countdownViewModel)

                case .icon:
                    IconPickerViewMVVM(viewModel: viewModel.iconPickerViewModel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
}
