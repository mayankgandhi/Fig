//
//  AlarmFireDetector.swift
//  TickerCore
//
//  Answers the question the app could not previously answer: did alarms fire?
//
//  `AlarmManager.alarmUpdates` looks like the obvious mechanism and is not one.
//  It is an in-process AsyncSequence, and nothing launches the app when an alarm
//  fires — no background mode covers it, no push arrives. A user who sets a 7am
//  alarm and does not open the app overnight produces no elements at all, and by
//  the time they do open it the `.alerting` transition is long gone. Observing it
//  would report ~0 fires for exactly the population being measured.
//
//  So detection is done two ways, neither of which needs the app to be running
//  at fire time:
//
//  1. Absence inference. Every expanded one-time occurrence is written to a small
//     App Group log when it is scheduled. At launch, any occurrence whose fire
//     date has passed and which is no longer armed in AlarmKit must have fired.
//  2. Reactions. Stop / Repeat / Open run in an intent process that really does
//     execute at fire time; those are recorded by `AlarmReactionRecorder` and
//     drained here.
//
//  The denominator is computed by expanding each enabled ticker's schedule over
//  the interval since the last check.
//

import Foundation
import SwiftData
import AlarmKit

// MARK: - Occurrence Log

/// A small App Group-backed record of scheduled one-time occurrences.
///
/// Deliberately not a SwiftData attribute: this is transient bookkeeping, and
/// putting it in the store would mean a schema migration on a store that three
/// processes open, for data that does not belong to the user.
public enum AlarmOccurrenceLog {

    private static let key = "scheduledAlarmOccurrences"

    public struct Occurrence: Sendable {
        public let alarmID: UUID
        public let fireDate: Date
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: TickerSchema.appGroupIdentifier)
    }

    public static func record(alarmID: UUID, fireDate: Date) {
        guard let defaults else { return }
        var stored = defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
        stored[alarmID.uuidString] = fireDate.timeIntervalSince1970
        // Bound the log; stale entries are pruned on every drain anyway.
        if stored.count > 500 {
            let oldest = stored.sorted { $0.value < $1.value }.prefix(stored.count - 500)
            for entry in oldest { stored.removeValue(forKey: entry.key) }
        }
        defaults.set(stored, forKey: key)
    }

    public static func remove(alarmIDs: [UUID]) {
        guard let defaults, !alarmIDs.isEmpty else { return }
        var stored = defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
        for id in alarmIDs { stored.removeValue(forKey: id.uuidString) }
        defaults.set(stored, forKey: key)
    }

    public static func all() -> [Occurrence] {
        guard let defaults,
              let stored = defaults.dictionary(forKey: key) as? [String: Double] else {
            return []
        }
        return stored.compactMap { key, value in
            guard let id = UUID(uuidString: key) else { return nil }
            return Occurrence(alarmID: id, fireDate: Date(timeIntervalSince1970: value))
        }
    }
}

// MARK: - Detector

public enum AlarmFireDetector {

    private static let lastCheckKey = "alarmFireDetectorLastCheck"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: TickerSchema.appGroupIdentifier)
    }

    public struct Result: Sendable {
        public let inferredFires: Int
        public let reactions: Int
        public let expected: Int
        public let scheduledCount: Int
    }

    /// Runs the detection sweep. Call at launch and on foreground.
    @discardableResult
    @MainActor
    public static func detect(
        alarmManager: any AlarmScheduling,
        stateManager: AlarmStateManagerProtocol,
        context: ModelContext
    ) -> Result {
        let now = Date()
        let lastCheck = (defaults?.object(forKey: lastCheckKey) as? Date) ?? now

        let armed = (try? stateManager.queryAlarmKit(alarmManager: alarmManager)) ?? []
        let armedIDs = Set(armed.map(\.id))

        // 1. Absence inference over the occurrence log.
        var inferred = 0
        var resolved: [UUID] = []
        for occurrence in AlarmOccurrenceLog.all() where occurrence.fireDate <= now {
            if !armedIDs.contains(occurrence.alarmID) {
                AlarmTelemetry.record(
                    .alarmFiredInferred(
                        alarmID: occurrence.alarmID,
                        scheduledAt: occurrence.fireDate,
                        detectedAt: now
                    )
                )
                inferred += 1
                resolved.append(occurrence.alarmID)
            }
        }
        AlarmOccurrenceLog.remove(alarmIDs: resolved)

        // 2. Reactions recorded by intent processes since we last looked.
        let reactions = AlarmReactionRecorder.drainPending()
        for reaction in reactions {
            AlarmTelemetry.record(.alarmReaction(kind: reaction.kind, alarmID: reaction.alarmID))
        }

        // 3. Denominator: occurrences that should have fired since the last check.
        let expected = expectedFireCount(since: lastCheck, until: now, context: context)
        if expected > 0 {
            AlarmTelemetry.record(.alarmsExpected(count: expected, since: lastCheck))
        }

        AlarmTelemetry.record(.scheduledAlarmCount(count: armed.count))
        defaults?.set(now, forKey: lastCheckKey)

        let result = Result(
            inferredFires: inferred,
            reactions: reactions.count,
            expected: expected,
            scheduledCount: armed.count
        )

        print("🔔 Fire detection: \(inferred) inferred, \(reactions.count) reactions, \(expected) expected, \(armed.count) armed")
        return result
    }

    /// Counts occurrences that should have fired in the interval, across every
    /// enabled ticker, by expanding each schedule over that window.
    @MainActor
    private static func expectedFireCount(
        since start: Date,
        until end: Date,
        context: ModelContext
    ) -> Int {
        guard end > start else { return 0 }

        let descriptor = FetchDescriptor<Ticker>()
        guard let tickers = try? context.fetch(descriptor) else { return 0 }

        let expander = TickerScheduleExpander()
        let window = DateInterval(start: start, end: end)

        return tickers
            .filter { $0.isEnabled }
            .compactMap { $0.schedule }
            .reduce(0) { total, schedule in
                total + expander.expandSchedule(schedule, within: window).count
            }
    }
}
