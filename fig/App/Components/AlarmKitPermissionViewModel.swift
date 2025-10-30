//
//  AlarmKitPermissionViewModel.swift
//  Ticker
//
//  Created by Claude Code
//

import Foundation
import TickerCore
import UIKit

@Observable
final class AlarmKitPermissionViewModel {
    // MARK: - Properties

    private let tickerService: TickerService

    var authorizationStatus: AlarmAuthorizationStatus
    var isRequestingPermission: Bool = false
    var errorMessage: String?

    // MARK: - Initialization

    init(tickerService: TickerService) {
        self.tickerService = tickerService
        self.authorizationStatus = tickerService.authorizationStatus
    }

    // MARK: - Business Logic

    /// Checks the current authorization status from TickerService
    func checkAuthorizationStatus() {
        authorizationStatus = tickerService.authorizationStatus
    }

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
            authorizationStatus = tickerService.authorizationStatus
        } catch {
            errorMessage = "Failed to request permission: \(error.localizedDescription)"
        }

        isRequestingPermission = false
    }

    /// Opens the iOS Settings app to the Ticker app settings
    func openSettings() {
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
            return "Never Miss a Moment"
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
            return "Ticker works seamlessly with your device to wake you up reliably, every time."
        case .denied:
            return "To use Ticker, please enable alarm access in your device settings."
        case .authorized:
            return "Ticker is ready to help you start each day on time."
        }
    }

    /// Returns the appropriate features list based on authorization status
    var features: [String] {
        switch authorizationStatus {
        case .notDetermined:
            return [
                "System-level alarm reliability",
                "Works even when app is closed",
                "Live Activities and widgets"
            ]
        case .denied, .authorized:
            return []
        }
    }

    /// Returns the appropriate button title based on authorization status
    var buttonTitle: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Continue"
        case .denied:
            return "Open Settings"
        case .authorized:
            return "Get Started"
        }
    }
}
