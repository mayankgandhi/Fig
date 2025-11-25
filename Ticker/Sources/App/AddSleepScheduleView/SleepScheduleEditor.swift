//
//  SleepScheduleEditor.swift
//  Ticker
//
//  Created by Claude Code
//  Editor for creating and editing sleep schedule composite tickers
//

import SwiftUI
import SwiftData
import TickerCore
import Factory

struct SleepScheduleEditor: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Injected(\.tickerService) private var tickerService

    @State private var viewModel: SleepScheduleViewModel

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

                ToolbarItem(placement: .navigationBarTrailing) {
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
        }
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        if viewModel.compositeTickerToUpdate != nil {
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
}

// MARK: - Preview

// #Preview {
//     SleepScheduleEditor()
//         .modelContainer(for: [Ticker.self, CompositeTicker.self], inMemory: true)
// }

