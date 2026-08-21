//
//  AlarmTelemetrySinkAdapter.swift
//  Ticker
//
//  Bridges TickerCore's alarm telemetry events onto PostHog.
//
//  TickerCore cannot see this type — it depends only on Factory, and
//  `AnalyticsEvents` lives in the app target. The app installs this sink at
//  launch; TickerCore raises events through the `AlarmTelemetry` facade.
//
//  These are the events that make the product's core promise measurable. Before
//  them the app could report paywall views to three decimal places and could not
//  answer "did alarms ring last night?".
//

import Foundation
import TickerCore
import Telemetry

struct PostHogAlarmTelemetrySink: AlarmTelemetrySink {

    func record(_ event: AlarmTelemetryEvent) {
        switch event {

        case let .alarmFiredInferred(alarmID, scheduledAt, detectedAt):
            TelemetryService.shared.track(
                event: "alarm_fired",
                properties: [
                    "alarm_id": alarmID.uuidString,
                    "scheduled_at": ISO8601DateFormatter().string(from: scheduledAt),
                    "detected_at": ISO8601DateFormatter().string(from: detectedAt),
                    "detection_method": "absence_inference",
                    "detection_lag_seconds": Int(detectedAt.timeIntervalSince(scheduledAt))
                ]
            )

        case let .alarmsExpected(count, since):
            // The denominator. `alarm_fired / alarms_expected` is the reliability
            // metric worth alerting on.
            TelemetryService.shared.track(
                event: "alarms_expected",
                properties: [
                    "count": count,
                    "since": ISO8601DateFormatter().string(from: since)
                ]
            )

        case let .scheduledAlarmCount(count):
            TelemetryService.shared.track(
                event: "scheduled_alarm_count",
                properties: [
                    "count": count,
                    "budget": AlarmBudget.maxScheduledAlarms
                ]
            )

        case let .alarmReaction(kind, alarmID):
            // Independent proof of a fire: the intent process really did run.
            TelemetryService.shared.track(
                event: "alarm_reaction",
                properties: [
                    "kind": kind.rawValue,
                    "alarm_id": alarmID.uuidString
                ]
            )

        case let .alarmScheduleFailed(reason):
            TelemetryService.shared.track(
                event: "alarm_schedule_failed",
                properties: ["reason": reason]
            )

        case let .alarmBudgetExhausted(scheduled, limit):
            TelemetryService.shared.track(
                event: "alarm_budget_exhausted",
                properties: [
                    "scheduled": scheduled,
                    "limit": limit
                ]
            )
        }
    }
}
