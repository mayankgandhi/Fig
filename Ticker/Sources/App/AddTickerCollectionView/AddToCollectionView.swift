//
//  AddToCollectionView.swift
//  fig
//
//  View for adding an existing ticker to a collection
//

import SwiftUI
import SwiftData
import TickerCore
import DesignKit
import Factory

struct AddToCollectionView: View {
    // MARK: - Properties
    
    let tickerToAdd: Ticker
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var viewModel: AddToCollectionViewModel?
    @State private var showCreateNewCollection = false
    @State private var newCollectionLabel = ""
    @State private var selectedIcon = "alarm"
    @State private var selectedColorHex = "#8B5CF6"
    @State private var showIconPicker = false
    
    // MARK: - Initialization
    
    init(tickerToAdd: Ticker) {
        self.tickerToAdd = tickerToAdd
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            if let viewModel = viewModel {
                contentView(viewModel: viewModel)
                    .background(backgroundView)
                    .navigationTitle("Add to Collection")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                DesignKitHaptics.selection()
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
                            }
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
                    .sheet(isPresented: $showCreateNewCollection) {
                        createNewCollectionView(viewModel: viewModel)
                    }
            }
        }
        .onAppear {
            // Initialize viewModel with actual modelContext
            if viewModel == nil {
                viewModel = AddToCollectionViewModel(
                    modelContext: modelContext,
                    tickerToAdd: tickerToAdd
                )
            }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private func contentView(viewModel: AddToCollectionViewModel) -> some View {
        ScrollView {
            VStack(spacing: DesignKit.md) {
                // Header info
                VStack(spacing: DesignKit.md) {
                    Text("Adding \"\(tickerToAdd.label)\"")
                        .font(.headline)
                        .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
                    
                    Text("Select a collection or create a new one")
                        .font(.subheadline)
                        .foregroundStyle(DesignKit.textSecondary(for: colorScheme))
                }
                .padding(.top, DesignKit.md)
                .padding(.horizontal, DesignKit.md)
                
                // Create New Collection Button
                Button {
                    DesignKitHaptics.selection()
                    showCreateNewCollection = true
                } label: {
                    HStack(spacing: DesignKit.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Create New Collection")
                            .font(.body.weight(.medium))
                    }
                    .foregroundStyle(DesignKit.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignKit.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignKit.large)
                            .fill(DesignKit.primary.opacity(0.1))
                    )
                }
                .padding(.horizontal, DesignKit.md)
                .padding(.top, DesignKit.md)
                
                // Existing Collections List
                if viewModel.availableCollections.isEmpty {
                    VStack(spacing: DesignKit.md) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(DesignKit.textTertiary(for: colorScheme))
                        Text("No collections yet")
                            .font(.subheadline)
                            .foregroundStyle(DesignKit.textSecondary(for: colorScheme))
                    }
                    .padding(.top, DesignKit.lg)
                } else {
                    VStack(spacing: DesignKit.md) {
                        ForEach(viewModel.availableCollections) { collection in
                            collectionRow(collection, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, DesignKit.md)
                }
                
                Spacer(minLength: 100)
            }
        }
    }
    
    // MARK: - Collection Row
    
    @ViewBuilder
    private func collectionRow(_ collection: TickerCollection, viewModel: AddToCollectionViewModel) -> some View {
        Button {
            DesignKitHaptics.selection()
            Task {
                await viewModel.addToExistingCollection(collection)
                if !viewModel.showingError {
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: DesignKit.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(collection.presentation.tintColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: collection.tickerData?.icon ?? "square.stack.3d.up.fill")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(collection.presentation.tintColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: DesignKit.md) {
                    Text(collection.label)
                        .font(.body.weight(.medium))
                        .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
                    
                    if let childCount = collection.childTickers?.count {
                        Text("\(childCount) alarm\(childCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(DesignKit.textSecondary(for: colorScheme))
                    }
                }
                
                Spacer()
                
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignKit.textTertiary(for: colorScheme))
                }
            }
            .padding(DesignKit.md)
            .background(
                RoundedRectangle(cornerRadius: DesignKit.large)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
    }
    
    // MARK: - Create New Collection View
    
    @ViewBuilder
    private func createNewCollectionView(viewModel: AddToCollectionViewModel) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignKit.lg) {
                    // Label Text Field
                    VStack(alignment: .leading, spacing: DesignKit.md) {
                        Text("Collection Label")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DesignKit.textTertiary(for: colorScheme))
                            .textCase(.uppercase)
                        
                        TextField("e.g., Morning Routine", text: $newCollectionLabel)
                            .textFieldStyle(.plain)
                            .padding(DesignKit.md)
                            .background(
                                RoundedRectangle(cornerRadius: DesignKit.large)
                                    .fill(DesignKit.surface(for: colorScheme))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignKit.large)
                                    .strokeBorder(
                                        DesignKit.textTertiary(for: colorScheme).opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .padding(.horizontal, DesignKit.md)
                    .padding(.top, DesignKit.md)
                    
                    // Icon and Color Picker
                    VStack(alignment: .leading, spacing: DesignKit.md) {
                        Text("Icon & Color")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DesignKit.textTertiary(for: colorScheme))
                            .textCase(.uppercase)
                        
                        Button {
                            DesignKitHaptics.selection()
                            showIconPicker = true
                        } label: {
                            HStack(spacing: DesignKit.md) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: selectedColorHex)?.opacity(0.15) ?? DesignKit.primary.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                    
                                    Image(systemName: selectedIcon)
                                        .font(.system(.title3, design: .rounded, weight: .semibold))
                                        .foregroundStyle(Color(hex: selectedColorHex) ?? DesignKit.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: DesignKit.md) {
                                    Text("Tap to change")
                                        .font(.body)
                                        .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
                                    
                                    Text("Icon and color")
                                        .font(.caption)
                                        .foregroundStyle(DesignKit.textSecondary(for: colorScheme))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DesignKit.textTertiary(for: colorScheme))
                            }
                            .padding(DesignKit.md)
                            .background(
                                RoundedRectangle(cornerRadius: DesignKit.large)
                                    .fill(DesignKit.surface(for: colorScheme))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignKit.large)
                                    .strokeBorder(
                                        DesignKit.textTertiary(for: colorScheme).opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, DesignKit.md)
                    
                    Spacer(minLength: 200)
                }
            }
            .background(backgroundView)
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        DesignKitHaptics.selection()
                        showCreateNewCollection = false
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(DesignKit.textPrimary(for: colorScheme))
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        DesignKitHaptics.selection()
                        let label = newCollectionLabel.isEmpty ? "Ticker Collection" : newCollectionLabel
                        Task {
                            await viewModel.addToNewCollection(
                                label: label,
                                icon: selectedIcon,
                                colorHex: selectedColorHex
                            )
                            if !viewModel.showingError {
                                showCreateNewCollection = false
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Create")
                                .fontWeight(.semibold)
                                .foregroundStyle(DesignKit.primary)
                        }
                    }
                    .disabled(viewModel.isSaving || newCollectionLabel.isEmpty)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showIconPicker) {
                iconPickerSheet
            }
        }
    }
    
    // MARK: - Icon Picker Sheet
    
    @ViewBuilder
    private var iconPickerSheet: some View {
        NavigationStack {
            IconPickerView(
                selectedIcon: $selectedIcon,
                selectedColorHex: $selectedColorHex
            )
            .padding()
            .background(backgroundView)
            .navigationTitle("Select Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        DesignKitHaptics.selection()
                        showIconPicker = false
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignKit.primary)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        ZStack {
            DesignKit.liquidGlassGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    }
}

