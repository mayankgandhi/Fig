//
//  TestAlarmFactory.swift
//  TickerCoreTests
//
//  Builds real `AlarmKit.Alarm` values for tests, and a fake scheduler.
//
//  `AlarmManager` is `@_hasMissingDesignatedInitializers` and `Alarm` exposes no
//  initializer, which is why the existing helpers gave up and fell through to
//  the real `AlarmManager.shared`. But `Alarm` is `Codable`, so an instance can
//  be decoded from JSON assembled out of parts that *are* constructible
//  (`Alarm.Schedule`, `Alarm.State`, `Alarm.CountdownDuration`).
//
//  This is what makes the alarm pipeline's error paths testable at all.
//

import Foundation
import AlarmKit
@testable import TickerCore

@available(iOS 26.0, *)
enum TestAlarmFactory {

    enum FactoryError: Error {
        case couldNotEncodeComponent
    }

    /// Builds an `Alarm` by round-tripping through its `Codable` conformance.
    static func makeAlarm(
        id: UUID = UUID(),
        schedule: Alarm.Schedule? = nil,
        state: Alarm.State = .scheduled,
        countdownDuration: Alarm.CountdownDuration? = nil
    ) throws -> Alarm {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        var object: [String: Any] = [:]
        object["id"] = id.uuidString
        object["state"] = try JSONSerialization.jsonObject(
            with: encoder.encode(state), options: [.fragmentsAllowed]
        )

        if let schedule {
            object["schedule"] = try JSONSerialization.jsonObject(
                with: encoder.encode(schedule), options: [.fragmentsAllowed]
            )
        }
        if let countdownDuration {
            object["countdownDuration"] = try JSONSerialization.jsonObject(
                with: encoder.encode(countdownDuration), options: [.fragmentsAllowed]
            )
        }

        let data = try JSONSerialization.data(withJSONObject: object)
        return try decoder.decode(Alarm.self, from: data)
    }

    /// Convenience: a one-time alarm armed for a specific instant.
    static func makeFixedAlarm(id: UUID = UUID(), at date: Date) throws -> Alarm {
        try makeAlarm(id: id, schedule: .fixed(date))
    }
}

// MARK: - Fake Scheduler

/// A controllable stand-in for `AlarmManager`.
@available(iOS 26.0, *)
final class FakeAlarmScheduler: AlarmScheduling, @unchecked Sendable {

    // State
    var armed: [UUID: Alarm] = [:]

    // Tracking
    private(set) var scheduledIDs: [UUID] = []
    private(set) var cancelledIDs: [UUID] = []
    private(set) var stoppedIDs: [UUID] = []

    // Failure injection
    /// Throws `maximumLimitReached` once this many alarms are armed.
    var scheduleLimit: Int?
    var scheduleError: Error?
    var cancelError: Error?
    var alarmsError: Error?

    /// Schedule stamped onto alarms this fake creates.
    ///
    /// `AlarmManager.AlarmConfiguration` exposes only an initializer — its
    /// `schedule` and `countdownDuration` are not readable — so the fake cannot
    /// mirror what it was handed. Tests that care set this first.
    var nextAlarmSchedule: Alarm.Schedule?

    var authorizationState: AlarmManager.AuthorizationState = .authorized

    var alarms: [Alarm] {
        get throws {
            if let alarmsError { throw alarmsError }
            return Array(armed.values)
        }
    }

    func requestAuthorization() async throws -> AlarmManager.AuthorizationState {
        authorizationState
    }

    @discardableResult
    func schedule(
        id: UUID,
        configuration: AlarmManager.AlarmConfiguration<TickerData>
    ) async throws -> Alarm {
        if let scheduleError { throw scheduleError }
        if let scheduleLimit, armed.count >= scheduleLimit {
            throw AlarmManager.AlarmError.maximumLimitReached
        }

        let alarm = try TestAlarmFactory.makeAlarm(
            id: id,
            schedule: nextAlarmSchedule,
            state: .scheduled
        )
        armed[id] = alarm
        scheduledIDs.append(id)
        return alarm
    }

    func countdown(id: UUID) throws {}

    func cancel(id: UUID) throws {
        if let cancelError { throw cancelError }
        cancelledIDs.append(id)
        armed.removeValue(forKey: id)
    }

    func stop(id: UUID) throws {
        stoppedIDs.append(id)
        armed.removeValue(forKey: id)
    }

    func pause(id: UUID) throws {}
    func resume(id: UUID) throws {}
}
