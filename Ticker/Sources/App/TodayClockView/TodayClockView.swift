//
//  TodayClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 07/10/25.
//

import SwiftUI
import SwiftData
import TickerCore
import Gate
import Factory

struct TodayClockView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Injected(\.tickerService) private var tickerService
    @EnvironmentObject private var modelContextObserver: ModelContextObserver
    
    @State private var showSettings: Bool = false
    @State private var showAddSheet: Bool = false
    @State private var showNaturalLanguageSheet: Bool = false
    @State private var viewModel: TodayViewModel
    @State private var alarmToEdit: Ticker?
    @State private var alarmToSkip: UpcomingAlarmPresentation?
    @State private var showSkipConfirmation: Bool = false
    @State private var shouldAnimateAlarms: Bool = false
    @State private var generatedTicker: Ticker?
    @Namespace private var editButtonNamespace
    
    init() {
        _viewModel = State(initialValue: TodayViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.md) {
                    // Clock View (uses unique alarms only)
                    ClockView(upcomingAlarms: viewModel.upcomingAlarmsForClock, shouldAnimateAlarms: shouldAnimateAlarms)
                        .frame(height: UIScreen.main.bounds.width)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Upcoming Alarms Section
                    VStack(alignment: .leading, spacing: TickerSpacing.md) {
                        HStack {
                            
                            Text("Upcoming Tickers")
                                .Title2()
                                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                            
                            
                            Spacer()
                            
                            HStack(alignment: .center, spacing: TickerSpacing.md) {
                                Image(systemName: "clock.fill")
                                    .Body()
                                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                                
                                Text("\(viewModel.upcomingAlarmsCount)")
                                    .Body()
                                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                                
                            }
                        }
                        .padding(.horizontal, TickerSpacing.md)
                        .padding(.top, TickerSpacing.lg)
                        
                        if !viewModel.hasUpcomingAlarms {
                            VStack(spacing: TickerSpacing.sm) {
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.system(.largeTitle, design: .rounded, weight: .medium))
                                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                                
                                Text("No upcoming Tickers")
                                    .TickerTitle()
                                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                                
                                Text("All upcoming alarms will appear here")
                                    .DetailText()
                                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, TickerSpacing.xxl)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TickerSpacing.xxl)
                        } else {
                            LazyVStack(spacing: TickerSpacing.xs) {
                                ForEach(viewModel.upcomingAlarms) { presentation in
                                    UpcomingAlarmRow(
                                        presentation: presentation,
                                        onEdit: { presentation in
                                            handleEditAlarm(presentation)
                                        },
                                        onSkip: { presentation in
                                            handleSkipAlarm(presentation)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(
                ZStack {
                    TickerColor.liquidGlassGradient(for: colorScheme)
                        .ignoresSafeArea()
                    
                    // Subtle overlay for glass effect
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.1)
                        .ignoresSafeArea()
                }
            )
            .navigationTitle("Today")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        TickerHaptics.selection()
                        showNaturalLanguageSheet = true
                    } label: {
                        Image(systemName: "apple.intelligence")
                    }
                    .accessibilityLabel("AI alarm creation")
                    .accessibilityHint("Create alarms using natural language")

                    Button {
                        TickerHaptics.selection()
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Opens app settings")
                }
            }
            .sheet(isPresented: $showNaturalLanguageSheet) {
                SubscriptionGate(feature: .aiAlarmCreation) {
                    NaturalLanguageTickerView()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationCornerRadius(TickerRadius.large)
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $alarmToEdit) { ticker in
                AddTickerView(namespace: editButtonNamespace, prefillTickerId: ticker.persistentModelID, isEditMode: true)
                    .presentationCornerRadius(TickerRadius.large)
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
                    .presentationBackground {
                        ZStack {
                            TickerColor.liquidGlassGradient(for: colorScheme)
                            
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.5)
                        }
                    }
            }
            .onAppear {
                // Load initial data
                Task {
                    await viewModel.refreshAlarms()
                }
                
                // Reset and trigger animation when view appears
                shouldAnimateAlarms = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    shouldAnimateAlarms = true
                }
            }
            .onReceive(modelContextObserver.objectWillChange) { _ in
                // Refresh when any SwiftData context saves (app or widget)
                Task {
                    await viewModel.refreshAlarms()
                }
            }
            .alert(
                "Skip this alarm?",
                isPresented: $showSkipConfirmation,
                presenting: alarmToSkip,
                actions: { presentation in
                    Button("Skip Alarm", role: .destructive) {
                        Task {
                            await performSkipAlarm(presentation)
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        alarmToSkip = nil
                    }
                },
                message: { presentation in
                    if presentation.scheduleType == .oneTime {
                        Text("This will delete the one-time alarm '\(presentation.displayName)'.")
                    } else {
                        Text("This will skip the alarm '\(presentation.displayName)' scheduled for \(presentation.nextAlarmTime, style: .time). The alarm will repeat as scheduled.")
                    }
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTicker(for id: UUID) -> Ticker? {
        let allItemsDescriptor = FetchDescriptor<Ticker>()
        let allItems = try? modelContext.fetch(allItemsDescriptor)
        return allItems?.first(where: { $0.id == id })
    }
    
    private func handleEditAlarm(_ presentation: UpcomingAlarmPresentation) {
        if let ticker = getTicker(for: presentation.baseAlarmId) {
            alarmToEdit = ticker
        }
    }
    
    private func handleSkipAlarm(_ presentation: UpcomingAlarmPresentation) {
        alarmToSkip = presentation
        showSkipConfirmation = true
    }
    
    private func performSkipAlarm(_ presentation: UpcomingAlarmPresentation) async {
        print("🔄 TodayClockView: Starting skip alarm for '\(presentation.displayName)'")
        
        guard let ticker = getTicker(for: presentation.baseAlarmId) else {
            print("⚠️ Could not find ticker for skip action")
            await MainActor.run {
                alarmToSkip = nil
            }
            return
        }
        
        // Play haptic feedback
        await MainActor.run {
            TickerHaptics.warning()
        }
        
        do {
            try await tickerService.cancelAlarm(id: ticker.id, context: modelContext)
            print("   ✅ Deleted one-time alarm: \(ticker.label)")
        } catch {
            print("   ❌ Failed to delete alarm: \(error)")
        }
        
        // Refresh the alarm list and clock
        print("   → Refreshing alarm list and clock...")
        await viewModel.refreshAlarms()
        
        // Clear the skip state
        await MainActor.run {
            alarmToSkip = nil
            print("   ✅ Skip operation completed and UI refreshed")
        }
    }
}


#Preview {
    TodayClockView()
        .modelContainer(for: [Ticker.self])
}
