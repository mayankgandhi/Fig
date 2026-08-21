//
//  AlarmTelemetry.swift
//  TickerCore
//
//  A telemetry seam for the alarm pipeline.
//
//  Why this exists: the app had ~158 analytics events wired to PostHog and not a
//  single one recorded an alarm actually firing. TickerCore contained 251
//  `print()` calls and zero `.track()` calls, and it cannot reach the app
//  target's `AnalyticsEvents` type anyway (TickerCore depends only on Factory).
//  The result was that the app's one promise — it wakes you up — was the only
//  thing it could not measure, so a total failure of the alarm pipeline was
//  invisible until a user complained.
//
//  TickerCore raises events through `AlarmTelemetry`; the app installs a sink
//  that forwards them to PostHog. Nothing here knows what PostHog is.
//

import Foundation

// MARK: - Events

public enum AlarmTelemetryEvent: Sendable {

    /// An alarm was observed to have fired. Detected at launch/foreground by
    /// noticing that a scheduled occurrence is in the past and no longer present
    /// in AlarmKit — the app is not running when an alarm fires, so this can
    /// never be observed live.
    case alarmFiredInferred(alarmID: UUID, scheduledAt: Date, detectedAt: Date)

    /// The denominator for the fire-rate metric: occurrences that should have
    /// fired since the last time we looked.
    case alarmsExpected(count: Int, since: Date)

    /// How many alarms are currently armed in AlarmKit, sampled at launch.
    case scheduledAlarmCount(count: Int)

    /// The user reacted to a ringing alarm. Proves a fire independently of
    /// inference, because the intent process really does run at that moment.
    case alarmReaction(kind: AlarmReactionKind, alarmID: UUID)

    /// Scheduling failed. `reason` is a stable, low-cardinality string.
    case alarmScheduleFailed(reason: String)

    /// The AlarmKit per-app alarm budget was hit.
    case alarmBudgetExhausted(scheduled: Int, limit: Int)
}

public enum AlarmReactionKind: String, Sendable {
    case stopped
    case snoozed
    case openedApp
    case paused
    case resumed
    case stopFailed
}

// MARK: - Sink

/// Implemented by the app target, which owns the analytics transport.
public protocol AlarmTelemetrySink: Sendable {
    func record(_ event: AlarmTelemetryEvent)
}

// MARK: - Facade

public enum AlarmTelemetry {

    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var sink: (any AlarmTelemetrySink)?

        func install(_ newSink: any AlarmTelemetrySink) {
            lock.lock(); defer { lock.unlock() }
            sink = newSink
        }

        func current() -> (any AlarmTelemetrySink)? {
            lock.lock(); defer { lock.unlock() }
            return sink
        }
    }

    private static let storage = Storage()

    /// Called once at app launch. Extension processes (widget, intents) normally
    /// have no sink installed; events raised there are dropped, which is fine —
    /// the reaction they record is re-derived at the next launch by inference.
    public static func install(_ sink: any AlarmTelemetrySink) {
        storage.install(sink)
    }

    public static func record(_ event: AlarmTelemetryEvent) {
        storage.current()?.record(event)
    }
}

// MARK: - Reaction recording from intent processes

/// Records a user reaction to a ringing alarm.
///
/// A `LiveActivityIntent` runs in a short-lived process that may be suspended as
/// soon as `perform()` returns, so anything asynchronous here is unreliable.
/// The reaction is therefore written synchronously to the shared App Group
/// defaults and picked up by the app at its next launch, in addition to being
/// offered to any sink that happens to be installed.
public enum AlarmReactionRecorder {

    private static let pendingKey = "pendingAlarmReactions"

    public static func record(_ kind: AlarmReactionKind, alarmID: UUID) {
        AlarmTelemetry.record(.alarmReaction(kind: kind, alarmID: alarmID))

        guard let defaults = UserDefaults(suiteName: TickerSchema.appGroupIdentifier) else { return }
        var pending = defaults.array(forKey: pendingKey) as? [[String: Any]] ?? []
        pending.append([
            "kind": kind.rawValue,
            "alarmID": alarmID.uuidString,
            "at": Date().timeIntervalSince1970
        ])
        // Bounded: this is bookkeeping, not an audit log.
        if pending.count > 50 { pending.removeFirst(pending.count - 50) }
        defaults.set(pending, forKey: pendingKey)
    }

    /// Drains reactions recorded by extension processes. Called by the app at
    /// launch/foreground, where a sink is installed.
    public static func drainPending() -> [(kind: AlarmReactionKind, alarmID: UUID, at: Date)] {
        guard let defaults = UserDefaults(suiteName: TickerSchema.appGroupIdentifier),
              let pending = defaults.array(forKey: pendingKey) as? [[String: Any]] else {
            return []
        }
        defaults.removeObject(forKey: pendingKey)

        return pending.compactMap { entry in
            guard let kindRaw = entry["kind"] as? String,
                  let kind = AlarmReactionKind(rawValue: kindRaw),
                  let idString = entry["alarmID"] as? String,
                  let id = UUID(uuidString: idString),
                  let at = entry["at"] as? TimeInterval else {
                return nil
            }
            return (kind, id, Date(timeIntervalSince1970: at))
        }
    }
}
