//
//  DeviceCapabilities.swift
//  fig
//
//  Device capability detection utilities
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
struct DeviceCapabilities {
    /// Checks if the device supports Apple Intelligence by verifying Foundation Models availability
    static var supportsAppleIntelligence: Bool {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
}
