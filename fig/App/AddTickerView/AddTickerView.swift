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

                    // Inline validation banner
                    if let message = viewModel.validationMessages.first {
                        validationBanner(message: message)
                            .padding(.horizontal, TickerSpacing.md)
                    }

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
                VStack(spacing: TickerSpacing.xxs) {
                    Text(isEditMode ? "Edit Ticker" : "New Ticker")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    
                        Text(viewModel.timePickerViewModel.formattedTime)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                            .opacity(0.8)
                    
                }
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
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(TickerColor.surface(for: colorScheme).opacity(0.8))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        TickerColor.textTertiary(for: colorScheme).opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    }
                }
                .buttonStyle(PlainButtonStyle())
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
                            TickerHaptics.criticalAction()
                            await viewModel.saveTicker()
                            if !viewModel.showingError {
                                dismiss()
                            }
                        }
                    }
                } label: {
                    HStack(spacing: TickerSpacing.sm) {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(TickerColor.absoluteWhite)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                        }
                        Text(viewModel.isSaving ? "Saving..." : "Save")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(TickerColor.absoluteWhite)
                    .padding(.horizontal, TickerSpacing.lg)
                    .padding(.vertical, TickerSpacing.md)
                    .background(
                        ZStack {
                            // Base gradient
                            Capsule()
                                .fill(
                                    viewModel.isSaving ?
                                    LinearGradient(
                                            colors: [
                                                TickerColor.primary.opacity(0.8),
                                                TickerColor.primary.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [
                                                TickerColor.primary,
                                                TickerColor.primary.opacity(0.95),
                                                TickerColor.primary.opacity(0.9)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                            
                            // Shimmer effect when saving
                            if viewModel.isSaving {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.clear,
                                                Color.white.opacity(0.2),
                                                Color.clear
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .offset(x: -50)
                                    .animation(
                                        .linear(duration: 1.5)
                                        .repeatForever(autoreverses: false),
                                        value: viewModel.isSaving
                                    )
                            }
                        }
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                TickerColor.absoluteWhite.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: TickerColor.primary.opacity(viewModel.isSaving ? 0.3 : 0.5),
                        radius: viewModel.isSaving ? 6 : 12,
                        x: 0,
                        y: viewModel.isSaving ? 3 : 6
                    )
                    .scaleEffect(viewModel.isSaving ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isSaving)
                }
                .disabled(viewModel.isSaving || !viewModel.canSave)
                .opacity(viewModel.hasDateWeekdayMismatch ? 0.5 : (viewModel.canSave ? 1.0 : 0.6))
                .animation(.easeInOut(duration: 0.2), value: viewModel.canSave)
                .animation(.easeInOut(duration: 0.2), value: viewModel.hasDateWeekdayMismatch)
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
        .onChange(of: viewModel.timePickerViewModel.selectedHour) { _, newValue in
            TickerHaptics.selection()
            viewModel.updateSmartDate()
        }
        .onChange(of: viewModel.timePickerViewModel.selectedMinute) { _, newValue in
            TickerHaptics.selection()
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
                        .fill(TickerColor.surface(for: colorScheme).opacity(0.7))
                )
                .background(
                    RoundedRectangle(cornerRadius: TickerRadius.large)
                        .fill(.ultraThinMaterial)
                )
                .overlay(timePickerCardBorder)
                .shadow(color: Color.black.opacity(0.1), radius: 25, x: 0, y: 12)
                .shadow(color: TickerColor.primary.opacity(0.15), radius: 35, x: 0, y: 18)
                .padding(.horizontal, TickerSpacing.md)
                .padding(.top, TickerSpacing.md)
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.timePickerViewModel.selectedHour)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.timePickerViewModel.selectedMinute)
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
            VStack(spacing: 0) {
                // Dismiss button positioned above the content
                HStack {
                    Spacer()
                    Button {
                        TickerHaptics.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.optionsPillsViewModel.collapseField()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(TickerColor.surface(for: colorScheme).opacity(0.9))
                                .frame(width: 28, height: 28)

                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.5))
                                .frame(width: 28, height: 28)

                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        }
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(TickerSpacing.md)
                }
                
                // Content
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
                .padding(TickerSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: TickerRadius.large)
                        .fill(TickerColor.surface(for: colorScheme).opacity(0.95))
                )
                .background(
                    RoundedRectangle(cornerRadius: TickerRadius.large)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.large)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
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

// MARK: - Inline Validation Banner

extension AddTickerView {
    @ViewBuilder
    fileprivate func validationBanner(message: String) -> some View {
        HStack(spacing: TickerSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(TickerColor.warning)

            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColor.warning.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .strokeBorder(TickerColor.warning.opacity(0.3), lineWidth: 1)
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
