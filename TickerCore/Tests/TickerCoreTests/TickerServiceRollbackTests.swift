//
//  TickerServiceRollbackTests.swift
//  TickerCoreTests
//
//  The F5 data-loss path.
//
//  `scheduleAlarm` used to respond to a scheduling failure by fetching the
//  ticker by ID and deleting it. Because `parentTickerCollection` is a
//  `.cascade` inverse, one failed reschedule could take a whole collection with
//  it. The fix narrows rollback to rows the call itself inserted, and this suite
//  is what stops it regressing — nothing else exercised TickerService at all
//  after the empty AlarmServiceTests file was removed.
//

import Foundation
import XCTest
import SwiftData
import AlarmKit
import Factory
@testable import TickerCore

@available(iOS 26.0, *)
final class TickerServiceRollbackTests: XCTestCase {

    private var scheduler: FakeAlarmScheduler!

    override func setUp() {
        super.setUp()
        scheduler = FakeAlarmScheduler()
        // Replace the AlarmKit seam for the duration of the test. This is the
        // whole point of vending `any AlarmScheduling` from the container.
        Container.shared.alarmManager.register { [unowned self] in self.scheduler }
    }

    override func tearDown() {
        Container.shared.alarmManager.reset()
        scheduler = nil
        super.tearDown()
    }

    private func makeTicker(label: String = "Wake up") -> Ticker {
        Ticker(
            label: label,
            isEnabled: true,
            schedule: .oneTime(date: Date().addingTimeInterval(3600))
        )
    }

    // MARK: - A failed schedule must not delete a pre-existing ticker

    @MainActor
    func test_scheduleAlarm_doesNotDeleteAPreExistingTicker_whenSchedulingFails() async throws {
        let ticker = makeTicker()
        let tickerID = ticker.id
        // Already stored: this is a user-authored row being rescheduled.
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        scheduler.scheduleError = AlarmManager.AlarmError.maximumLimitReached

        let service = TickerService()
        do {
            try await service.scheduleAlarm(from: ticker, context: context)
            XCTFail("Expected scheduleAlarm to throw when AlarmKit refuses")
        } catch {
            // Expected.
        }

        XCTAssertTickersExist(in: context, tickerIDs: [tickerID])
        let stored = try context.fetch(FetchDescriptor<Ticker>())
        XCTAssertEqual(
            stored.count, 1,
            "A failed reschedule must leave the user's alarm exactly where it was"
        )
    }

    @MainActor
    func test_scheduleAlarm_preservesTheTicker_whenSchedulingFailsRepeatedly() async throws {
        let ticker = makeTicker()
        let tickerID = ticker.id
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        scheduler.scheduleError = NSError(domain: "AlarmKit", code: 99)

        let service = TickerService()
        for _ in 0..<3 {
            _ = try? await service.scheduleAlarm(from: ticker, context: context)
        }

        XCTAssertTickersExist(
            in: context, tickerIDs: [tickerID]
        )
    }

    @MainActor
    func test_scheduleAlarm_doesNotStrandANewTickerInTheStore_whenSchedulingFails() async throws {
        // The other half of the rollback contract: a row this call never
        // committed must not be left behind either.
        let ticker = makeTicker(label: "Brand new")
        let tickerID = ticker.id
        let context = try TestModelContextFactory.createInMemoryContext()

        scheduler.scheduleError = AlarmManager.AlarmError.maximumLimitReached

        let service = TickerService()
        _ = try? await service.scheduleAlarm(from: ticker, context: context)

        XCTAssertTickersNotExist(in: context, tickerIDs: [tickerID])
    }

    // MARK: - The happy path still works

    @MainActor
    func test_scheduleAlarm_armsTheAlarmAndStoresTheTicker() async throws {
        let ticker = makeTicker()
        let context = try TestModelContextFactory.createInMemoryContext()

        let service = TickerService()
        try await service.scheduleAlarm(from: ticker, context: context)

        XCTAssertEqual(
            ticker.generatedAlarmKitIDs.count, 1,
            "A scheduled ticker records the occurrence ID it armed"
        )
        let armedID = try XCTUnwrap(ticker.generatedAlarmKitIDs.first)
        XCTAssertTrue(scheduler.scheduledIDs.contains(armedID))
        XCTAssertNotEqual(
            armedID, ticker.id,
            "The occurrence ID must be fresh, not the SwiftData Ticker ID (F9)"
        )
        XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
    }

    @MainActor
    func test_scheduleAlarm_logsAFixedOccurrenceSoItsFireCanBeInferred() async throws {
        let key = "scheduledAlarmOccurrences"
        let defaults = UserDefaults(suiteName: TickerSchema.appGroupIdentifier)
        defaults?.removeObject(forKey: key)
        defer { defaults?.removeObject(forKey: key) }

        let ticker = makeTicker()   // .oneTime maps to a `.fixed` AlarmKit schedule
        let context = try TestModelContextFactory.createInMemoryContext()

        let service = TickerService()
        try await service.scheduleAlarm(from: ticker, context: context)

        let armedID = try XCTUnwrap(ticker.generatedAlarmKitIDs.first)
        XCTAssertTrue(
            AlarmOccurrenceLog.all().contains { $0.alarmID == armedID },
            "A one-shot alarm must be logged, or its fire can never be inferred"
        )
    }

    @MainActor
    func test_scheduleAlarm_doesNotLogAnOccurrenceForARecurringAlarm() async throws {
        let key = "scheduledAlarmOccurrences"
        let defaults = UserDefaults(suiteName: TickerSchema.appGroupIdentifier)
        defaults?.removeObject(forKey: key)
        defer { defaults?.removeObject(forKey: key) }

        // `.weekdays` maps to a native `.relative` recurrence, which stays armed
        // in AlarmKit, so there is nothing to infer from its absence.
        let ticker = Ticker(
            label: "Weekdays",
            isEnabled: true,
            schedule: .weekdays(
                time: .init(hour: 7, minute: 0),
                days: [.monday, .tuesday, .wednesday, .thursday, .friday]
            )
        )
        let context = try TestModelContextFactory.createInMemoryContext()

        let service = TickerService()
        try await service.scheduleAlarm(from: ticker, context: context)

        let armedID = try XCTUnwrap(ticker.generatedAlarmKitIDs.first)
        XCTAssertFalse(
            AlarmOccurrenceLog.all().contains { $0.alarmID == armedID },
            "A recurring alarm never leaves AlarmKit, so logging it would infer a phantom fire"
        )
    }

    // MARK: - Occurrence-log lifecycle (adversarial review)

    /// A cancelled alarm that stays in the occurrence log is later read as
    /// "past and no longer armed" — the exact signature of a fire. Deleting an
    /// alarm would therefore be reported as that alarm having rung, inflating
    /// the one metric this release exists to produce.
    @MainActor
    func test_cancelAlarm_removesTheOccurrenceFromTheLog() async throws {
        let key = "scheduledAlarmOccurrences"
        let defaults = UserDefaults(suiteName: TickerSchema.appGroupIdentifier)
        defaults?.removeObject(forKey: key)
        defer { defaults?.removeObject(forKey: key) }

        let ticker = makeTicker()
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let service = TickerService()
        try await service.scheduleAlarm(from: ticker, context: context)
        let armedID = try XCTUnwrap(ticker.generatedAlarmKitIDs.first)
        XCTAssertTrue(AlarmOccurrenceLog.all().contains { $0.alarmID == armedID })

        try await service.cancelAlarm(id: ticker.id, context: context)

        XCTAssertFalse(
            AlarmOccurrenceLog.all().contains { $0.alarmID == armedID },
            "A cancelled alarm must leave the log, or its passing date is counted as a fire"
        )
    }

    /// Editing an alarm cancels and re-arms it under a fresh occurrence ID. The
    /// old entry has to go and the new one has to be written, or the edited
    /// alarm both reports a phantom fire (old ID) and fails to report its real
    /// one (new ID missing from the log).
    @MainActor
    func test_updateAlarm_swapsTheOccurrenceLogEntryForTheNewID() async throws {
        let key = "scheduledAlarmOccurrences"
        let defaults = UserDefaults(suiteName: TickerSchema.appGroupIdentifier)
        defaults?.removeObject(forKey: key)
        defer { defaults?.removeObject(forKey: key) }

        let ticker = makeTicker()
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let service = TickerService()
        try await service.scheduleAlarm(from: ticker, context: context)
        let originalID = try XCTUnwrap(ticker.generatedAlarmKitIDs.first)

        // Edit it: same ticker, a different one-shot time.
        ticker.schedule = .oneTime(date: Date().addingTimeInterval(7200))
        try await service.updateAlarm(ticker, context: context)

        let newID = try XCTUnwrap(ticker.generatedAlarmKitIDs.first)
        XCTAssertNotEqual(newID, originalID, "An edit re-arms under a fresh occurrence ID")

        let logged = Set(AlarmOccurrenceLog.all().map(\.alarmID))
        XCTAssertFalse(
            logged.contains(originalID),
            "The superseded occurrence must not linger and be counted as a fire"
        )
        XCTAssertTrue(
            logged.contains(newID),
            "The replacement occurrence must be logged, or its real fire is never counted"
        )
    }

    // MARK: - Cancellation

    @MainActor
    func test_cancelAlarm_cancelsEveryOccurrenceTheTickerOwns() async throws {
        let ticker = makeTicker()
        let context = try TestModelContextFactory.createContextWithTickers([ticker])

        let service = TickerService()
        try await service.scheduleAlarm(from: ticker, context: context)
        let armed = ticker.generatedAlarmKitIDs
        XCTAssertFalse(armed.isEmpty)

        try await service.cancelAlarm(id: ticker.id, context: context)

        for id in armed {
            XCTAssertTrue(
                scheduler.cancelledIDs.contains(id),
                "Cancelling a ticker must release every occurrence it armed"
            )
        }
    }
}
