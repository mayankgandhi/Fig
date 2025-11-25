//
//  AddSleepScheduleView.swift
//  Ticker
//
//  Created by Claude Code
//  Main view for creating sleep schedule composite tickers
//

import SwiftUI
import SwiftData
import TickerCore
import Factory

struct AddSleepScheduleView: View {

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

                    // Edit Sleep Schedule in Health button
                    healthLinkButton
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Change Wake Up")
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
            Text(viewModel.formattedDuration)
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.goalMessage)
                .font(.subheadline)
                .foregroundColor(viewModel.meetsGoal ? .green : .orange)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private var healthLinkButton: some View {
        Button {
            // Open Health app sleep schedule
            if let url = URL(string: "x-apple-health://") {
                UIApplication.shared.open(url)
            }
        } label: {
            Text("Edit Sleep Schedule in Health")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
        }
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
//     AddSleepScheduleView()
//         .modelContainer(for: [Ticker.self, CompositeTicker.self], inMemory: true)
// }
