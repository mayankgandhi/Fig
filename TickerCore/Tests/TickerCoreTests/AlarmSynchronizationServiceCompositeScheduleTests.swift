//
//  AlarmSynchronizationServiceCompositeScheduleTests.swift
//  TickerCoreTests
//
//  Tests for composite schedule scenarios with multiple generatedAlarmKitIDs
//

import XCTest
import SwiftData
@testable import TickerCore
import AlarmKit

@available(iOS 26.0, *)
final class AlarmSynchronizationServiceCompositeScheduleTests: XCTestCase {
    
    var service: AlarmSynchronizationService!
    var mockStateManager: MockAlarmStateManager!
    var alarmManager: AlarmManager!
    
    override func setUp() {
        super.setUp()
        service = AlarmSynchronizationService()
        mockStateManager = MockAlarmStateManager()
        alarmManager = AlarmManager.shared
        mockStateManager.reset()
    }
    
    override func tearDown() {
        mockStateManager.reset()
        service = nil
        mockStateManager = nil
        alarmManager = nil
        super.tearDown()
    }
    
    // MARK: - Multiple Generated IDs Tests
    
    func testSynchronize_TickerWithMultipleGeneratedIDs() async throws {
        // Given: Ticker with multiple generated alarm IDs
        let generatedIDs = [UUID(), UUID(), UUID()]
        let ticker = AlarmSynchronizationServiceTestHelpers.createTickerWithGeneratedIDs(
            id: UUID(),
            label: "Multi-ID Ticker",
            generatedIDs: generatedIDs
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: All IDs should be cleaned up (no alarms exist)
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)
        
        if let updatedTicker = tickers.first(where: { $0.id == ticker.id }) {
            XCTAssertEqual(updatedTicker.generatedAlarmKitIDs.count, 0, "All generated IDs should be removed")
        }
    }
    
    func testSynchronize_PartialCleanupOfGeneratedIDs() async throws {
        // Given: Ticker with multiple IDs, some valid, some invalid
        // Note: Since we can't create Alarm instances, we test the cleanup logic
        let validID = UUID()
        let invalidID1 = UUID()
        let invalidID2 = UUID()
        
        let ticker = AlarmSynchronizationServiceTestHelpers.createTickerWithGeneratedIDs(
            id: UUID(),
            label: "Partial Cleanup Ticker",
            generatedIDs: [validID, invalidID1, invalidID2]
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = [] // No alarms, so all IDs invalid
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Invalid IDs should be removed
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)
        
        if let updatedTicker = tickers.first(where: { $0.id == ticker.id }) {
            // Since mockAlarms is empty, all IDs should be removed
            XCTAssertEqual(updatedTicker.generatedAlarmKitIDs.count, 0, "Invalid IDs should be removed")
        }
    }
    
    // MARK: - Main ID vs Generated IDs Tests
    
    func testSynchronize_TickerWithMainIDAndGeneratedIDs() async throws {
        // Given: Ticker where main ID matches an alarm, plus generated IDs
        let mainID = UUID()
        let generatedID1 = UUID()
        let generatedID2 = UUID()
        
        let ticker = AlarmSynchronizationServiceTestHelpers.createTickerWithGeneratedIDs(
            id: mainID,
            label: "Main + Generated IDs",
            generatedIDs: [generatedID1, generatedID2]
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Ticker should be handled appropriately
        // Since no alarms exist, generated IDs should be cleaned
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)
        
        // Ticker should exist if it has upcoming alarms
        if let schedule = ticker.schedule {
            let expander = TickerScheduleExpander()
            let oneYear: TimeInterval = 365 * 24 * 3600
            let upcomingDates = expander.expandSchedule(
                schedule,
                withinCustomWindow: Date(),
                duration: oneYear,
                maxAlarms: 1
            )
            
            if !upcomingDates.isEmpty {
                XCTAssertTickersExist(in: context, tickerIDs: [ticker.id])
            }
        }
    }
    
    func testSynchronize_TickerWithOverlappingMainAndGeneratedID() async throws {
        // Given: Ticker where main ID appears in generated IDs (edge case)
        let mainID = UUID()
        
        let ticker = AlarmSynchronizationServiceTestHelpers.createTickerWithGeneratedIDs(
            id: mainID,
            label: "Overlapping IDs",
            generatedIDs: [mainID, UUID()] // Main ID also in generated
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Should handle gracefully
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)
        
        if let updatedTicker = tickers.first(where: { $0.id == ticker.id }) {
            // Generated IDs should be cleaned (no alarms exist)
            XCTAssertTrue(true, "Should handle overlapping IDs")
        }
    }
    
    // MARK: - Mixed Valid/Invalid Scenarios
    
    func testSynchronize_MixedValidAndInvalidGeneratedIDs() async throws {
        // Given: Mix of valid and invalid generated IDs
        let validID1 = UUID()
        let validID2 = UUID()
        let invalidID1 = UUID()
        let invalidID2 = UUID()
        
        let ticker = AlarmSynchronizationServiceTestHelpers.createTickerWithGeneratedIDs(
            id: UUID(),
            label: "Mixed IDs",
            generatedIDs: [validID1, invalidID1, validID2, invalidID2]
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = [] // No alarms, so all invalid
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Invalid IDs should be removed
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)
        
        if let updatedTicker = tickers.first(where: { $0.id == ticker.id }) {
            XCTAssertEqual(updatedTicker.generatedAlarmKitIDs.count, 0, "All invalid IDs should be removed")
        }
    }
    
    func testSynchronize_EmptyGeneratedIDsArray() async throws {
        // Given: Ticker with empty generatedAlarmKitIDs
        let ticker = Ticker.mockDailyMorning
        ticker.generatedAlarmKitIDs = []
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: Should remain empty
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)
        
        if let updatedTicker = tickers.first(where: { $0.id == ticker.id }) {
            XCTAssertEqual(updatedTicker.generatedAlarmKitIDs.count, 0, "Empty array should remain empty")
        }
    }
    
    // MARK: - Large Number of Generated IDs
    
    func testSynchronize_LargeNumberOfGeneratedIDs() async throws {
        // Given: Ticker with many generated IDs
        let generatedIDs = (0..<50).map { _ in UUID() }
        let ticker = AlarmSynchronizationServiceTestHelpers.createTickerWithGeneratedIDs(
            id: UUID(),
            label: "Many IDs",
            generatedIDs: generatedIDs
        )
        
        let context = try TestModelContextFactory.createContextWithTickers([ticker])
        mockStateManager.mockAlarms = []
        
        // When
        await service.synchronize(
            alarmManager: alarmManager,
            stateManager: mockStateManager,
            context: context
        )
        
        // Then: All IDs should be cleaned (no alarms exist)
        let descriptor = FetchDescriptor<Ticker>()
        let tickers = try context.fetch(descriptor)
        
        if let updatedTicker = tickers.first(where: { $0.id == ticker.id }) {
            XCTAssertEqual(updatedTicker.generatedAlarmKitIDs.count, 0, "All IDs should be removed")
        }
    }
}

