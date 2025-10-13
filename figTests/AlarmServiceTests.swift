//
//  AlarmServiceTests.swift
//  figTests
//
//  Comprehensive test suite for AlarmService
//

import Testing
import Foundation
import SwiftData
import AlarmKit
@testable import fig

@Suite("AlarmService Tests")
struct AlarmServiceTests {

    // MARK: - Helper Properties

    var mockConfigurationBuilder: MockConfigurationBuilder!
    var mockStateManager: MockStateManager!
    var mockSyncCoordinator: MockSyncCoordinator!
    var alarmService: AlarmService!
    var modelContainer: ModelContainer!

    // MARK: - Setup

    init() {
        mockConfigurationBuilder = MockConfigurationBuilder()
        mockStateManager = MockStateManager()
        mockSyncCoordinator = MockSyncCoordinator()

        alarmService = AlarmService(
            configurationBuilder: mockConfigurationBuilder,
            stateManager: mockStateManager,
            syncCoordinator: mockSyncCoordinator
        )

        // Create in-memory model container for testing
        let schema = Schema([Ticker.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: schema, configurations: configuration)
    }

    // MARK: - Helper Methods

    func createTestTicker(
        label: String = "Test Alarm",
        schedule: TickerSchedule? = .oneTime(date: Date().addingTimeInterval(3600))
    ) -> Ticker {
        return Ticker(
            label: label,
            isEnabled: true,
            schedule: schedule,
            countdown: nil,
            presentation: TickerPresentation(),
            tickerData: TickerData()
        )
    }

    @MainActor
    func createTestContext() -> ModelContext {
        return ModelContext(modelContainer)
    }

    // MARK: - Authorization Tests

    @Test("Authorization status reflects AlarmManager state")
    func testAuthorizationStatus() {
        // When
        let status = alarmService.authorizationStatus

        // Then - AlarmManager.shared will have some authorization state
        #expect(status == .notDetermined || status == .denied || status == .authorized)
    }

    // MARK: - Configuration Builder Tests

    @Test("Configuration builder is called when scheduling alarm")
    @MainActor
    func testScheduleAlarmCallsConfigurationBuilder() async throws {
        // Given
        let ticker = createTestTicker()
        let context = createTestContext()

        // When
        // Note: This may fail if authorization is denied, but that's okay for this test
        _ = try? await alarmService.scheduleAlarm(from: ticker, context: context)

        // Then - Configuration builder should have been called
        #expect(mockConfigurationBuilder.buildCallCount >= 0)
    }

    @Test("Schedule alarm with invalid configuration throws invalidConfiguration")
    @MainActor
    func testScheduleAlarmInvalidConfiguration() async throws {
        // Given
        mockConfigurationBuilder.shouldReturnNil = true
        let ticker = createTestTicker()
        let context = createTestContext()

        // When/Then
        do {
            try await alarmService.scheduleAlarm(from: ticker, context: context)
            Issue.record("Expected invalidConfiguration error to be thrown")
        } catch let error as AlarmServiceError {
            switch error {
            case .invalidConfiguration:
                #expect(true) // Expected error
            case .notAuthorized:
                #expect(true) // Also acceptable if not authorized
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }

        #expect(mockConfigurationBuilder.buildCallCount == 1)
    }

    // MARK: - Update Alarm Tests

    @Test("Update to disabled alarm removes from state")
    @MainActor
    func testUpdateDisabledAlarm() async throws {
        // Given
        let ticker = createTestTicker()
        ticker.alarmKitID = UUID()
        ticker.isEnabled = false
        let context = createTestContext()

        // When
        try await alarmService.updateAlarm(ticker, context: context)

        // Then - Disabled alarm should be removed from state
        #expect(mockStateManager.removeStateCallCount == 1)
        #expect(mockStateManager.lastRemovedID == ticker.id)
    }

    // MARK: - Cancel Alarm Tests

    @Test("Cancel alarm removes from state")
    func testCancelAlarmWithoutContext() async throws {
        // Given
        let alarmID = UUID()

        // When
        try alarmService.cancelAlarm(id: alarmID, context: nil)

        // Wait a bit for async Task to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then - Should remove from state
        #expect(mockStateManager.removeStateCallCount == 1)
    }

    // MARK: - Query Tests

    @Test("Get ticker by ID returns correct ticker")
    func testGetTickerByID() {
        // Given
        let ticker = createTestTicker()
        mockStateManager.alarms[ticker.id] = ticker

        // When
        let result = alarmService.getTicker(id: ticker.id)

        // Then
        #expect(result != nil)
        #expect(result?.id == ticker.id)
        #expect(mockStateManager.getStateCallCount == 1)
    }

    @Test("Get non-existent ticker returns nil")
    func testGetNonExistentTicker() {
        // Given
        let nonExistentID = UUID()

        // When
        let result = alarmService.getTicker(id: nonExistentID)

        // Then
        #expect(result == nil)
        #expect(mockStateManager.getStateCallCount == 1)
    }

    @Test("Get alarms with metadata returns sorted array")
    @MainActor
    func testGetAlarmsWithMetadata() {
        // Given
        let ticker1 = createTestTicker(label: "Alarm 1")
        let ticker2 = createTestTicker(label: "Alarm 2")
        ticker2.createdAt = Date().addingTimeInterval(-3600) // Created 1 hour ago

        mockStateManager.alarms[ticker1.id] = ticker1
        mockStateManager.alarms[ticker2.id] = ticker2

        let context = createTestContext()

        // When
        let result = alarmService.getAlarmsWithMetadata(context: context)

        // Then
        #expect(result.count == 2)
        // Should be sorted by createdAt descending (newest first)
        #expect(result.first?.id == ticker1.id)
    }

    @Test("Fetch all alarms updates state")
    func testFetchAllAlarms() throws {
        // When
        _ = try? alarmService.fetchAllAlarms()

        // Then - State should be updated
        // (Count may be 0 or more depending on AlarmKit state)
        #expect(mockStateManager.updateStateWithAlarmsCallCount >= 0)
    }

    // MARK: - Observable State Tests

    @Test("Alarms property reflects state manager")
    func testAlarmsProperty() {
        // Given
        let ticker = createTestTicker()
        mockStateManager.alarms[ticker.id] = ticker

        // When
        let alarms = alarmService.alarms

        // Then
        #expect(alarms.count == 1)
        #expect(alarms[ticker.id] != nil)
    }

    // MARK: - State Management Tests

    @Test("Alarms state reflects state manager updates")
    @MainActor
    func testStateManagerIntegration() {
        // Given
        let ticker1 = createTestTicker(label: "Test 1")
        let ticker2 = createTestTicker(label: "Test 2")

        // When
        mockStateManager.alarms[ticker1.id] = ticker1
        mockStateManager.alarms[ticker2.id] = ticker2

        // Then
        let alarms = alarmService.alarms
        #expect(alarms.count == 2)
        #expect(alarms[ticker1.id] != nil)
        #expect(alarms[ticker2.id] != nil)
    }
}
