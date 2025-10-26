//
//  AlarmHealth.swift
//  fig
//
//  Health monitoring for alarm regeneration status
//  Provides user-visible indicators of alarm system health
//

import Foundation

// MARK: - HealthStatus

enum HealthStatus: String, Codable {
    case healthy    // Everything is working properly
    case warning    // Minor issues but alarms still functional
    case critical   // Serious issues that may affect alarm delivery

    var icon: String {
        switch self {
        case .healthy:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .healthy:
            return "green"
        case .warning:
            return "orange"
        case .critical:
            return "red"
        }
    }
}

// MARK: - AlarmHealth

struct AlarmHealth: Codable, Equatable {
    /// When alarms were last regenerated
    var lastRegenerationDate: Date?

    /// Whether the last regeneration was successful
    var lastRegenerationSuccess: Bool

    /// Number of active (future) alarms currently scheduled
    var activeAlarmCount: Int

    /// Time since last successful regeneration
    var staleness: TimeInterval {
        guard let lastDate = lastRegenerationDate else {
            return TimeInterval.infinity  // Never regenerated
        }
        return Date().timeIntervalSince(lastDate)
    }

    // MARK: - Status Calculation

    /// Overall health status of the alarm system
    var status: HealthStatus {
        // Critical: Never regenerated
        guard lastRegenerationDate != nil else {
            return .critical
        }

        // Critical: Last regeneration failed
        guard lastRegenerationSuccess else {
            return .critical
        }

        // Critical: No alarms scheduled
        guard activeAlarmCount > 0 else {
            return .critical
        }

        // Warning: Stale (> 24 hours since last regeneration)
        if staleness > 24 * 3600 {
            return .warning
        }

        // Critical: Very stale (> 48 hours)
        if staleness > 48 * 3600 {
            return .critical
        }

        // Healthy
        return .healthy
    }

    /// User-friendly status message
    var statusMessage: String {
        switch status {
        case .healthy:
            return "All alarms are up to date"
        case .warning:
            if staleness > 24 * 3600 {
                return "Alarms haven't been updated in \(stalenessDescription)"
            }
            return "Some alarms may need attention"
        case .critical:
            if lastRegenerationDate == nil {
                return "Alarms need to be configured"
            } else if !lastRegenerationSuccess {
                return "Last alarm update failed"
            } else if activeAlarmCount == 0 {
                return "No alarms are scheduled"
            } else {
                return "Alarms are critically out of date"
            }
        }
    }

    /// Detailed status for debugging or settings UI
    var detailedStatus: String {
        var details: [String] = []

        if let lastDate = lastRegenerationDate {
            details.append("Last updated: \(lastUpdatedDescription)")
        } else {
            details.append("Never updated")
        }

        details.append("\(activeAlarmCount) alarm\(activeAlarmCount == 1 ? "" : "s") scheduled")

        if !lastRegenerationSuccess {
            details.append("Last update failed")
        }

        return details.joined(separator: " • ")
    }

    /// Human-readable "last updated" description
    var lastUpdatedDescription: String {
        guard let lastDate = lastRegenerationDate else {
            return "Never"
        }

        let now = Date()
        let interval = now.timeIntervalSince(lastDate)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }

    /// Human-readable staleness description
    private var stalenessDescription: String {
        if staleness < 3600 {
            let minutes = Int(staleness / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if staleness < 86400 {
            let hours = Int(staleness / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let days = Int(staleness / 86400)
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }

    // MARK: - Initialization

    init(
        lastRegenerationDate: Date? = nil,
        lastRegenerationSuccess: Bool = false,
        activeAlarmCount: Int = 0
    ) {
        self.lastRegenerationDate = lastRegenerationDate
        self.lastRegenerationSuccess = lastRegenerationSuccess
        self.activeAlarmCount = activeAlarmCount
    }

    /// Create a healthy status after successful regeneration
    static func healthy(alarmCount: Int) -> AlarmHealth {
        AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: true,
            activeAlarmCount: alarmCount
        )
    }

    /// Create a failed status after unsuccessful regeneration
    static func failed(previousHealth: AlarmHealth) -> AlarmHealth {
        AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: false,
            activeAlarmCount: previousHealth.activeAlarmCount
        )
    }

    /// Create initial status for new ticker
    static func initial() -> AlarmHealth {
        AlarmHealth(
            lastRegenerationDate: nil,
            lastRegenerationSuccess: false,
            activeAlarmCount: 0
        )
    }
}
