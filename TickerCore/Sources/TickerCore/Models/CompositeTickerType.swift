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
    // Future: medicationSchedule, mealPlan, workoutRoutine, etc.

    public var displayName: String {
        switch self {
        case .sleepSchedule:
            return "Sleep Schedule"
        }
    }

    public var iconName: String {
        switch self {
        case .sleepSchedule:
            return "bed.double.fill"
        }
    }
}
