//
//  SleepScheduleEditor.swift
//  Ticker
//
//  Created by Claude Code
//  Editor for creating and editing sleep schedule ticker collections
//

import SwiftUI
import SwiftData
import TickerCore
import Factory

struct SleepScheduleEditor: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Injected(\.tickerService) private var tickerService
    @Injected(\.tickerCollectionService) private var collectionService

    @State private var viewModel: SleepScheduleViewModel
    @State private var showDeleteConfirmation: Bool = false

    init(viewModel: SleepScheduleViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    headerSection

                    // Circular sleep schedule picker
                    pickerSection

                    // Sleep duration display
                    durationSection

                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.tickerCollectionToUpdate != nil {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                    
                    Button("Save") {
                        Task {
                            await saveSleepSchedule()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isCreating)
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .alert("Delete Sleep Schedule", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    showDeleteConfirmation = false
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteSleepSchedule()
                    }
                }
            } message: {
                if let collection = viewModel.tickerCollectionToUpdate {
                    Text("Are you sure you want to delete \"\(collection.label)\"? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this sleep schedule? This action cannot be undone.")
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        if viewModel.tickerCollectionToUpdate != nil {
            return "Edit Sleep Schedule"
        } else {
            return "New Sleep Schedule"
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        HStack(spacing: 32) {
            // Bedtime info
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.blue)
                    Text("BEDTIME")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Text(viewModel.bedtime.formatted(as: .hourMinute))
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Tomorrow")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Wake up info
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "alarm.fill")
                        .foregroundColor(.orange)
                    Text("WAKE UP")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Text(viewModel.wakeTime.formatted(as: .hourMinute))
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Tomorrow")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var pickerSection: some View {
        VStack(spacing: 16) {
            SleepSchedulePickerView(
                bedtime: $viewModel.bedtime,
                wakeTime: $viewModel.wakeTime
            )
            .glassEffect()
            .padding()
        }
    }

    private var durationSection: some View {
        VStack(spacing: 8) {
            Text("Sleep Duration")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(viewModel.formattedDuration)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    

    // MARK: - Actions

    private func saveSleepSchedule() async {
        do {
            try await viewModel.createSleepSchedule(modelContext: modelContext)
            dismiss()
        } catch {
            // Error is handled by viewModel
            print("Failed to create sleep schedule: \(error)")
        }
    }

    private func deleteSleepSchedule() async {
        guard let collection = viewModel.tickerCollectionToUpdate else { return }
        
        do {
            try await collectionService.deleteTickerCollection(
                collection,
                modelContext: modelContext
            )
            dismiss()
        } catch {
            print("Failed to delete sleep schedule: \(error)")
            // Could show error alert here if needed
        }
    }
}

// MARK: - Preview

// #Preview {
//     SleepScheduleEditor()
//         .modelContainer(for: [Ticker.self, TickerCollection.self], inMemory: true)
// }

