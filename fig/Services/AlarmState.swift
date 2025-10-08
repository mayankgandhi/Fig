//
//  AlarmState.swift
//  fig
//
//  Created by Mayank Gandhi on 08/10/25.
//

import Foundation
import AlarmKit
// MARK: - AlarmState

struct AlarmState {
    let id: UUID
    let state: State
    let alertingTime: Date?
    let countdownRemaining: TimeInterval?
    let label: LocalizedStringResource

    enum State {
        case scheduled
        case countdown
        case paused
        case alerting

        init(from alarmKitState: Alarm.State) {
            switch alarmKitState {
            case .scheduled:
                self = .scheduled
            case .countdown:
                self = .countdown
            case .paused:
                self = .paused
            case .alerting:
                self = .alerting
            @unknown default:
                self = .scheduled
            }
        }
    }

    init(from alarm: Alarm, label: LocalizedStringResource) {
        self.id = alarm.id
        self.state = State(from: alarm.state)
        self.alertingTime = alarm.alertingTime
        self.countdownRemaining = nil // Could be calculated from alarm.countdownDuration
        self.label = label
    }
}
