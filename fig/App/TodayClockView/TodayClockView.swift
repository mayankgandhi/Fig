//
//  TodayClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 07/10/25.
//

import SwiftUI
import SwiftData

struct TodayClockView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(TickerService.self) private var tickerService
    
    @State private var showSettings: Bool = false
    @State private var showAddSheet: Bool = false
    @State private var showNaturalLanguageSheet: Bool = false
    @State private var viewModel: TodayViewModel?
    @State private var alarmToEdit: Ticker?
    @State private var shouldAnimateAlarms: Bool = false
    @State private var generatedTicker: Ticker?
    @Namespace private var editButtonNamespace
    @Namespace private var addButtonNamespace
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Clock View
                            ClockView(upcomingAlarms: viewModel.upcomingAlarms, shouldAnimateAlarms: shouldAnimateAlarms)
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
                                            .font(.system(size: 64))
                                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                                        
                                        Text("No upcoming alarms")
                                            .Title2()
                                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                                        
                                        Text("Alarms scheduled for the next 12 hours will appear here")
                                            .Footnote()
                                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, TickerSpacing.xxl)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, TickerSpacing.xxl)
                                } else {
                                    LazyVStack(spacing: 0) {
                                        ForEach(viewModel.upcomingAlarms) { presentation in
                                            UpcomingAlarmRow(presentation: presentation)
                                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                    Button {
                                                        TickerHaptics.selection()
                                                        if let ticker = getTicker(for: presentation.id) {
                                                            alarmToEdit = ticker
                                                        }
                                                    } label: {
                                                        Label("Edit", systemImage: "pencil")
                                                    }
                                                    .tint(TickerColor.primary)
                                                }
                                        }
                                    }
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 24)
                        }
                    }
                } else {
                    ProgressView()
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
                        Image(systemName: "plus")
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
                NaturalLanguageTickerView(
                    namespace: addButtonNamespace,
                    onGenerated: { ticker in
                        generatedTicker = ticker
                        showNaturalLanguageSheet = false
                        showAddSheet = true
                    },
                    onSkip: {
                        showNaturalLanguageSheet = false
                        showAddSheet = true
                    }
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
            .sheet(isPresented: $showAddSheet, onDismiss: {
                generatedTicker = nil
            }) {
                AddTickerView(
                    namespace: addButtonNamespace,
                    prefillTemplate: generatedTicker
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
                AddTickerView(namespace: editButtonNamespace, prefillTemplate: ticker, isEditMode: true)
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
                if viewModel == nil {
                    viewModel = TodayViewModel(tickerService: tickerService, modelContext: modelContext)
                }
                
                // Reset and trigger animation when view appears
                shouldAnimateAlarms = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    shouldAnimateAlarms = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTicker(for id: UUID) -> Ticker? {
        let descriptor = FetchDescriptor<Ticker>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }
}


#Preview {
    TodayClockView()
        .modelContainer(for: [Ticker.self])
}
