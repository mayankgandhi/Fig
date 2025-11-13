//
//  AppView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI
import TickerCore
import DesignKit

struct AppView: View {
    // MARK: - Environment

    @Environment(TickerService.self) private var tickerService
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State

    @State private var permissionViewModel: AlarmKitPermissionViewModel?
    @State private var showPermissionSheet: Bool = false

    // MARK: - Initialization

    init() {
        // For large titles - SF Pro Rounded Bold
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 30, weight: .bold).withRoundedDesign()
        ]

        // For inline titles - SF Pro Rounded Bold
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold).withRoundedDesign()
        ]
    }

    // MARK: - Body

    var body: some View {
        TabView {
            Tab("Today", systemImage: "calendar.day.timeline.left") {
                TodayClockView()
            }

            Tab("Scheduled", systemImage: "alarm") {
                ContentView()
            }
        }
        .tint(DesignKit.primary)
        .onAppear {
            checkPermissionStatus()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Recheck permission when app becomes active (e.g., returning from Settings)
            if newPhase == .active {
                checkPermissionStatus()
            }
        }
        .sheet(isPresented: $showPermissionSheet) {
            if let viewModel = permissionViewModel {
                AlarmKitPermissionSheet(
                    viewModel: viewModel,
                    onDismiss: {
                        showPermissionSheet = false
                    }
                )
                .presentationDetents([.medium])
                .presentationCornerRadius(DesignKit.large)
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
            }
        }
    }

    // MARK: - Methods

    private func checkPermissionStatus() {
        if permissionViewModel == nil {
            permissionViewModel = AlarmKitPermissionViewModel(tickerService: tickerService)
        }

        permissionViewModel?.checkAuthorizationStatus()

        if let viewModel = permissionViewModel, viewModel.shouldShowSheet() {
            showPermissionSheet = true
        } else {
            showPermissionSheet = false
        }
    }
}

#Preview {
    AppView()
        .environment(TickerService())
}
