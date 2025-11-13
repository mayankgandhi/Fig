//
//  AlarmStateManager.swift
//  fig
//
//  Provides AlarmKit query functionality
//  Note: No longer maintains in-memory cache - SwiftData is the single source of truth
//

import Foundation
import AlarmKit
import SwiftUI

// MARK: - AlarmStateManager Protocol

public protocol AlarmStateManagerProtocol: Observable {
    func queryAlarmKit(alarmManager: AlarmManager) throws -> [Alarm]
}

// MARK: - AlarmStateManager Implementation

@Observable
public final class AlarmStateManager: AlarmStateManagerProtocol {

    public init() {}

    /// Centralized AlarmKit query method
    /// All code should use this instead of directly accessing alarmManager.alarms
    /// - Parameter alarmManager: The AlarmManager instance to query
    /// - Returns: Array of Alarm objects from AlarmKit
    /// - Throws: AlarmKit errors if query fails
    public func queryAlarmKit(alarmManager: AlarmManager) throws -> [Alarm] {
        return try alarmManager.alarms
    }
}
