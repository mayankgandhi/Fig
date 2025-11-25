//
//  CompositeTickerDetailView.swift
//  Ticker
//
//  Created by Claude Code
//  Detail view for composite tickers showing child alarms
//

import SwiftUI
import SwiftData
import TickerCore
import Factory

struct CompositeTickerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(TickerService.self) private var tickerService

    let compositeTicker: CompositeTicker
    
    @Injected(\.compositeTickerService) private var compositeService

    @State private var isToggling = false
    @State private var showingEditView = false

    var body: some View {
        List {
            // Master toggle section
            Section {
                Toggle(isOn: Binding(
                    get: { compositeTicker.isEnabled },
                    set: { newValue in
                        Task {
                            await toggleCompositeTicker(enabled: newValue)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: compositeTicker.compositeType.iconName)
                            .foregroundStyle(compositeTicker.presentation.tintColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(compositeTicker.label)
                                .font(.headline)

                            if let config = compositeTicker.sleepScheduleConfig {
                                Text(config.formattedDuration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .disabled(isToggling)
            }

            // Sleep schedule section (for sleep schedule composites)
            if let config = compositeTicker.sleepScheduleConfig {
                Section {
                    // Bedtime display
                    if let bedtimeTicker = compositeTicker.childTickers?.first(where: { $0.label == "Bedtime" }) {
                        childTickerRow(ticker: bedtimeTicker, config: config, isBedtime: true)
                    }

                    // Wake up display
                    if let wakeUpTicker = compositeTicker.childTickers?.first(where: { $0.label == "Wake Up" }) {
                        childTickerRow(ticker: wakeUpTicker, config: config, isBedtime: false)
                    }
                } header: {
                    Text("Schedule")
                }

                // Sleep duration info
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sleep Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(config.formattedDuration)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        if config.meetsGoal {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }

                    if config.meetsGoal {
                        Text("This schedule meets your sleep goal.")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("This schedule is \(String(format: "%.1f", config.sleepGoalHours - config.sleepDuration)) hours short of your goal.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                // Health app link
                Section {
                    Button {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Edit Sleep Schedule in Health")
                                .foregroundColor(.orange)

                            Spacer()

                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }

            // Child tickers section (generic, for other composite types)
            if compositeTicker.compositeType != .sleepSchedule,
               let children = compositeTicker.childTickers,
               !children.isEmpty {
                Section("Alarms") {
                    ForEach(children) { child in
                        genericChildTickerRow(ticker: child)
                    }
                }
            }

            // Delete section
            Section {
                Button(role: .destructive) {
                    Task {
                        await deleteCompositeTicker()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Sleep Schedule")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(compositeTicker.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            // TODO: Edit view for updating sleep schedule
            Text("Edit view coming soon")
        }
    }

    // MARK: - Child Ticker Row (Sleep Schedule specific)

    @ViewBuilder
    private func childTickerRow(ticker: Ticker, config: SleepScheduleConfiguration, isBedtime: Bool) -> some View {
        Toggle(isOn: Binding(
            get: { ticker.isEnabled },
            set: { newValue in
                Task {
                    await toggleChildTicker(ticker, enabled: newValue)
                }
            }
        )) {
            HStack(spacing: 12) {
                Image(systemName: isBedtime ? "bed.double.fill" : "alarm.fill")
                    .foregroundStyle(isBedtime ? Color.blue : Color.orange)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(ticker.label)
                        .font(.body)

                    let time = isBedtime ? config.bedtime : config.wakeTime
                    Text(time.formatted(as: .hourMinute))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .disabled(isToggling)
    }

    // MARK: - Generic Child Ticker Row

    @ViewBuilder
    private func genericChildTickerRow(ticker: Ticker) -> some View {
        Toggle(isOn: Binding(
            get: { ticker.isEnabled },
            set: { newValue in
                Task {
                    await toggleChildTicker(ticker, enabled: newValue)
                }
            }
        )) {
            HStack(spacing: 12) {
                if let icon = ticker.tickerData?.icon {
                    Image(systemName: icon)
                        .foregroundStyle(compositeTicker.presentation.tintColor)
                        .frame(width: 30)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(ticker.label)
                        .font(.body)

                    if let schedule = ticker.schedule {
                        Text(schedule.displaySummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .disabled(isToggling)
    }

    // MARK: - Actions

    private func toggleCompositeTicker(enabled: Bool) async {
        guard !isToggling else { return }
        isToggling = true
        defer { isToggling = false }

        do {
            try await compositeService.toggleCompositeTicker(
                compositeTicker,
                enabled: enabled,
                modelContext: modelContext
            )
        } catch {
            print("Failed to toggle composite ticker: \(error)")
        }
    }

    private func toggleChildTicker(_ ticker: Ticker, enabled: Bool) async {
        guard !isToggling else { return }
        isToggling = true
        defer { isToggling = false }

        do {
            try await compositeService.toggleChildTicker(
                compositeTicker,
                childID: ticker.id,
                enabled: enabled,
                modelContext: modelContext
            )
        } catch {
            print("Failed to toggle child ticker: \(error)")
        }
    }

    private func deleteCompositeTicker() async {
        do {
            try await compositeService.deleteCompositeTicker(
                compositeTicker,
                modelContext: modelContext
            )
            dismiss()
        } catch {
            print("Failed to delete composite ticker: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Ticker.self, CompositeTicker.self, configurations: config)

    let compositeTicker = CompositeTicker(
        label: "Sleep Schedule",
        compositeType: .sleepSchedule,
        configuration: .sleepSchedule(SleepScheduleConfiguration(
            bedtime: TimeOfDay(hour: 22, minute: 0),
            wakeTime: TimeOfDay(hour: 6, minute: 30),
            sleepGoalHours: 8.0
        ))
    )

    let bedtime = Ticker(
        label: "Bedtime",
        schedule: .daily(time: TimeOfDay(hour: 22, minute: 0))
    )

    let wakeUp = Ticker(
        label: "Wake Up",
        schedule: .daily(time: TimeOfDay(hour: 6, minute: 30))
    )

    bedtime.parentCompositeTicker = compositeTicker
    wakeUp.parentCompositeTicker = compositeTicker
    compositeTicker.childTickers = [bedtime, wakeUp]

    container.mainContext.insert(compositeTicker)
    container.mainContext.insert(bedtime)
    container.mainContext.insert(wakeUp)

    return NavigationStack {
        CompositeTickerDetailView(compositeTicker: compositeTicker)
            .modelContainer(container)
            .environment(TickerService())
    }
}
