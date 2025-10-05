/*
 See the LICENSE.txt file for this sample's licensing information.
 
 Abstract:
 The main content view of the app showing the list of alarms.
 */

import AlarmKit
import SwiftUI
import WalnutDesignSystem

struct ContentView: View {
    
    @Environment(ViewModel.self) private var viewModel
    
    @State private var showAddSheet = false
    @State var showSettings: Bool = false
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text("Alarms").font(.cabinetLargeTitle))
                .navigationBarTitleDisplayMode(.automatic)
                .toolbar {
                    ToolbarItemGroup {
                        menuButton
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
        .sheet(isPresented: $showAddSheet) {
            AlarmAddView()
        }
        .sheet(isPresented: $showSettings, content: {
            SettingsView()
        })
        .environment(viewModel)
        .onAppear {
            viewModel.fetchAlarms()
        }
        .tint(.accentColor)
    }
    
    var menuButton: some View {
        Menu {
            // Schedules an alarm with an alert but no additional configuration.
            Button {
                viewModel.scheduleAlertOnlyExample()
            } label: {
                Label("Alert only", systemImage: "bell.circle.fill")
            }
            
            // Schedules an alarm with a countdown button.
            Button {
                viewModel.scheduleCountdownAlertExample()
            } label: {
                Label("With Countdown", systemImage: "fitness.timer.fill")
            }
            
            // Schedules an alarm with a custom button to launch the app.
            Button {
                viewModel.scheduleCustomButtonAlertExample()
            } label: {
                Label("With Custom Button", systemImage: "alarm")
            }
            
            // Displays a sheet with configuration options for a new alarm.
            Button {
                showAddSheet.toggle()
            } label: {
                Label("Configure", systemImage: "pencil.and.scribble")
            }
        } label: {
            Image(systemName: "plus")
        }
    }
    
    @ViewBuilder
    var content: some View {
        VStack {
            
            ClockView()
            
            if viewModel.hasUpcomingAlerts {
                alarmList(alarms: Array(viewModel.alarmsMap.values))
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
    
    func alarmList(alarms: [ViewModel.AlarmsMap.Value]) -> some View {
        List {
            ForEach(alarms, id: \.0.id) { (alarm, label) in
                AlarmCell(alarm: alarm, label: label)
            }
            .onDelete { indexSet in
                indexSet.forEach { idx in
                    viewModel.unscheduleAlarm(with: alarms[idx].0.id)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(ViewModel())
}
