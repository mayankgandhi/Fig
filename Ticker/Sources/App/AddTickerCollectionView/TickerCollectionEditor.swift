//
//  TickerCollectionEditor.swift
//  fig
//
//  Main view for creating and editing ticker collections
//  Similar in UI and implementation to AddTickerView
//

import SwiftUI
import SwiftData
import TickerCore
import Factory
import DesignKit

struct TickerCollectionEditor: View {
    // MARK: - Properties

    let namespace: Namespace.ID
    let tickerCollection: TickerCollection?
    let isEditMode: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(namespace: Namespace.ID, tickerCollection: TickerCollection? = nil, isEditMode: Bool = false) {
        self.namespace = namespace
        self.tickerCollection = tickerCollection
        self.isEditMode = isEditMode
    }

    // MARK: - Body

    var body: some View {
        TickerCollectionEditorContent(
            namespace: namespace,
            tickerCollection: tickerCollection,
            isEditMode: isEditMode,
            modelContext: modelContext,
            dismiss: dismiss,
            colorScheme: colorScheme
        )
        .navigationTransition(.zoom(sourceID: "addButton", in: namespace))
    }
}

// MARK: - Content View with ViewModel

private struct TickerCollectionEditorContent: View {
    let namespace: Namespace.ID
    let tickerCollection: TickerCollection?
    let isEditMode: Bool
    let modelContext: ModelContext
    let dismiss: DismissAction
    let colorScheme: ColorScheme
    
    @State private var viewModel: TickerCollectionEditorViewModel
    
    // Child ticker data editing state
    @State private var childDataToEdit: CollectionChildTickerData?
    @State private var showAddChildSheet = false
    @State private var childDataToDelete: CollectionChildTickerData?
    @State private var showDeleteChildAlert = false
    
    init(
        namespace: Namespace.ID,
        tickerCollection: TickerCollection?,
        isEditMode: Bool,
        modelContext: ModelContext,
        dismiss: DismissAction,
        colorScheme: ColorScheme
    ) {
        self.namespace = namespace
        self.tickerCollection = tickerCollection
        self.isEditMode = isEditMode
        self.modelContext = modelContext
        self.dismiss = dismiss
        self.colorScheme = colorScheme
        // Initialize viewModel immediately since we have modelContext
        _viewModel = State(initialValue: TickerCollectionEditorViewModel(
            modelContext: modelContext,
            tickerCollectionToEdit: tickerCollection,
            isEditMode: isEditMode
        ))
    }
    
    var body: some View {
        NavigationStack {
            contentView(viewModel: viewModel)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: TickerCollectionEditorViewModel) -> some View {
        ScrollView {
            VStack(spacing: TickerSpacing.xl) {
                // Options Pills for Label and Icon
                OptionsPillsView(
                    viewModel: viewModel.optionsPillsViewModel,
                    selectedIcon: viewModel.iconPickerViewModel.selectedIcon,
                    selectedColorHex: viewModel.iconPickerViewModel.selectedColorHex
                )
                .padding(.top, TickerSpacing.sm)

                // Child Ticker Data List
                ChildTickerDataListView(
                    childData: viewModel.childTickerData,
                    icon: viewModel.iconPickerViewModel.selectedIcon,
                    colorHex: viewModel.iconPickerViewModel.selectedColorHex,
                    onEdit: { data in
                        childDataToEdit = data
                    },
                    onDelete: { data in
                        childDataToDelete = data
                        showDeleteChildAlert = true
                    }
                )
                .padding(.top, TickerSpacing.sm)

                // Add Ticker Button
                Button {
                    TickerHaptics.selection()
                    showAddChildSheet = true
                } label: {
                    HStack(spacing: TickerSpacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.callout.weight(.semibold))
                        Text("Add Ticker")
                            .Body()
                    }
                    .foregroundStyle(TickerColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TickerSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: TickerRadius.medium)
                            .fill(TickerColor.primary.opacity(0.1))
                    )
                }
                .padding(.horizontal, TickerSpacing.md)
                .padding(.top, TickerSpacing.md)

                Spacer(minLength: 300)
            }
            .padding(.top, TickerSpacing.md)
        }
        // Overlay presentation for all expandable fields
        .overlay(alignment: .top) {
            if let field = viewModel.optionsPillsViewModel.expandedField {
                ExpandedFieldContentForCollection(field: field, viewModel: viewModel)
                    .zIndex(100)
            }
        }
        .background(backgroundView)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            TickerCollectionEditorToolbar(
                isEditMode: isEditMode,
                formattedTime: viewModel.formattedTime,
                isSaving: viewModel.isSaving,
                canSave: viewModel.canSave,
                isExpanded: viewModel.optionsPillsViewModel.expandedField != nil,
                onDismiss: { dismiss() },
                onSave: {
                    Task {
                        await viewModel.saveTickerCollection()
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
        .alert("Delete Ticker", isPresented: $showDeleteChildAlert) {
            Button("Cancel", role: .cancel) {
                childDataToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let data = childDataToDelete {
                    viewModel.removeChildTickerData(data)
                    childDataToDelete = nil
                }
            }
        } message: {
            if let data = childDataToDelete {
                Text("Are you sure you want to remove \"\(data.label)\" from this ticker collection?")
            }
        }
        .sheet(isPresented: $showAddChildSheet) {
            AddCollectionChildTickerView(
                childToEdit: nil,
                onSave: { childData in
                    // Add the newly created child data to the composite's list
                    viewModel.addChildTickerData(childData)
                }
            )
            .presentationCornerRadius(DesignKit.large)
            .presentationBackground {
                sheetBackground
            }
        }
        .sheet(item: $childDataToEdit) { data in
            AddCollectionChildTickerView(
                childToEdit: data,
                onSave: { updatedData in
                    // Update the child data in the composite's list
                    viewModel.updateChildTickerData(updatedData)
                }
            )
            .presentationCornerRadius(DesignKit.large)
            .presentationBackground {
                sheetBackground
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
    
    private var sheetBackground: some View {
        ZStack {
            TickerColor.liquidGlassGradient(for: colorScheme)
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        }
    }
}

// MARK: - Expanded Field Content for Collection

struct ExpandedFieldContentForCollection: View {
    let field: ExpandableField
    let viewModel: TickerCollectionEditorViewModel

    var body: some View {
        OverlayCalloutForCollection(field: field, viewModel: viewModel) {
            fieldContent
        }
    }

    // MARK: - Field Content

    @ViewBuilder
    private var fieldContent: some View {
        switch field {
        case .label:
            LabelEditorView(
                viewModel: viewModel.labelViewModel,
                onDismiss: {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.optionsPillsViewModel.collapseField()
                    }
                }
            )

        case .icon:
            IconPickerViewMVVM(viewModel: viewModel.iconPickerViewModel)
            
        case .sound:
            SoundPickerView(viewModel: viewModel.soundPickerViewModel)

        default:
            EmptyView()
        }
    }
}

// MARK: - Overlay Callout for Collection

struct OverlayCalloutForCollection<Content: View>: View {
    let field: ExpandableField
    let viewModel: TickerCollectionEditorViewModel
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
                        viewModel.optionsPillsViewModel.collapseField()
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
                            viewModel.optionsPillsViewModel.collapseField()
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
        case .label:
            return 200
        case .icon:
            return 600
        case .sound:
            return 400
        default:
            return 400
        }
    }
    
    private var headerTitle: String {
        switch field {
        case .label:
            return "Collection Label"
        case .icon:
            return "Collection Icon"
        case .sound:
            return "Collection Sound"
        default:
            return "Options"
        }
    }
}


// MARK: - Collection Ticker Editor Toolbar

struct TickerCollectionEditorToolbar: ToolbarContent {
    let isEditMode: Bool
    let formattedTime: String
    let isSaving: Bool
    let canSave: Bool
    let isExpanded: Bool
    let onDismiss: () -> Void
    let onSave: () -> Void
    let onCollapse: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(isEditMode ? "Edit Collection" : "New Collection")
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Text(formattedTime)
                    .Caption()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .opacity(0.8)
            }
        }

        ToolbarItem(placement: .cancellationAction) {
            Button {
                TickerHaptics.selection()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
            }
            .buttonStyle(PlainButtonStyle())
        }

        ToolbarItem(placement: .confirmationAction) {
            SaveButton(
                isSaving: isSaving,
                canSave: canSave,
                isExpanded: isExpanded,
                onCollapse: onCollapse,
                onSave: onSave
            )
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @Namespace var namespace
    TickerCollectionEditor(namespace: namespace)
        .modelContainer(for: [Ticker.self, TickerCollection.self])
}

