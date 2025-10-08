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
    @Query(sort: \AlarmItem.createdAt, order: .reverse) private var alarmItems: [AlarmItem]

    @State private var showAddSheet = false
    @State private var showTemplates: Bool = false
    
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
            AlarmAddView()
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
            if !alarmItems.isEmpty {
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
            ForEach(alarmItems) { alarmItem in
                AlarmCell(alarmItem: alarmItem)
            }
            .onDelete(perform: deleteAlarms)
        }
    }

    private func deleteAlarms(at offsets: IndexSet) {
        offsets.forEach { index in
            let alarmItem = alarmItems[index]
            try? alarmService.cancelAlarm(id: alarmItem.id, context: nil)
        }
    }
}

#Preview {
    let alarmService = AlarmService()
    return ContentView()
        .modelContainer(for: AlarmItem.self, inMemory: true)
        .environment(alarmService)
}
