//
//  MockTickerServiceDependencies.swift
//  figTests
//
//  Mock implementations of TickerService dependencies for testing
//

import Foundation
import SwiftData
import AlarmKit
@testable import Ticker

// MARK: - MockConfigurationBuilder

final class MockConfigurationBuilder: AlarmConfigurationBuilderProtocol {
    var shouldReturnNil = false
    var buildCallCount = 0
    var lastAlarmItem: Ticker?

    func buildConfiguration(from alarmItem: Ticker) -> AlarmManager.AlarmConfiguration<TickerData>? {
        buildCallCount += 1
        lastAlarmItem = alarmItem

        guard !shouldReturnNil else { return nil }

        // Return a valid configuration
        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: alarmItem.label),
                stopButton: AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle"),
                secondaryButton: nil,
                secondaryButtonBehavior: nil
            )),
            metadata: alarmItem.tickerData ?? TickerData(),
            tintColor: .accentColor
        )

        return AlarmManager.AlarmConfiguration(
            countdownDuration: alarmItem.alarmKitCountdownDuration,
            schedule: alarmItem.alarmKitSchedule,
            attributes: attributes,
            stopIntent: StopIntent(alarmID: alarmItem.id.uuidString),
            secondaryIntent: nil
        )
    }

    func reset() {
        shouldReturnNil = false
        buildCallCount = 0
        lastAlarmItem = nil
    }
}

// MARK: - MockStateManager

final class MockStateManager: AlarmStateManagerProtocol {

    var alarms: [UUID: Ticker] = [:]

    var updateStateWithAlarmsCallCount = 0
    var updateStateFromAlarmCallCount = 0
    var removeStateCallCount = 0
    var getStateCallCount = 0

    var lastRemovedID: UUID?

    func updateState(with remoteAlarms: [Alarm]) {
        updateStateWithAlarmsCallCount += 1
        // Simple implementation for testing
        remoteAlarms.forEach { alarm in
            if alarms[alarm.id] == nil {
                let ticker = Ticker(id: alarm.id, label: "Mock Alarm", isEnabled: true)
                ticker.generatedAlarmKitIDs = [alarm.id]
                alarms[alarm.id] = ticker
            }
        }
    }

    @MainActor
    func updateState(ticker: Ticker) {
        updateStateFromAlarmCallCount += 1
        alarms[ticker.id] = ticker
    }

    @MainActor
    func removeState(id: UUID) {
        removeStateCallCount += 1
        lastRemovedID = id
        alarms[id] = nil
    }

    func getState(id: UUID) -> Ticker? {
        getStateCallCount += 1
        return alarms[id]
    }

    func reset() {
        alarms = [:]
        updateStateWithAlarmsCallCount = 0
        updateStateFromAlarmCallCount = 0
        removeStateCallCount = 0
        getStateCallCount = 0
        lastRemovedID = nil
    }
}

// MARK: - MockSyncCoordinator

final class MockSyncCoordinator: AlarmSyncCoordinatorProtocol {
    var synchronizeCallCount = 0
    var shouldThrow = false

    @MainActor
    func synchronizeOnLaunch(
        alarmManager: AlarmManager,
        stateManager: AlarmStateManagerProtocol,
        context: ModelContext
    ) async {
        synchronizeCallCount += 1
    }

    func reset() {
        synchronizeCallCount = 0
        shouldThrow = false
    }
}

