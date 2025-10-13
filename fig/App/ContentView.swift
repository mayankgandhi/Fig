/*
 See the LICENSE.txt file for this sample's licensing information.
 
 Abstract:
 The main content view of the app showing the list of alarms.
 */

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AlarmService.self) private var alarmService

    @State private var showAddSheet = false
    @State private var displayAlarms: [Ticker] = []
    @State private var alarmToEdit: Ticker?
    @State private var alarmToDelete: Ticker?
    @State private var alarmToShowDetail: Ticker?
    @State private var showDeleteAlert = false
    @State private var searchText = ""
    @Namespace private var addButtonNamespace
    @Namespace private var editButtonNamespace
    
    var body: some View {
        NavigationStack {
            content
                .background(
                    ZStack {
                        TickerColors.liquidGlassGradient(for: colorScheme)
                            .ignoresSafeArea()

                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.1)
                            .ignoresSafeArea()
                    }
                )
                .navigationTitle(Text("Tickers"))
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarItemGroup {
                        menuButton
                    }
                }
                .searchable(text: $searchText, prompt: "Search by name or time")
        }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            showAddSheet = false
        }) {
            AddTickerView(namespace: addButtonNamespace)
                .presentationDetents([.height(620)])
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationBackground {
                    ZStack {
                        TickerColors.liquidGlassGradient(for: colorScheme)

                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    }
                }
        }
        .sheet(item: $alarmToEdit) { ticker in
            AddTickerView(namespace: editButtonNamespace, prefillTemplate: ticker, isEditMode: true)
                .presentationDetents([.height(620)])
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationBackground {
                    ZStack {
                        TickerColors.liquidGlassGradient(for: colorScheme)

                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    }
                }
        }
        .sheet(item: $alarmToShowDetail) { ticker in
            AlarmDetailView(
                alarm: ticker,
                onEdit: {
                    alarmToEdit = ticker
                },
                onDelete: {
                    alarmToDelete = ticker
                    showDeleteAlert = true
                }
            )
            .presentationCornerRadius(TickerRadius.large)
            .presentationBackground {
                ZStack {
                    TickerColors.liquidGlassGradient(for: colorScheme)

                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                }
            }
        }
        .alert("Delete Ticker", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                alarmToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let ticker = alarmToDelete {
                    TickerHaptics.warning()
                    if let index = displayAlarms.firstIndex(where: { $0.id == ticker.id }) {
                        deleteAlarms(at: IndexSet(integer: index))
                    }
                }
                alarmToDelete = nil
            }
        } message: {
            if let ticker = alarmToDelete {
                Text("Are you sure you want to delete \"\(ticker.label)\"? This action cannot be undone.")
            }
        }
        .tint(TickerColors.primary)
        .onAppear {
            loadAlarms()
        }
        .onChange(of: alarmService.alarms) { _, _ in
            loadAlarms()
        }
    }

    @MainActor
    private func loadAlarms() {
        displayAlarms = alarmService.getAlarmsWithMetadata(context: modelContext).sorted { ticker1, ticker2 in
            sortByScheduledTime(ticker1, ticker2)
        }
    }

    private var filteredAlarms: [Ticker] {
        guard !searchText.isEmpty else {
            return displayAlarms
        }

        let lowercasedSearch = searchText.lowercased()

        return displayAlarms.filter { ticker in
            // Search by label
            if ticker.label.lowercased().contains(lowercasedSearch) {
                return true
            }

            // Search by time
            if let schedule = ticker.schedule {
                let timeString: String
                switch schedule {
                case .oneTime(let date):
                    // Format as "HH:mm" for one-time alarms
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    timeString = formatter.string(from: date)

                case .daily(let time):
                    // Format as "HH:mm" for daily alarms
                    timeString = String(format: "%02d:%02d", time.hour, time.minute)
                }

                if timeString.contains(lowercasedSearch) {
                    return true
                }
            }

            return false
        }.sorted { ticker1, ticker2 in
            sortByScheduledTime(ticker1, ticker2)
        }
    }

    var menuButton: some View {
        Button {
            TickerHaptics.selection()
            showAddSheet.toggle()
        } label: {
            Image(systemName: "plus")
        }
        .matchedTransitionSource(id: "addButton", in: addButtonNamespace)
    }

    @ViewBuilder
    var content: some View {
        VStack {
            if !filteredAlarms.isEmpty {
                alarmList
            } else if !displayAlarms.isEmpty && searchText.isEmpty {
                alarmList
            } else if !searchText.isEmpty {
                ContentUnavailableView {
                    Text("No Results")
                        .Title3()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                } description: {
                    Text("No tickers match '\(searchText)'")
                        .Body()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                }
            } else {
                ContentUnavailableView {
                    Text("No Tickers")
                        .Title3()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                } description: {
                    Text("Add a new ticker by tapping + button.")
                        .Body()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                } actions: {
                    Button {
                        TickerHaptics.criticalAction()
                        showAddSheet = true
                    } label: {
                        HStack(spacing: TickerSpacing.xs) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add Ticker")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(TickerColors.absoluteWhite)
                        .padding(.horizontal, TickerSpacing.xl)
                        .padding(.vertical, TickerSpacing.md)
                        .background(
                            Capsule()
                                .fill(TickerColors.primary)
                        )
                        .shadow(
                            color: TickerColors.primary.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                }
            }
        }
    }

    var alarmList: some View {
        List {
            ForEach(filteredAlarms, id: \.id) { ticker in
                AlarmCell(alarmItem: ticker) {
                    alarmToShowDetail = ticker
                }
                .listRowInsets(EdgeInsets(top: TickerSpacing.xs, leading: 20, bottom: TickerSpacing.xs, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            TickerHaptics.selection()
                            alarmToEdit = ticker
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(TickerColors.primary)

                        Button(role: .destructive) {
                            TickerHaptics.selection()
                            alarmToDelete = ticker
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func deleteAlarms(at offsets: IndexSet) {
        TickerHaptics.warning()

        // Collect IDs first to avoid index issues
        let alarmsToDelete = offsets.map { displayAlarms[$0] }

        // Delete each alarm
        for alarm in alarmsToDelete {
            try? alarmService.cancelAlarm(id: alarm.id, context: modelContext)
        }

        // Reload the list
        loadAlarms()
    }

    private func toggleAlarmEnabled(_ ticker: Ticker) {
        ticker.isEnabled.toggle()

        // Update in AlarmService
        Task { @MainActor in
            if ticker.isEnabled {
                try? await alarmService.scheduleAlarm(from: ticker, context: modelContext)
            } else {
                try? alarmService.cancelAlarm(id: ticker.id, context: modelContext)
            }
            loadAlarms()
        }
    }

    // MARK: - Sorting Helper

    private func sortByScheduledTime(_ ticker1: Ticker, _ ticker2: Ticker) -> Bool {
        // Extract time components for comparison
        guard let schedule1 = ticker1.schedule, let schedule2 = ticker2.schedule else {
            // If either ticker doesn't have a schedule, keep original order
            if ticker1.schedule != nil { return true }
            if ticker2.schedule != nil { return false }
            return false
        }

        let time1 = getComparableTime(from: schedule1)
        let time2 = getComparableTime(from: schedule2)

        // For one-time schedules, also compare dates
        if case .oneTime(let date1) = schedule1, case .oneTime(let date2) = schedule2 {
            // Sort by full date and time for one-time schedules
            return date1 < date2
        }

        // For mixed or daily schedules, just compare time of day
        return time1 < time2
    }

    private func getComparableTime(from schedule: TickerSchedule) -> TimeInterval {
        switch schedule {
        case .oneTime(let date):
            // Get the time portion of the date as seconds from midnight
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)
            let seconds = (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
            return TimeInterval(seconds)

        case .daily(let time):
            // Convert time to seconds from midnight
            let seconds = time.hour * 3600 + time.minute * 60
            return TimeInterval(seconds)
        }
    }
}

#Preview {
    return ContentView()
        .environment(AlarmService())
        .modelContainer(for: Ticker.self, inMemory: true)
}
