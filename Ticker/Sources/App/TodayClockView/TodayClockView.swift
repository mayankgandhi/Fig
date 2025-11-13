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

struct TodayClockView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(TickerService.self) private var tickerService
    @EnvironmentObject private var modelContextObserver: ModelContextObserver

    @State private var showSettings: Bool = false
    @State private var showAddSheet: Bool = false
    @State private var showNaturalLanguageSheet: Bool = false
    @State private var viewModel: TodayViewModel
    @State private var alarmToEdit: Ticker?
    @State private var shouldAnimateAlarms: Bool = false
    @State private var generatedTicker: Ticker?
    @Namespace private var editButtonNamespace
    @Namespace private var addButtonNamespace

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
                                    UpcomingAlarmRow(presentation: presentation)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button {
                                                TickerHaptics.selection()
                                                if let ticker = getTicker(for: presentation.baseAlarmId) {
                                                    alarmToEdit = ticker
                                                }
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(TickerColor.primary)
                                        }
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
                        if #available(iOS 26.0, *), DeviceCapabilities.supportsAppleIntelligence {
                            showNaturalLanguageSheet = true
                        } else {
                            showAddSheet = true
                        }
                    } label: {
                        if #available(iOS 26.0, *), DeviceCapabilities.supportsAppleIntelligence {
                            Image(systemName: "apple.intelligence")
                        } else {
                            Image(systemName: "plus")
                        }
                    }
                    .matchedTransitionSource(id: "addButton", in: addButtonNamespace)

                    Button {
                        TickerHaptics.selection()
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showNaturalLanguageSheet) {
                SubscriptionGate(feature: .aiAlarmCreation) {
                    NaturalLanguageTickerView()
                }                
            }
            .sheet(isPresented: $showAddSheet, onDismiss: {
                generatedTicker = nil
            }) {
                AddTickerView(
                    namespace: addButtonNamespace
                )
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
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTicker(for id: UUID) -> Ticker? {
        let allItemsDescriptor = FetchDescriptor<Ticker>()
        let allItems = try? modelContext.fetch(allItemsDescriptor)
        return allItems?.first(where: { $0.id == id })
    }
}


#Preview {
    TodayClockView()
        .modelContainer(for: [Ticker.self])
}
