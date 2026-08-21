//
//  AlarmRegenerationRollbackTests.swift
//  TickerCoreTests
//
//  The second F5 site.
//
//  `executeAtomicTransaction` used to cancel the stale alarms first and, on
//  failure, undo only the alarms it had newly created. A mid-transaction throw —
//  `AlarmError.maximumLimitReached` being the realistic one — therefore left the
//  ticker with zero armed alarms and no route back. The fix inverts the order:
//  add everything, and only then retire what is stale.
//
//  This suite pins that ordering, plus the budget pre-flight that stops AlarmKit
//  from throwing part-way through in the first place.
//

import Foundation
import XCTest
import SwiftData
import AlarmKit
import Factory
@testable import TickerCore

@available(iOS 26.0, *)
final class AlarmRegenerationRollbackTests: XCTestCase {

    private var scheduler: FakeAlarmScheduler!
    private var stateManager: LiveFakeStateManager!
    private let occurrenceKey = "scheduledAlarmOccurrences"

    override func setUp() {
        super.setUp()
        scheduler = FakeAlarmScheduler()
        stateManager = LiveFakeStateManager()
        Container.shared.alarmManager.register { [unowned self] in self.scheduler }
        Container.shared.alarmStateManager.register { [unowned self] in self.stateManager }
        UserDefaults(suiteName: TickerSchema.appGroupIdentifier)?.removeObject(forKey: occurrenceKey)
    }

    override func tearDown() {
        Container.shared.alarmManager.reset()
        Container.shared.alarmStateManager.reset()
        UserDefaults(suiteName: TickerSchema.appGroupIdentifier)?.removeObject(forKey: occurrenceKey)
        scheduler = nil
        stateManager = nil
        super.tearDown()
    }

    /// A ticker on the expansion path (`.hourly` has no native AlarmKit form)
    /// already holding armed one-time alarms.
    @MainActor
    private func makeExpansionTicker(existing: [UUID]) throws -> Ticker {
        let ticker = Ticker(
            label: "Hourly reminder",
            isEnabled: true,
            schedule: .hourly(interval: 1, time: .init(hour: 0, minute: 0))
        )
        ticker.generatedAlarmKitIDs = existing
        // Arm them in the past-free future so they read as live occurrences.
        for (offset, id) in existing.enumerated() {
            scheduler.armed[id] = try TestAlarmFactory.makeFixedAlarm(
                id: id,
                at: Date().addingTimeInterval(Double(600 + offset * 60))
            )
        }
        return ticker
    }

    // MARK: - Add before delete

    @MainActor
    func test_regeneration_keepsExistingAlarmsArmed_whenSchedulingTheReplacementsFails() async throws {
        let existing = [UUID(), UUID()]
        let ticker = try makeExpansionTicker(existing: existing)
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        // Every new schedule attempt is refused.
        scheduler.scheduleError = AlarmManager.AlarmError.maximumLimitReached

        let service = AlarmRegenerationService()
        _ = try? await service.regenerateAlarmsIfNeeded(ticker: ticker, context: context, force: true)

        for id in existing {
            XCTAssertNotNil(
                scheduler.armed[id],
                "A failed regeneration must leave the user's existing alarms armed — cancelling first is what silently emptied the ticker"
            )
            XCTAssertFalse(
                scheduler.cancelledIDs.contains(id),
                "Nothing may be cancelled before the replacements are committed"
            )
        }
    }

    @MainActor
    func test_regeneration_retiresStaleAlarmsOnlyAfterEveryAddSucceeds() async throws {
        let existing = [UUID()]
        let ticker = try makeExpansionTicker(existing: existing)
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let service = AlarmRegenerationService()
        try await service.regenerateAlarmsIfNeeded(ticker: ticker, context: context, force: true)

        XCTAssertFalse(
            scheduler.scheduledIDs.isEmpty,
            "A forced regeneration on an expansion schedule should arm new occurrences"
        )
        // Whatever the diff decided to retire, it must not still be armed.
        for id in scheduler.cancelledIDs {
            XCTAssertNil(scheduler.armed[id], "A retired alarm should be gone from AlarmKit")
        }
        XCTAssertFalse(
            ticker.generatedAlarmKitIDs.isEmpty,
            "The ticker must end up owning the alarms that are actually armed"
        )
    }

    @MainActor
    func test_regeneration_doesNotRollBackCommittedAddsWhenACancelFails() async throws {
        let existing = [UUID(), UUID()]
        let ticker = try makeExpansionTicker(existing: existing)
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        // Adds succeed; retiring the stale alarms is refused.
        scheduler.cancelError = NSError(domain: "AlarmKit", code: 7)

        let service = AlarmRegenerationService()
        _ = try? await service.regenerateAlarmsIfNeeded(ticker: ticker, context: context, force: true)

        XCTAssertFalse(
            scheduler.scheduledIDs.isEmpty,
            "Newly armed alarms must survive a failed cancel — the next sync reconciles the leftovers"
        )
        for id in scheduler.scheduledIDs {
            XCTAssertNotNil(
                scheduler.armed[id],
                "A cancel failure must not undo work that already succeeded"
            )
        }
    }

    // MARK: - Budget pre-flight

    @MainActor
    func test_regeneration_trimsToTheBudgetAndReportsIt_ratherThanLettingAlarmKitThrow() async throws {
        let sink = RecordingTelemetrySink()
        AlarmTelemetry.install(sink)
        defer { AlarmTelemetry.install(SilentSink()) }

        let ticker = try makeExpansionTicker(existing: [])
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        // Fill the global budget so the allowance is near zero.
        for _ in 0..<AlarmBudget.maxScheduledAlarms {
            let id = UUID()
            scheduler.armed[id] = try TestAlarmFactory.makeFixedAlarm(
                id: id, at: Date().addingTimeInterval(3600)
            )
        }

        let service = AlarmRegenerationService()
        _ = try? await service.regenerateAlarmsIfNeeded(ticker: ticker, context: context, force: true)

        XCTAssertTrue(
            scheduler.scheduledIDs.isEmpty,
            "With the budget already full, nothing new may be armed"
        )
        XCTAssertTrue(
            sink.events.contains {
                if case .alarmBudgetExhausted = $0 { return true } else { return false }
            },
            "Budget exhaustion must be reported — it is the best explanation for 'it worked, then stopped'"
        )
    }

    @MainActor
    func test_regeneration_neverArmsMoreThanThePerTickerCap() async throws {
        let ticker = try makeExpansionTicker(existing: [])
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let service = AlarmRegenerationService()
        try await service.regenerateAlarmsIfNeeded(ticker: ticker, context: context, force: true)

        XCTAssertLessThanOrEqual(
            ticker.generatedAlarmKitIDs.count,
            AlarmBudget.maxAlarmsPerTicker,
            "One hourly ticker must not be able to starve every other alarm in the app"
        )
    }

    @MainActor
    func test_regeneration_logsEveryArmedOccurrenceForFireInference() async throws {
        let ticker = try makeExpansionTicker(existing: [])
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let service = AlarmRegenerationService()
        try await service.regenerateAlarmsIfNeeded(ticker: ticker, context: context, force: true)

        let logged = Set(AlarmOccurrenceLog.all().map(\.alarmID))
        for id in scheduler.scheduledIDs {
            XCTAssertTrue(
                logged.contains(id),
                "An expansion-generated alarm that is not logged can never be counted as a fire"
            )
        }
    }

    // MARK: - Gating

    @MainActor
    func test_regeneration_isASkipForANativelyExpressibleSchedule() async throws {
        // `.weekdays` now maps to a native recurrence, so it must not be pulled
        // back onto the expansion path.
        let ticker = Ticker(
            label: "Weekdays",
            isEnabled: true,
            schedule: .weekdays(
                time: .init(hour: 7, minute: 0),
                days: [.monday, .tuesday, .wednesday, .thursday, .friday]
            )
        )
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let service = AlarmRegenerationService()
        XCTAssertFalse(
            service.shouldRegenerate(ticker: ticker),
            "A native recurrence never needs expansion, so it must not be regenerated"
        )
    }

    private struct SilentSink: AlarmTelemetrySink {
        func record(_ event: AlarmTelemetryEvent) {}
    }
}
