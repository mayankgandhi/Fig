//
//  AlarmTelemetryAndMigrationTests.swift
//  TickerCoreTests
//
//  Covers the three modules the reliability work added and left untested:
//  AlarmTelemetry, AlarmFireDetector (with AlarmOccurrenceLog), and
//  AlarmScheduleMigration.
//
//  These matter more than their line count suggests. The telemetry path is the
//  only reason a total failure of the alarm pipeline is detectable at all, and
//  the migration is what stops an existing user's Mon-Fri alarm from going
//  silent within seven days of this release. Both were shipping unexercised.
//

import Foundation
import XCTest
import SwiftData
import AlarmKit
@testable import TickerCore

// MARK: - Test doubles

/// A state manager that reports what the fake scheduler is actually holding.
///
/// `MockAlarmStateManager` returns a static array, which cannot express
/// "re-read AlarmKit after cancelling" — the exact step the migration relies on
/// to avoid double alerts.
@available(iOS 26.0, *)
@Observable
final class LiveFakeStateManager: AlarmStateManagerProtocol {

    var failQuery = false
    /// Fails only the Nth query (1-based). Used to fail the *re-read* after a
    /// cancel while letting the initial read succeed.
    var failQueryOnCall: Int?
    private(set) var queryCount = 0

    func queryAlarmKit(alarmManager: any AlarmScheduling) throws -> [Alarm] {
        queryCount += 1
        if failQuery || failQueryOnCall == queryCount {
            throw NSError(domain: "TestError", code: 1)
        }
        return try alarmManager.alarms
    }
}

@available(iOS 26.0, *)
final class RecordingTelemetrySink: AlarmTelemetrySink, @unchecked Sendable {
    private let lock = NSLock()
    private var _events: [AlarmTelemetryEvent] = []

    var events: [AlarmTelemetryEvent] {
        lock.lock(); defer { lock.unlock() }
        return _events
    }

    func record(_ event: AlarmTelemetryEvent) {
        lock.lock(); defer { lock.unlock() }
        _events.append(event)
    }
}

/// A builder that can be made to fail, so the migration's failure path is
/// reachable.
@available(iOS 26.0, *)
struct StubConfigurationBuilder: AlarmConfigurationBuilderProtocol {
    var returnNil = false
    private let real = AlarmConfigurationBuilder()

    func buildConfiguration(
        from alarmItem: Ticker,
        occurrenceAlarmID: UUID
    ) -> AlarmManager.AlarmConfiguration<TickerData>? {
        if returnNil { return nil }
        return real.buildConfiguration(from: alarmItem, occurrenceAlarmID: occurrenceAlarmID)
    }
}

// MARK: - Tests

@available(iOS 26.0, *)
final class AlarmTelemetryAndMigrationTests: XCTestCase {

    /// Every key these modules persist into the shared App Group suite. They are
    /// process-global, so a test that does not clear them leaks into the next.
    private static let persistedKeys = [
        "scheduledAlarmOccurrences",
        "pendingAlarmReactions",
        "alarmFireDetectorLastCheck",
        "alarmScheduleMigrationVersion"
    ]

    private var defaults: UserDefaults {
        UserDefaults(suiteName: TickerSchema.appGroupIdentifier)!
    }

    override func setUp() {
        super.setUp()
        clearPersistedState()
    }

    override func tearDown() {
        clearPersistedState()
        AlarmTelemetry.install(NullSink())
        super.tearDown()
    }

    private func clearPersistedState() {
        for key in Self.persistedKeys { defaults.removeObject(forKey: key) }
    }

    private struct NullSink: AlarmTelemetrySink {
        func record(_ event: AlarmTelemetryEvent) {}
    }

    // MARK: - AlarmOccurrenceLog

    func test_occurrenceLog_roundTripsAnOccurrence() throws {
        let id = UUID()
        let fireDate = Date(timeIntervalSince1970: 1_700_000_000)

        AlarmOccurrenceLog.record(alarmID: id, fireDate: fireDate)

        let stored = AlarmOccurrenceLog.all()
        let match = try XCTUnwrap(
            stored.first { $0.alarmID == id },
            "A recorded occurrence should be readable back"
        )
        XCTAssertEqual(
            match.fireDate.timeIntervalSince1970,
            fireDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func test_occurrenceLog_removeDeletesOnlyTheNamedIDs() {
        let keep = UUID()
        let drop = UUID()
        AlarmOccurrenceLog.record(alarmID: keep, fireDate: Date())
        AlarmOccurrenceLog.record(alarmID: drop, fireDate: Date())

        AlarmOccurrenceLog.remove(alarmIDs: [drop])

        let ids = Set(AlarmOccurrenceLog.all().map(\.alarmID))
        XCTAssertTrue(ids.contains(keep), "remove() must not touch unnamed IDs")
        XCTAssertFalse(ids.contains(drop))
    }

    func test_occurrenceLog_removeWithEmptyListIsANoOp() {
        let id = UUID()
        AlarmOccurrenceLog.record(alarmID: id, fireDate: Date())

        AlarmOccurrenceLog.remove(alarmIDs: [])

        XCTAssertTrue(
            AlarmOccurrenceLog.all().contains { $0.alarmID == id },
            "An empty removal list must not clear the log"
        )
    }

    func test_occurrenceLog_isBoundedAtFiveHundredEntries() {
        // 505 in: the 500 newest survive, the 5 oldest are pruned.
        let base = Date(timeIntervalSince1970: 1_000_000)
        var oldest: [UUID] = []
        for i in 0..<505 {
            let id = UUID()
            if i < 5 { oldest.append(id) }
            AlarmOccurrenceLog.record(alarmID: id, fireDate: base.addingTimeInterval(Double(i)))
        }

        let stored = AlarmOccurrenceLog.all()
        XCTAssertLessThanOrEqual(stored.count, 500, "The log must stay bounded")

        let survivingIDs = Set(stored.map(\.alarmID))
        for id in oldest {
            XCTAssertFalse(survivingIDs.contains(id), "The oldest entries should be pruned first")
        }
    }

    func test_occurrenceLog_ignoresMalformedKeys() {
        let valid = UUID()
        AlarmOccurrenceLog.record(alarmID: valid, fireDate: Date())

        // Simulate a corrupted defaults payload.
        var raw = defaults.dictionary(forKey: "scheduledAlarmOccurrences") as? [String: Double] ?? [:]
        raw["not-a-uuid"] = 123
        defaults.set(raw, forKey: "scheduledAlarmOccurrences")

        let stored = AlarmOccurrenceLog.all()
        XCTAssertEqual(
            stored.filter { $0.alarmID == valid }.count, 1,
            "A malformed key must not discard the valid entries alongside it"
        )
        XCTAssertEqual(stored.count, raw.count - 1, "The malformed key itself is skipped")
    }

    // MARK: - AlarmTelemetry facade

    func test_telemetry_forwardsEventsToTheInstalledSink() {
        let sink = RecordingTelemetrySink()
        AlarmTelemetry.install(sink)

        AlarmTelemetry.record(.scheduledAlarmCount(count: 7))

        XCTAssertEqual(sink.events.count, 1)
        if case .scheduledAlarmCount(let count) = sink.events[0] {
            XCTAssertEqual(count, 7)
        } else {
            XCTFail("Expected scheduledAlarmCount, got \(sink.events[0])")
        }
    }

    func test_telemetry_installingASecondSinkReplacesTheFirst() {
        let first = RecordingTelemetrySink()
        let second = RecordingTelemetrySink()
        AlarmTelemetry.install(first)
        AlarmTelemetry.install(second)

        AlarmTelemetry.record(.alarmBudgetExhausted(scheduled: 64, limit: 64))

        XCTAssertTrue(first.events.isEmpty, "The replaced sink should stop receiving events")
        XCTAssertEqual(second.events.count, 1)
    }

    // MARK: - AlarmReactionRecorder

    func test_reactionRecorder_persistsForTheNextLaunchAndDrainsOnce() {
        let id = UUID()
        AlarmReactionRecorder.record(.stopped, alarmID: id)

        let drained = AlarmReactionRecorder.drainPending()
        XCTAssertEqual(drained.count, 1)
        XCTAssertEqual(drained.first?.kind, .stopped)
        XCTAssertEqual(drained.first?.alarmID, id)

        XCTAssertTrue(
            AlarmReactionRecorder.drainPending().isEmpty,
            "A drain must consume the queue, or the same reaction is counted every launch"
        )
    }

    func test_reactionRecorder_reachesASinkInTheSameProcess() {
        let sink = RecordingTelemetrySink()
        AlarmTelemetry.install(sink)
        let id = UUID()

        AlarmReactionRecorder.record(.snoozed, alarmID: id)

        XCTAssertEqual(sink.events.count, 1, "An installed sink should see the reaction immediately")
        if case .alarmReaction(let kind, let alarmID) = sink.events[0] {
            XCTAssertEqual(kind, .snoozed)
            XCTAssertEqual(alarmID, id)
        } else {
            XCTFail("Expected alarmReaction, got \(sink.events[0])")
        }
    }

    func test_reactionRecorder_isBoundedAtFiftyAndKeepsTheNewest() {
        for _ in 0..<60 { AlarmReactionRecorder.record(.stopped, alarmID: UUID()) }
        let newest = UUID()
        AlarmReactionRecorder.record(.openedApp, alarmID: newest)

        let drained = AlarmReactionRecorder.drainPending()
        XCTAssertLessThanOrEqual(drained.count, 50, "The pending queue must stay bounded")
        XCTAssertTrue(
            drained.contains { $0.alarmID == newest },
            "Bounding must drop the oldest reactions, not the most recent one"
        )
    }

    func test_reactionRecorder_skipsMalformedEntriesWithoutLosingGoodOnes() {
        let valid = UUID()
        AlarmReactionRecorder.record(.paused, alarmID: valid)

        var pending = defaults.array(forKey: "pendingAlarmReactions") as? [[String: Any]] ?? []
        pending.append(["kind": "not-a-real-kind", "alarmID": UUID().uuidString, "at": 1.0])
        pending.append(["alarmID": UUID().uuidString])
        defaults.set(pending, forKey: "pendingAlarmReactions")

        let drained = AlarmReactionRecorder.drainPending()
        XCTAssertEqual(drained.count, 1, "Only the well-formed reaction should survive")
        XCTAssertEqual(drained.first?.alarmID, valid)
    }

    // MARK: - AlarmFireDetector

    @MainActor
    func test_detect_infersAFireForAPastOccurrenceThatIsNoLongerArmed() throws {
        let sink = RecordingTelemetrySink()
        AlarmTelemetry.install(sink)

        let firedID = UUID()
        AlarmOccurrenceLog.record(alarmID: firedID, fireDate: Date().addingTimeInterval(-3600))

        let scheduler = FakeAlarmScheduler()   // nothing armed
        let result = AlarmFireDetector.detect(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            context: try TestModelContextFactory.createInMemoryContext()
        )

        XCTAssertEqual(result.inferredFires, 1, "A past, unarmed occurrence must have fired")
        XCTAssertTrue(
            sink.events.contains { if case .alarmFiredInferred = $0 { return true } else { return false } },
            "The inferred fire must be reported, or the fire rate has no numerator"
        )
        XCTAssertFalse(
            AlarmOccurrenceLog.all().contains { $0.alarmID == firedID },
            "A resolved occurrence must leave the log, or it is counted again next launch"
        )
    }

    @MainActor
    func test_detect_doesNotInferAFireForAnOccurrenceStillArmed() throws {
        let stillArmedID = UUID()
        AlarmOccurrenceLog.record(alarmID: stillArmedID, fireDate: Date().addingTimeInterval(-3600))

        let scheduler = FakeAlarmScheduler()
        scheduler.armed[stillArmedID] = try TestAlarmFactory.makeFixedAlarm(
            id: stillArmedID, at: Date().addingTimeInterval(-3600)
        )

        let result = AlarmFireDetector.detect(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            context: try TestModelContextFactory.createInMemoryContext()
        )

        XCTAssertEqual(result.inferredFires, 0, "An alarm still armed in AlarmKit has not fired")
        XCTAssertTrue(
            AlarmOccurrenceLog.all().contains { $0.alarmID == stillArmedID },
            "An unresolved occurrence must stay in the log"
        )
    }

    @MainActor
    func test_detect_ignoresOccurrencesWhoseFireDateIsStillInTheFuture() throws {
        let futureID = UUID()
        AlarmOccurrenceLog.record(alarmID: futureID, fireDate: Date().addingTimeInterval(3600))

        let result = AlarmFireDetector.detect(
            alarmManager: FakeAlarmScheduler(),
            stateManager: LiveFakeStateManager(),
            context: try TestModelContextFactory.createInMemoryContext()
        )

        XCTAssertEqual(result.inferredFires, 0, "A future occurrence cannot have fired yet")
        XCTAssertTrue(
            AlarmOccurrenceLog.all().contains { $0.alarmID == futureID },
            "A future occurrence must be left alone for a later sweep"
        )
    }

    @MainActor
    func test_detect_drainsPendingReactionsAndReportsThem() throws {
        let sink = RecordingTelemetrySink()
        AlarmTelemetry.install(sink)

        AlarmReactionRecorder.record(.stopped, alarmID: UUID())
        AlarmReactionRecorder.record(.snoozed, alarmID: UUID())
        // Reactions recorded before the sweep are the extension-process case.
        let sinkCountBefore = sink.events.count

        let result = AlarmFireDetector.detect(
            alarmManager: FakeAlarmScheduler(),
            stateManager: LiveFakeStateManager(),
            context: try TestModelContextFactory.createInMemoryContext()
        )

        XCTAssertEqual(result.reactions, 2)
        XCTAssertGreaterThan(sink.events.count, sinkCountBefore)
        XCTAssertTrue(
            AlarmReactionRecorder.drainPending().isEmpty,
            "detect() must consume the pending queue"
        )
    }

    @MainActor
    func test_detect_reportsTheArmedCountAndSurvivesAQueryFailure() throws {
        let sink = RecordingTelemetrySink()
        AlarmTelemetry.install(sink)

        let stateManager = LiveFakeStateManager()
        stateManager.failQuery = true

        let result = AlarmFireDetector.detect(
            alarmManager: FakeAlarmScheduler(),
            stateManager: stateManager,
            context: try TestModelContextFactory.createInMemoryContext()
        )

        XCTAssertEqual(result.scheduledCount, 0, "A failed query degrades to zero armed, not a crash")
        XCTAssertTrue(
            sink.events.contains { if case .scheduledAlarmCount = $0 { return true } else { return false } },
            "The armed-count sample should still be reported"
        )
    }

    @MainActor
    func test_detect_firstRunReportsNoExpectedFires() throws {
        // With no stored last-check, the window is zero-width, so the
        // denominator is 0 rather than an invented backfill.
        let ticker = Ticker(
            label: "Daily",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 7, minute: 0))
        )
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let result = AlarmFireDetector.detect(
            alarmManager: FakeAlarmScheduler(),
            stateManager: LiveFakeStateManager(),
            context: context
        )

        XCTAssertEqual(result.expected, 0, "The first sweep has no baseline to measure against")
        XCTAssertNotNil(
            defaults.object(forKey: "alarmFireDetectorLastCheck"),
            "The sweep must stamp a baseline so the next run has a window"
        )
    }

    @MainActor
    func test_detect_countsExpectedFiresOverTheWindowSinceTheLastCheck() throws {
        // Seed a last-check two days back so the window is real.
        defaults.set(Date().addingTimeInterval(-2 * 24 * 3600), forKey: "alarmFireDetectorLastCheck")

        let enabled = Ticker(
            label: "Daily enabled",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 7, minute: 0))
        )
        let disabled = Ticker(
            label: "Daily disabled",
            isEnabled: false,
            schedule: .daily(time: .init(hour: 8, minute: 0))
        )
        let context = try TestModelContextFactory.createContextWithTickers([enabled, disabled])

        let result = AlarmFireDetector.detect(
            alarmManager: FakeAlarmScheduler(),
            stateManager: LiveFakeStateManager(),
            context: context
        )

        XCTAssertGreaterThan(
            result.expected, 0,
            "A daily alarm over a two-day window should have expected occurrences"
        )
        // A disabled ticker contributes nothing, so the count cannot reach the
        // two-ticker total.
        XCTAssertLessThanOrEqual(
            result.expected, 3,
            "Only the enabled ticker should contribute to the denominator"
        )
    }

    // MARK: - AlarmScheduleMigration

    /// Builds a ticker in the exact pre-migration shape: a natively-expressible
    /// weekday schedule still backed by expansion-generated one-time alarms.
    private func makeLegacyWeekdayTicker(
        legacyIDs: [UUID]
    ) -> Ticker {
        let ticker = Ticker(
            label: "Weekday wake-up",
            isEnabled: true,
            schedule: .weekdays(
                time: .init(hour: 7, minute: 0),
                days: [.monday, .tuesday, .wednesday, .thursday, .friday]
            )
        )
        ticker.generatedAlarmKitIDs = legacyIDs
        return ticker
    }

    @MainActor
    private func armFixed(_ scheduler: FakeAlarmScheduler, ids: [UUID]) throws {
        for id in ids {
            scheduler.armed[id] = try TestAlarmFactory.makeFixedAlarm(
                id: id, at: Date().addingTimeInterval(3600)
            )
        }
    }

    @MainActor
    func test_migration_replacesExpandedAlarmsWithASingleNativeRecurrence() async throws {
        let legacy = [UUID(), UUID(), UUID()]
        let ticker = makeLegacyWeekdayTicker(legacyIDs: legacy)
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let scheduler = FakeAlarmScheduler()
        try armFixed(scheduler, ids: legacy)

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            configurationBuilder: StubConfigurationBuilder(),
            context: context
        )

        XCTAssertEqual(
            Set(scheduler.cancelledIDs), Set(legacy),
            "Every expansion-generated alarm must be cancelled"
        )
        XCTAssertEqual(
            ticker.generatedAlarmKitIDs.count, 1,
            "A migrated ticker holds exactly one native recurring alarm"
        )
        let newID = try XCTUnwrap(ticker.generatedAlarmKitIDs.first)
        XCTAssertFalse(legacy.contains(newID), "The replacement must be a fresh occurrence ID")
        XCTAssertTrue(scheduler.scheduledIDs.contains(newID))
        XCTAssertEqual(ticker.lastRegenerationSuccess, true)
    }

    @MainActor
    func test_migration_skipsTheTickerWhenACancelSilentlyFails() async throws {
        // The double-alert guard. A cancel that fails while the migration arms a
        // new recurrence leaves the user with two alerts the same morning, so the
        // migration must verify and back out instead.
        let legacy = [UUID()]
        let ticker = makeLegacyWeekdayTicker(legacyIDs: legacy)
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let scheduler = FakeAlarmScheduler()
        try armFixed(scheduler, ids: legacy)
        scheduler.cancelError = NSError(domain: "TestError", code: 42)

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            configurationBuilder: StubConfigurationBuilder(),
            context: context
        )

        XCTAssertTrue(
            scheduler.scheduledIDs.isEmpty,
            "Nothing may be armed while a stale alarm is still live — that is the double alert"
        )
        XCTAssertEqual(
            ticker.generatedAlarmKitIDs, legacy,
            "The ticker keeps its working alarms when the migration backs out"
        )
    }

    @MainActor
    func test_migration_defersWhenAlarmKitCannotBeReRead() async throws {
        let legacy = [UUID()]
        let ticker = makeLegacyWeekdayTicker(legacyIDs: legacy)
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let scheduler = FakeAlarmScheduler()
        try armFixed(scheduler, ids: legacy)

        // First read succeeds, the post-cancel verification read fails.
        let stateManager = LiveFakeStateManager()
        stateManager.failQueryOnCall = 2

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: stateManager,
            configurationBuilder: StubConfigurationBuilder(),
            context: context
        )

        XCTAssertTrue(
            scheduler.scheduledIDs.isEmpty,
            "Unverifiable cancellation must not be followed by a new alarm"
        )
    }

    @MainActor
    func test_migration_recordsTelemetryAndClearsIDsWhenSchedulingFails() async throws {
        let sink = RecordingTelemetrySink()
        AlarmTelemetry.install(sink)

        let legacy = [UUID()]
        let ticker = makeLegacyWeekdayTicker(legacyIDs: legacy)
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let scheduler = FakeAlarmScheduler()
        try armFixed(scheduler, ids: legacy)
        // Cancel works; the replacement schedule is refused (e.g. budget hit).
        scheduler.scheduleError = AlarmManager.AlarmError.maximumLimitReached

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            configurationBuilder: StubConfigurationBuilder(),
            context: context
        )

        XCTAssertTrue(
            ticker.generatedAlarmKitIDs.isEmpty,
            "A failed migration must not claim alarms that were cancelled"
        )
        XCTAssertEqual(
            ticker.lastRegenerationSuccess, false,
            "The regeneration path needs to see this ticker as failed so it retries"
        )
        XCTAssertTrue(
            sink.events.contains {
                if case .alarmScheduleFailed(let reason) = $0 { return reason == "weekday_migration_failed" }
                return false
            },
            "A silent migration failure is the failure mode this whole change exists to end"
        )
    }

    @MainActor
    func test_migration_runsOnlyOnce() async throws {
        let legacy = [UUID()]
        let ticker = makeLegacyWeekdayTicker(legacyIDs: legacy)
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let scheduler = FakeAlarmScheduler()
        try armFixed(scheduler, ids: legacy)

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            configurationBuilder: StubConfigurationBuilder(),
            context: context
        )
        let scheduledAfterFirst = scheduler.scheduledIDs.count

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            configurationBuilder: StubConfigurationBuilder(),
            context: context
        )

        XCTAssertEqual(
            scheduler.scheduledIDs.count, scheduledAfterFirst,
            "The version gate must stop a second pass from re-arming everything"
        )
    }

    @MainActor
    func test_migration_leavesDisabledAndAlreadyNativeTickersAlone() async throws {
        // Disabled: out of scope entirely.
        let disabled = makeLegacyWeekdayTicker(legacyIDs: [UUID()])
        disabled.isEnabled = false

        // Enabled weekday ticker with no armed `.fixed` alarms is already native.
        let alreadyNative = makeLegacyWeekdayTicker(legacyIDs: [])

        let context = try TestModelContextFactory.createContextWithTickers([disabled, alreadyNative])
        let scheduler = FakeAlarmScheduler()

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            configurationBuilder: StubConfigurationBuilder(),
            context: context
        )

        XCTAssertTrue(scheduler.cancelledIDs.isEmpty, "Nothing here needed cancelling")
        XCTAssertTrue(scheduler.scheduledIDs.isEmpty, "Nothing here needed arming")
    }

    @MainActor
    func test_migration_skipsExpansionOnlySchedulesThatHaveNoNativeForm() async throws {
        // `.hourly` is genuinely inexpressible in AlarmKit, so it must stay on
        // the expansion path rather than being collapsed to one alarm.
        let hourly = Ticker(
            label: "Hourly",
            isEnabled: true,
            schedule: .hourly(interval: 2, time: .init(hour: 0, minute: 0))
        )
        let legacy = [UUID(), UUID()]
        hourly.generatedAlarmKitIDs = legacy

        let context = try TestModelContextFactory.createContextWithTickers([hourly])
        let scheduler = FakeAlarmScheduler()
        try armFixed(scheduler, ids: legacy)

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            configurationBuilder: StubConfigurationBuilder(),
            context: context
        )

        XCTAssertTrue(scheduler.cancelledIDs.isEmpty, "An expansion-only schedule must be left alone")
        XCTAssertEqual(hourly.generatedAlarmKitIDs, legacy)
    }

    @MainActor
    func test_migration_clearsIDsWhenNoNativeConfigurationCanBeBuilt() async throws {
        let legacy = [UUID()]
        let ticker = makeLegacyWeekdayTicker(legacyIDs: legacy)
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let scheduler = FakeAlarmScheduler()
        try armFixed(scheduler, ids: legacy)

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            configurationBuilder: StubConfigurationBuilder(returnNil: true),
            context: context
        )

        XCTAssertTrue(
            ticker.generatedAlarmKitIDs.isEmpty,
            "Cancelled alarms must not be left recorded against the ticker"
        )
        XCTAssertTrue(scheduler.scheduledIDs.isEmpty)
    }

    /// Documents a real edge in the current implementation rather than asserting
    /// it is desirable: a `.oneTime` ticker also reports
    /// `usesNativeAlarmKitSchedule == true` and its correct single alarm is
    /// `.fixed`, so the migration cannot tell it apart from an expansion
    /// leftover and cycles it. Harmless when the reschedule succeeds; if it
    /// throws, the alarm is cancelled and cleared. Flagged in review.
    @MainActor
    func test_migration_alsoCyclesOneTimeTickers_documentedEdge() async throws {
        let legacy = [UUID()]
        let oneTime = Ticker(
            label: "One-time",
            isEnabled: true,
            schedule: .oneTime(date: Date().addingTimeInterval(7200))
        )
        oneTime.generatedAlarmKitIDs = legacy

        let context = try TestModelContextFactory.createContextWithTickers([oneTime])
        let scheduler = FakeAlarmScheduler()
        try armFixed(scheduler, ids: legacy)

        await AlarmScheduleMigration.runIfNeeded(
            alarmManager: scheduler,
            stateManager: LiveFakeStateManager(),
            configurationBuilder: StubConfigurationBuilder(),
            context: context
        )

        XCTAssertEqual(
            scheduler.cancelledIDs, legacy,
            "Current behaviour: a one-time ticker is cancelled and re-armed too"
        )
        XCTAssertEqual(
            oneTime.generatedAlarmKitIDs.count, 1,
            "It ends up correctly armed again, so the fire is preserved on the happy path"
        )
    }
}
