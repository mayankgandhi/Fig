/*
 See the LICENSE.txt file for this sample's licensing information.
 
 Abstract:
 The main content view of the app showing the list of alarms.
 */

import SwiftUI
import SwiftData
import WalnutDesignSystem

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AlarmService.self) private var alarmService

    @State private var showAddSheet = false
    @State private var showTemplates: Bool = false
    @Namespace private var addButtonNamespace

    // Fetch alarms from AlarmKit (via AlarmService)
    private var displayAlarms: [Ticker] = []
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text("Alarms"))
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarItemGroup {
                        menuButton

                    }
                    ToolbarItem {
                        Button("Templates", systemImage: "pencil.and.list.clipboard") {
                            TickerHaptics.selection()
                            showTemplates = true
                        }
                    }
                }
        }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            showAddSheet = false
        }) {
            AddTickerView(namespace: addButtonNamespace)
                .presentationDetents([.height(620)])
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showTemplates, onDismiss: {
            showTemplates = false
        }, content: {
            TemplatesView()
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
        })
        .tint(TickerColors.primary)
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
            if !displayAlarms.isEmpty {
                alarmList
            } else {
                ContentUnavailableView {
                    Text("No Alarms")
                        .cabinetTitle()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                } description: {
                    Text("Add a new alarm by tapping + button.")
                        .cabinetBody()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                } actions: {
                    Button {
                        TickerHaptics.criticalAction()
                        showAddSheet = true
                    } label: {
                        Text("Add Alarm")
                    }
                    .tickerPrimaryButton()
                    .padding(.horizontal, TickerSpacing.xl)
                }
            }
        }
    }

    var alarmList: some View {
        List {
            ForEach(displayAlarms, id: \.id) { ticker in
                AlarmCell(alarmItem: ticker)
            }
            .onDelete(perform: deleteAlarms)
        }
    }

    private func deleteAlarms(at offsets: IndexSet) {
        offsets.forEach { index in
            let alarmToDelete = displayAlarms[index]
            TickerHaptics.warning()
            try? alarmService.cancelAlarm(id: alarmToDelete.id, context: modelContext)
        }
    }
}

#Preview {
    return ContentView()
        .modelContainer(for: Ticker.self, inMemory: true)
}
