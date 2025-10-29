//
//  AlarmHealthTests.swift
//  TickerCoreTests
//
//  Comprehensive tests for AlarmHealth model
//

import XCTest
@testable import TickerCore

final class AlarmHealthTests: XCTestCase {

    // MARK: - HealthStatus Tests

    func testHealthStatusIcons() {
        XCTAssertEqual(HealthStatus.healthy.icon, "checkmark.circle.fill")
        XCTAssertEqual(HealthStatus.warning.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(HealthStatus.critical.icon, "xmark.circle.fill")
    }

    func testHealthStatusColors() {
        XCTAssertEqual(HealthStatus.healthy.color, "green")
        XCTAssertEqual(HealthStatus.warning.color, "orange")
        XCTAssertEqual(HealthStatus.critical.color, "red")
    }

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let health = AlarmHealth()

        XCTAssertNil(health.lastRegenerationDate)
        XCTAssertFalse(health.lastRegenerationSuccess)
        XCTAssertEqual(health.activeAlarmCount, 0)
    }

    func testCustomInitialization() {
        let date = Date()
        let health = AlarmHealth(
            lastRegenerationDate: date,
            lastRegenerationSuccess: true,
            activeAlarmCount: 5
        )

        XCTAssertEqual(health.lastRegenerationDate, date)
        XCTAssertTrue(health.lastRegenerationSuccess)
        XCTAssertEqual(health.activeAlarmCount, 5)
    }

    // MARK: - Factory Method Tests

    func testHealthyFactory() {
        let health = AlarmHealth.healthy(alarmCount: 3)

        XCTAssertNotNil(health.lastRegenerationDate)
        XCTAssertTrue(health.lastRegenerationSuccess)
        XCTAssertEqual(health.activeAlarmCount, 3)
        XCTAssertEqual(health.status, .healthy)
    }

    func testFailedFactory() {
        let previousHealth = AlarmHealth.healthy(alarmCount: 5)
        let failedHealth = AlarmHealth.failed(previousHealth: previousHealth)

        XCTAssertNotNil(failedHealth.lastRegenerationDate)
        XCTAssertFalse(failedHealth.lastRegenerationSuccess)
        XCTAssertEqual(failedHealth.activeAlarmCount, 5)
        XCTAssertEqual(failedHealth.status, .critical)
    }

    func testInitialFactory() {
        let health = AlarmHealth.initial()

        XCTAssertNil(health.lastRegenerationDate)
        XCTAssertFalse(health.lastRegenerationSuccess)
        XCTAssertEqual(health.activeAlarmCount, 0)
        XCTAssertEqual(health.status, .critical)
    }

    // MARK: - Staleness Tests

    func testStalenessNeverRegenerated() {
        let health = AlarmHealth()
        XCTAssertEqual(health.staleness, TimeInterval.infinity)
    }

    func testStalenessRecent() {
        let health = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )

        XCTAssertLessThan(health.staleness, 5) // Should be < 5 seconds
    }

    func testStalenessOld() {
        let oldDate = Date().addingTimeInterval(-25 * 3600) // 25 hours ago
        let health = AlarmHealth(
            lastRegenerationDate: oldDate,
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )

        XCTAssertGreaterThan(health.staleness, 24 * 3600)
    }

    // MARK: - Status Tests

    func testStatusHealthy() {
        let health = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: true,
            activeAlarmCount: 5
        )

        XCTAssertEqual(health.status, .healthy)
    }

    func testStatusCriticalNeverRegenerated() {
        let health = AlarmHealth(
            lastRegenerationDate: nil,
            lastRegenerationSuccess: true,
            activeAlarmCount: 5
        )

        XCTAssertEqual(health.status, .critical)
    }

    func testStatusCriticalFailedRegeneration() {
        let health = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: false,
            activeAlarmCount: 5
        )

        XCTAssertEqual(health.status, .critical)
    }

    func testStatusCriticalNoAlarms() {
        let health = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: true,
            activeAlarmCount: 0
        )

        XCTAssertEqual(health.status, .critical)
    }

    func testStatusWarningStale() {
        let staleDate = Date().addingTimeInterval(-25 * 3600) // 25 hours ago
        let health = AlarmHealth(
            lastRegenerationDate: staleDate,
            lastRegenerationSuccess: true,
            activeAlarmCount: 3
        )

        XCTAssertEqual(health.status, .warning)
    }

    func testStatusCriticalVeryStale() {
        let veryStaleDate = Date().addingTimeInterval(-49 * 3600) // 49 hours ago
        let health = AlarmHealth(
            lastRegenerationDate: veryStaleDate,
            lastRegenerationSuccess: true,
            activeAlarmCount: 3
        )

        XCTAssertEqual(health.status, .critical)
    }

    // MARK: - Status Message Tests

    func testStatusMessageHealthy() {
        let health = AlarmHealth.healthy(alarmCount: 5)
        XCTAssertEqual(health.statusMessage, "All alarms are up to date")
    }

    func testStatusMessageWarningStale() {
        let staleDate = Date().addingTimeInterval(-25 * 3600)
        let health = AlarmHealth(
            lastRegenerationDate: staleDate,
            lastRegenerationSuccess: true,
            activeAlarmCount: 3
        )

        XCTAssertTrue(health.statusMessage.contains("haven't been updated"))
    }

    func testStatusMessageCriticalNeverRegenerated() {
        let health = AlarmHealth.initial()
        XCTAssertEqual(health.statusMessage, "Alarms need to be configured")
    }

    func testStatusMessageCriticalFailed() {
        let health = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: false,
            activeAlarmCount: 5
        )

        XCTAssertEqual(health.statusMessage, "Last alarm update failed")
    }

    func testStatusMessageCriticalNoAlarms() {
        let health = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: true,
            activeAlarmCount: 0
        )

        XCTAssertEqual(health.statusMessage, "No alarms are scheduled")
    }

    // MARK: - Description Tests

    func testLastUpdatedDescriptionJustNow() {
        let health = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )

        XCTAssertEqual(health.lastUpdatedDescription, "Just now")
    }

    func testLastUpdatedDescriptionMinutes() {
        let date = Date().addingTimeInterval(-5 * 60) // 5 minutes ago
        let health = AlarmHealth(
            lastRegenerationDate: date,
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )

        XCTAssertTrue(health.lastUpdatedDescription.contains("minute"))
    }

    func testLastUpdatedDescriptionHours() {
        let date = Date().addingTimeInterval(-2 * 3600) // 2 hours ago
        let health = AlarmHealth(
            lastRegenerationDate: date,
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )

        XCTAssertTrue(health.lastUpdatedDescription.contains("hour"))
    }

    func testLastUpdatedDescriptionDays() {
        let date = Date().addingTimeInterval(-3 * 86400) // 3 days ago
        let health = AlarmHealth(
            lastRegenerationDate: date,
            lastRegenerationSuccess: true,
            activeAlarmCount: 1
        )

        XCTAssertTrue(health.lastUpdatedDescription.contains("day"))
    }

    func testLastUpdatedDescriptionNever() {
        let health = AlarmHealth()
        XCTAssertEqual(health.lastUpdatedDescription, "Never")
    }

    func testDetailedStatus() {
        let health = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: true,
            activeAlarmCount: 5
        )

        let details = health.detailedStatus
        XCTAssertTrue(details.contains("Last updated"))
        XCTAssertTrue(details.contains("5 alarms scheduled"))
    }

    func testDetailedStatusFailed() {
        let health = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: false,
            activeAlarmCount: 3
        )

        let details = health.detailedStatus
        XCTAssertTrue(details.contains("Last update failed"))
    }

    func testDetailedStatusNeverUpdated() {
        let health = AlarmHealth()

        let details = health.detailedStatus
        XCTAssertTrue(details.contains("Never updated"))
    }

    // MARK: - Codable Tests

    func testCodableEncodingDecoding() throws {
        let original = AlarmHealth(
            lastRegenerationDate: Date(),
            lastRegenerationSuccess: true,
            activeAlarmCount: 10
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AlarmHealth.self, from: data)

        XCTAssertEqual(decoded.lastRegenerationSuccess, original.lastRegenerationSuccess)
        XCTAssertEqual(decoded.activeAlarmCount, original.activeAlarmCount)
        XCTAssertNotNil(decoded.lastRegenerationDate)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let date = Date()
        let health1 = AlarmHealth(
            lastRegenerationDate: date,
            lastRegenerationSuccess: true,
            activeAlarmCount: 5
        )
        let health2 = AlarmHealth(
            lastRegenerationDate: date,
            lastRegenerationSuccess: true,
            activeAlarmCount: 5
        )

        XCTAssertEqual(health1, health2)
    }

    func testInequality() {
        let health1 = AlarmHealth.healthy(alarmCount: 5)
        let health2 = AlarmHealth.healthy(alarmCount: 10)

        XCTAssertNotEqual(health1, health2)
    }
}
