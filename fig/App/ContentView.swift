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
    private var displayAlarms: [Ticker] {
        alarmService.getAlarmsWithMetadata(context: modelContext)
    }
    
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
                .presentationBackground {
                    ZStack {
                        TickerColors.liquidGlassGradient(for: colorScheme)

                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    }
                }
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
                        HStack(spacing: TickerSpacing.xs) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add Alarm")
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
            ForEach(displayAlarms, id: \.id) { ticker in
                AlarmCell(alarmItem: ticker)
            }
            .onDelete(perform: deleteAlarms)
        }
        .scrollContentBackground(.hidden)
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
        .environment(AlarmService())
        .modelContainer(for: Ticker.self, inMemory: true)
}
