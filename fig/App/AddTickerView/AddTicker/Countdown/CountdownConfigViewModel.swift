//
//  CountdownConfigViewModel.swift
//  fig
//
//  Manages countdown pre-alert configuration
//

import Foundation

@Observable
final class CountdownConfigViewModel {
    var isEnabled: Bool = false
    var hours: Int = 0
    var minutes: Int = 5
    var seconds: Int = 0

    // MARK: - Computed Properties

    var totalSeconds: Int {
        hours * 3600 + minutes * 60 + seconds
    }

    var displayText: String {
        isEnabled ? "\(hours)h \(minutes)m" : "Countdown"
    }

    var isValid: Bool {
        !isEnabled || totalSeconds > 0
    }
    
    var validationMessage: String? {
        guard isEnabled else { return nil }
        
        if totalSeconds <= 0 {
            return "Countdown must be greater than 0 seconds"
        }
        
        if totalSeconds > 24 * 3600 {
            return "Countdown is very long (over 24 hours)"
        }
        
        if totalSeconds < 60 {
            return "Countdown is very short - consider if this provides enough notice"
        }
        
        if totalSeconds > 6 * 3600 {
            return "Countdown is very long - consider if this is necessary"
        }
        
        return nil
    }
    
    var hasValidationWarning: Bool {
        guard isEnabled else { return false }
        return totalSeconds > 6 * 3600 || totalSeconds < 60
    }

    // MARK: - Methods

    func enable() {
        isEnabled = true
    }

    func disable() {
        isEnabled = false
    }

    func setDuration(hours: Int, minutes: Int, seconds: Int) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }

    func reset() {
        isEnabled = false
        hours = 0
        minutes = 5
        seconds = 0
    }
}
