//
//  Analytics+Extension.swift
//  Ticker
//
//  Created by Claude Code
//

import Foundation
import Telemetry

extension AnalyticsEvents {
    /// Track this analytics event
    func track() {
        TelemetryService.shared.track(event: eventName, properties: properties)
    }
}
