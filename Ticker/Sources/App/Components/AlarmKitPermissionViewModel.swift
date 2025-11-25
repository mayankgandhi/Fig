//
//  AlarmKitPermissionViewModel.swift
//  Ticker
//
//  Created by Claude Code
//

import Foundation
import TickerCore
import UIKit
import Factory

@Observable
final class AlarmKitPermissionViewModel {
    // MARK: - Properties

    @ObservationIgnored
    @Injected(\.tickerService) var tickerService

    var authorizationStatus: AlarmAuthorizationStatus {
        tickerService.authorizationStatus
    }
    var isRequestingPermission: Bool = false
    var errorMessage: String?

    /// Determines if the permission sheet should be shown
    /// Returns true if status is .notDetermined or .denied
    func shouldShowSheet() -> Bool {
        return authorizationStatus == .notDetermined || authorizationStatus == .denied
    }

    /// Requests AlarmKit authorization from the user
    @MainActor
    func requestPermission() async {
        guard authorizationStatus == .notDetermined else {
            return
        }

        isRequestingPermission = true
        errorMessage = nil

        do {
            try await tickerService.requestAuthorization()
            // Update status after request
            // Track permission result
            if authorizationStatus == .authorized {
                AnalyticsEvents.onboardingPermissionGranted.track()
                AnalyticsEvents.permissionGranted.track()
            } else if authorizationStatus == .denied {
                AnalyticsEvents.onboardingPermissionDenied.track()
                AnalyticsEvents.permissionDenied.track()
            }
        } catch {
            errorMessage = "Failed to request permission: \(error.localizedDescription)"
        }

        isRequestingPermission = false
    }

    /// Opens the iOS Settings app to the Ticker app settings
    func openSettings() {
        AnalyticsEvents.permissionSettingsOpened.track()

        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }

    /// Returns the appropriate title based on authorization status
    var title: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Allow Alarm Access"
        case .denied:
            return "Alarm Permission Needed"
        case .authorized:
            return "You're All Set!"
        }
    }

    /// Returns the appropriate description based on authorization status
    var description: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Ticker needs permission to schedule alarms on your device."
        case .denied:
            return "Please enable alarm access in Settings to use Ticker."
        case .authorized:
            return "Ticker is ready to help you start each day on time."
        }
    }

    /// Returns the appropriate features list based on authorization status
    var features: [String] {
        // Removed features list to reduce content volume for half-page sheet
        return []
    }

    /// Returns the appropriate button title based on authorization status
    var buttonTitle: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Allow Access"
        case .denied:
            return "Open Settings"
        case .authorized:
            return "Get Started"
        }
    }
}
