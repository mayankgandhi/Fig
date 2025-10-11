//
//  TodayClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 07/10/25.
//

import SwiftUI
import SwiftData
import WalnutDesignSystem

struct TodayClockView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AlarmService.self) private var alarmService

    @State private var showSettings: Bool = false
    @State private var viewModel: TodayViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Clock View
                            ClockView(upcomingAlarms: viewModel.upcomingAlarms)
                                .frame(height: UIScreen.main.bounds.width)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)

                            // Upcoming Alarms Section
                            VStack(alignment: .leading, spacing: TickerSpacing.md) {
                                HStack {
                                    Text("Next 12 Hours")
                                        .cabinetTitle()
                                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                                    Spacer()

                                    Text("\(viewModel.upcomingAlarmsCount)")
                                        .cabinetTitle2()
                                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                                }
                                .padding(.horizontal, TickerSpacing.md)
                                .padding(.top, TickerSpacing.lg)

                                if !viewModel.hasUpcomingAlarms {
                                    VStack(spacing: TickerSpacing.sm) {
                                        Image(systemName: "clock.badge.checkmark")
                                            .font(.system(size: 64))
                                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                                        Text("No upcoming alarms")
                                            .cabinetTitle2()
                                            .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                                        Text("Alarms scheduled for the next 12 hours will appear here")
                                            .cabinetFootnote()
                                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, TickerSpacing.xxl)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, TickerSpacing.xxl)
                                } else {
                                    LazyVStack(spacing: 0) {
                                        ForEach(viewModel.upcomingAlarms) { presentation in
                                            UpcomingAlarmRow(presentation: presentation)
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
                    TickerColors.liquidGlassGradient(for: colorScheme)
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        TickerHaptics.selection()
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationCornerRadius(TickerRadius.large)
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = TodayViewModel(alarmService: alarmService, modelContext: modelContext)
                }
            }
        }
    }
}


#Preview {
    TodayClockView()
        .modelContainer(for: [Ticker.self, TemplateCategory.self])
}
