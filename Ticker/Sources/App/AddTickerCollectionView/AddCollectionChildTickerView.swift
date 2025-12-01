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
    let defaultIcon: String?
    let defaultColorHex: String?
    let defaultSoundName: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: AddCollectionChildTickerViewModel
    @State private var hasAutoExpandedLabel = false
    
    init(
        childToEdit: CollectionChildTickerData? = nil,
        defaultIcon: String? = nil,
        defaultColorHex: String? = nil,
        defaultSoundName: String? = nil,
        onSave: @escaping (CollectionChildTickerData) -> Void
    ) {
        self.childToEdit = childToEdit
        self.defaultIcon = defaultIcon
        self.defaultColorHex = defaultColorHex
        self.defaultSoundName = defaultSoundName
        self.onSave = onSave
        _viewModel = State(initialValue: AddCollectionChildTickerViewModel(
            childToEdit: childToEdit,
            defaultIcon: defaultIcon,
            defaultColorHex: defaultColorHex,
            defaultSoundName: defaultSoundName
        ))
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
                
                // Options Pills with all options
                OptionsPillsView(
                    viewModel: viewModel.optionsPillsViewModel,
                    selectedIcon: viewModel.iconPickerViewModel.selectedIcon,
                    selectedColorHex: viewModel.iconPickerViewModel.selectedColorHex
                )
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
            if let field = viewModel.optionsPillsViewModel.expandedField {
                ChildTickerExpandedFieldContent(field: field, viewModel: viewModel)
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
                viewModel.optionsPillsViewModel.expandedField = .label
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
                viewModel.optionsPillsViewModel.expandedField = .label
            }
            return
        }
        
        if !viewModel.scheduleViewModel.repeatConfigIsValid {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.optionsPillsViewModel.expandedField = .schedule
            }
            return
        }
        
        if !viewModel.countdownViewModel.isValid {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.optionsPillsViewModel.expandedField = .countdown
            }
        }
    }
}

// MARK: - Expanded Field Content for Child Ticker

struct ChildTickerExpandedFieldContent: View {
    let field: ExpandableField
    let viewModel: AddCollectionChildTickerViewModel

    var body: some View {
        OverlayCalloutForChildTicker(field: field, viewModel: viewModel) {
            fieldContent
        }
    }

    // MARK: - Field Content

    @ViewBuilder
    private var fieldContent: some View {
        switch field {
        case .time:
            // Time picker is shown directly in main view via TimePickerCard
            EmptyView()

        case .schedule:
            ScheduleView(viewModel: viewModel.scheduleViewModel)

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

        case .countdown:
            CountdownConfigView(viewModel: viewModel.countdownViewModel)

        case .sound:
            SoundPickerView(viewModel: viewModel.soundPickerViewModel)

        case .icon:
            IconPickerViewMVVM(viewModel: viewModel.iconPickerViewModel)
        }
    }
}

// MARK: - Overlay Callout for Child Ticker

struct OverlayCalloutForChildTicker<Content: View>: View {
    let field: ExpandableField
    let viewModel: AddCollectionChildTickerViewModel
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background tap area to dismiss overlay
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.collapseField()
                    }
                }
            
            // Overlay content
            VStack(spacing: 0) {
                // Header with dismiss button
                HStack {
                    Text(headerTitle)
                        .Headline()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                    Spacer()

                    Button {
                        TickerHaptics.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.collapseField()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(.title2, design: .rounded, weight: .regular))
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(TickerSpacing.md)

                Divider()

                // Content area with adaptive max height
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

    // MARK: - Computed Properties

    private var maxContentHeight: CGFloat {
        switch field {
        case .time:
            return 400
        case .schedule, .icon:
            return 600
        case .label:
            return 200
        case .countdown:
            return 350
        case .sound:
            return 400
        }
    }

    private var headerTitle: String {
        switch field {
            case .time:
                return "Alarm Time"
            case .schedule:
                return "Schedule"
            case .label:
                return "Alarm Label"
            case .countdown:
                return "Pre-Alert Countdown"
            case .icon:
                return "Alarm Icon"
            case .sound:
                return "Alarm Sound"
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
                defaultIcon: "alarm",
                defaultColorHex: "#8B5CF6",
                defaultSoundName: nil,
                onSave: { _ in }
            )
        }
}
