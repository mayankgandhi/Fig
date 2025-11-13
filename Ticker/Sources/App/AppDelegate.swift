//
//  AppDelegate.swift
//  Ticker
//
//  Created by Claude Code
//

import Foundation
import Telemetry
import UIKit
#if DEBUG
import Atlantis
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        initializeDebugTools()
        // Configure Telemetry with PostHog provider
        let provider = PostHogProvider(
            apiKey: "phc_bXL6Ed1ZvsOwRMUrOFd42Z10OQyOdCoO2gG7hRGM5mj",
            host: "https://us.i.posthog.com"
        )
        
        TelemetryService.shared.configure(provider: provider)
        
        print("✅ Analytics configured with PostHog")
        
        return true
    }
    
    
    private func initializeDebugTools() {
#if DEBUG
        Atlantis.start()
#endif
    }
}
