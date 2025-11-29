//
//  AddCollectionChildTickerView.swift
//  fig
//
//  Bottom sheet for adding/editing collection tickers
//  Captures label, time, and schedule configuration
//

import SwiftUI
import TickerCore

struct AddCollectionChildTickerView: View {
    let childToEdit: CollectionChildTickerData?
    let onSave: (CollectionChildTickerData) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: AddCollectionChildTickerViewModel
    @State private var hasAutoExpandedLabel = false
    
    init(childToEdit: CollectionChildTickerData? = nil, onSave: @escaping (CollectionChildTickerData) -> Void) {
        self.childToEdit = childToEdit
        self.onSave = onSave
        _viewModel = State(initialValue: AddCollectionChildTickerViewModel(childToEdit: childToEdit))
    }
    
    var body: some View {
        NavigationStack {
            contentView
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: TickerSpacing.xl) {
                // Time Picker Card
                TimePickerCard(viewModel: viewModel.timePickerViewModel)
                
                // Simplified Pills Section
                pillsSection
                    .padding(.top, TickerSpacing.sm)
                
                // Validation Banner
                if let message = viewModel.validationBannerMessage {
                    ValidationBanner(message: message)
                        .padding(.horizontal, TickerSpacing.md)
                }
                
                Spacer(minLength: 300)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, TickerSpacing.md)
        }
        // Overlay for expanded fields
        .overlay(alignment: .top) {
            if let field = viewModel.expandedField {
                expandedFieldContent(for: field)
                    .zIndex(100)
            }
        }
        .background(backgroundView)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: TickerSpacing.xxs) {
                    Text(childToEdit == nil ? "Add Ticker" : "Edit Ticker")
                        .Headline()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    TickerHaptics.selection()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    TickerHaptics.selection()
                    viewModel.revealValidationMessage()
                    guard let childData = viewModel.createChildTickerData() else {
                        focusFirstInvalidField()
                        return
                    }
                    onSave(childData)
                    dismiss()
                } label: {
                    Text(childToEdit == nil ? "Add" : "Save")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(viewModel.canSave ? TickerColor.primary : TickerColor.textTertiary(for: colorScheme))
                }
                .disabled(!viewModel.canSave)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onChange(of: viewModel.timePickerViewModel.selectedHour) { _, _ in
            syncScheduleWithTimePicker()
        }
        .onChange(of: viewModel.timePickerViewModel.selectedMinute) { _, _ in
            syncScheduleWithTimePicker()
        }
        .onAppear {
            openLabelEditorInitially()
        }
    }
    
    // MARK: - Pills Section
    
    @ViewBuilder
    private var pillsSection: some View {
        VStack(spacing: TickerSpacing.md) {
            // Label Pill
            Button {
                TickerHaptics.selection()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.toggleField(.label)
                }
            } label: {
                TickerPill(
                    icon: "textformat",
                    title: viewModel.displayLabel,
                    isActive: viewModel.expandedField == .label,
                    hasValue: !viewModel.labelViewModel.isEmpty,
                    size: .large
                )
            }
            
            // Schedule Pill
            Button {
                TickerHaptics.selection()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.toggleField(.schedule)
                }
            } label: {
                TickerPill(
                    icon: "repeat",
                    title: viewModel.displaySchedule,
                    isActive: viewModel.expandedField == .schedule,
                    hasValue: viewModel.scheduleViewModel.hasScheduleValue,
                    size: .large
                )
            }
        }
        .padding(.horizontal, TickerSpacing.md)
    }
    
    // MARK: - Expanded Field Content
    
    @ViewBuilder
    private func expandedFieldContent(for field: SimplifiedExpandableField) -> some View {
        AddCompositeOverlayCallout(
            field: field,
            viewModel: viewModel,
            colorScheme: colorScheme,
            onDismiss: {
                TickerHaptics.selection()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.collapseField()
                }
            }
        ) {
            fieldContent(for: field)
        }
    }
    
    @ViewBuilder
    private func fieldContent(for field: SimplifiedExpandableField) -> some View {
        switch field {
            case .time:
                TimePickerCard(viewModel: viewModel.timePickerViewModel)
                
            case .label:
                LabelEditorView(
                    viewModel: viewModel.labelViewModel,
                    onDismiss: {
                        TickerHaptics.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.collapseField()
                        }
                    }
                )
                
            case .schedule:
                ScheduleView(viewModel: viewModel.scheduleViewModel)
        }
    }
    
    // MARK: - Background View
    
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
    
    private func openLabelEditorInitially() {
        guard !hasAutoExpandedLabel else { return }
        hasAutoExpandedLabel = true
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.expandedField = .label
            }
        }
    }
    
    private func syncScheduleWithTimePicker() {
        // Sync scheduleViewModel's selectedDate with time picker
        viewModel.scheduleViewModel.updateSmartDate(
            for: viewModel.timePickerViewModel.selectedHour,
            minute: viewModel.timePickerViewModel.selectedMinute
        )
    }
    
    private func focusFirstInvalidField() {
        if !viewModel.labelViewModel.isValid {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.expandedField = .label
            }
            return
        }
        
        if !viewModel.scheduleViewModel.repeatConfigIsValid {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.expandedField = .schedule
            }
        }
    }
}

// MARK: - Overlay Callout

private struct AddCompositeOverlayCallout<Content: View>: View {
    let field: SimplifiedExpandableField
    let viewModel: AddCollectionChildTickerViewModel
    let colorScheme: ColorScheme
    let onDismiss: () -> Void
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            // Background tap area to dismiss
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
            
            // Overlay content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(headerTitle)
                        .Headline()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    
                    Spacer()
                    
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(.title2, design: .rounded, weight: .regular))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(TickerSpacing.md)
                
                Divider()
                
                // Content area
                ScrollView {
                    content
                        .padding(TickerSpacing.md)
                }
                .frame(maxHeight: maxContentHeight)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .fill(TickerColor.surface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .strokeBorder(TickerColor.textTertiary(for: colorScheme).opacity(0.15), lineWidth: 1)
            )
            .shadow(
                color: TickerShadow.elevated.color,
                radius: TickerShadow.elevated.radius,
                x: TickerShadow.elevated.x,
                y: TickerShadow.elevated.y
            )
            .padding(TickerSpacing.md)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
        }
    }
    
    private var maxContentHeight: CGFloat {
        switch field {
            case .time:
                return 300
            case .label:
                return 200
            case .schedule:
                return 600
        }
    }
    
    private var headerTitle: String {
        switch field {
            case .time:
                return "Time"
            case .label:
                return "Label"
            case .schedule:
                return "Schedule"
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showSheet = true
    
    Color.clear
        .sheet(isPresented: $showSheet) {
            AddCollectionChildTickerView(
                childToEdit: nil,
                onSave: { _ in }
            )
        }
}
