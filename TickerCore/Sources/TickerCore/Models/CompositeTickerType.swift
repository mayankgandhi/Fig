//
//  CompositeTickerType.swift
//  TickerCore
//
//  Created by Claude Code
//

import Foundation

/// Represents the type of composite ticker
public enum CompositeTickerType: String, Codable, Sendable {
    case sleepSchedule
    case custom
    // Future: medicationSchedule, mealPlan, workoutRoutine, etc.

    public var displayName: String {
        switch self {
        case .sleepSchedule:
            return "Sleep Schedule"
        case .custom:
            return "Custom"
        }
    }

    public var iconName: String {
        switch self {
        case .sleepSchedule:
            return "bed.double.fill"
        case .custom:
            return "square.stack.3d.up.fill"
        }
    }
}
