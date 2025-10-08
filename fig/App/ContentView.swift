/*
 See the LICENSE.txt file for this sample's licensing information.
 
 Abstract:
 The main content view of the app showing the list of alarms.
 */

import SwiftUI
import SwiftData
import WalnutDesignSystem

struct ContentView: View {

    @Environment(AlarmService.self) private var alarmService
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSheet = false
    @State private var showTemplates: Bool = false

    // Fetch alarms from AlarmKit (via AlarmService) and enrich with SwiftData metadata
    private var displayAlarms: [(state: AlarmState, metadata: Ticker?)] {
        alarmService.getAlarmsWithMetadata(context: modelContext)
    }
    
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
                            showTemplates = true
                        }
                    }
                }
        }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            showAddSheet = false
        }) {
            AddAlarmView()
                .presentationCornerRadius(Spacing.large)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTemplates, onDismiss: {
            showTemplates = false
        }, content: {
            TemplatesView()
                .presentationCornerRadius(Spacing.large)
                .presentationDragIndicator(.visible)
        })
        .tint(.accentColor)
    }
    
    var menuButton: some View {
        Button {
            showAddSheet.toggle()
        } label: {
            Image(systemName: "plus")
        }
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
                } description: {
                    Text("Add a new alarm by tapping + button.")
                        .cabinetHeadline()
                } actions: {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add Alarm", systemImage: "plus")
                            .foregroundStyle(Color.white)
                    }
                    .padding(Spacing.small)
                    .background(Color.blue)
                    .cornerRadius(Spacing.large)
                }
            }
        }
    }

    var alarmList: some View {
        List {
            ForEach(displayAlarms, id: \.state.id) { item in
                // Use metadata if available, otherwise create minimal Ticker for display
                if let metadata = item.metadata {
                    AlarmCell(alarmItem: metadata)
                } else {
                    // Orphaned alarm (exists in AlarmKit but not SwiftData)
                    AlarmCell(alarmItem: Ticker(
                        id: item.state.id,
                        label: String(localized: item.state.label),
                        isEnabled: true
                    ))
                }
            }
            .onDelete(perform: deleteAlarms)
        }
    }

    private func deleteAlarms(at offsets: IndexSet) {
        offsets.forEach { index in
            let alarmToDelete = displayAlarms[index]
            try? alarmService.cancelAlarm(id: alarmToDelete.state.id, context: modelContext)
        }
    }
}

#Preview {
    let alarmService = AlarmService()
    return ContentView()
        .modelContainer(for: Ticker.self, inMemory: true)
        .environment(alarmService)
}
