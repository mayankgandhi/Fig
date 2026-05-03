//
//  DesignTokenValidationTests.swift
//  TickerCoreTests
//
//  Validates design token consistency across the design system.
//

import XCTest
import SwiftUI
@testable import TickerCore

final class DesignTokenValidationTests: XCTestCase {

    // MARK: - Color Token Validation

    func testPausedColorIsSlateBlueGray() {
        // #94A3B8 = rgb(0.580, 0.639, 0.722)
        let expected = Color(red: 0.580, green: 0.639, blue: 0.722)
        XCTAssertEqual(
            TickerColor.paused.description,
            expected.description,
            "Paused color should be slate blue-gray #94A3B8"
        )
    }

    func testWarningColorIsRed() {
        // #EF4444 = rgb(0.937, 0.267, 0.267)
        let expected = Color(red: 0.937, green: 0.267, blue: 0.267)
        XCTAssertEqual(
            TickerColor.warning.description,
            expected.description,
            "Warning color should be red #EF4444"
        )
    }

    func testPausedAndScheduledAreDistinct() {
        XCTAssertNotEqual(
            TickerColor.paused.description,
            TickerColor.scheduled.description,
            "Paused (#94A3B8) and scheduled (#F98947) must be visually distinct"
        )
    }

    func testWarningAndAccentAreDistinct() {
        XCTAssertNotEqual(
            TickerColor.warning.description,
            TickerColor.accent.description,
            "Warning (#EF4444) and accent (#F99D2B) must be visually distinct"
        )
    }

    // MARK: - Spacing Token Validation

    func testSpacingTokensArePositive() {
        XCTAssertGreaterThan(TickerSpacing.xxs, 0)
        XCTAssertGreaterThan(TickerSpacing.xs, 0)
        XCTAssertGreaterThan(TickerSpacing.sm, 0)
        XCTAssertGreaterThan(TickerSpacing.md, 0)
        XCTAssertGreaterThan(TickerSpacing.lg, 0)
        XCTAssertGreaterThan(TickerSpacing.xl, 0)
        XCTAssertGreaterThan(TickerSpacing.xxl, 0)
        XCTAssertGreaterThan(TickerSpacing.xxxl, 0)
    }

    func testSpacingTokensAreOrdered() {
        XCTAssertLessThan(TickerSpacing.xxs, TickerSpacing.xs)
        XCTAssertLessThan(TickerSpacing.xs, TickerSpacing.sm)
        XCTAssertLessThan(TickerSpacing.sm, TickerSpacing.md)
        XCTAssertLessThan(TickerSpacing.md, TickerSpacing.lg)
        XCTAssertLessThan(TickerSpacing.lg, TickerSpacing.xl)
        XCTAssertLessThan(TickerSpacing.xl, TickerSpacing.xxl)
        XCTAssertLessThan(TickerSpacing.xxl, TickerSpacing.xxxl)
    }

    // MARK: - Radius Token Validation

    func testRadiusTokensAreOrdered() {
        XCTAssertLessThanOrEqual(TickerRadius.none, TickerRadius.tight)
        XCTAssertLessThan(TickerRadius.tight, TickerRadius.small)
        XCTAssertLessThan(TickerRadius.small, TickerRadius.medium)
        XCTAssertLessThan(TickerRadius.medium, TickerRadius.large)
        XCTAssertLessThan(TickerRadius.large, TickerRadius.xlarge)
        XCTAssertLessThan(TickerRadius.xlarge, TickerRadius.full)
    }

    // MARK: - Tap Target Validation

    func testTapTargetMeetsMinimum() {
        XCTAssertGreaterThanOrEqual(
            TickerSpacing.tapTargetMin, 44,
            "Minimum tap target must be at least 44pt per Apple HIG"
        )
    }

    // MARK: - Alarm State Colors Are All Distinct

    func testAlarmStateColorsAreAllDistinct() {
        let states = [
            ("scheduled", TickerColor.scheduled.description),
            ("running", TickerColor.running.description),
            ("paused", TickerColor.paused.description),
            ("alerting", TickerColor.alerting.description),
            ("disabled", TickerColor.disabled.description),
        ]

        for i in 0..<states.count {
            for j in (i + 1)..<states.count {
                XCTAssertNotEqual(
                    states[i].1, states[j].1,
                    "\(states[i].0) and \(states[j].0) alarm state colors must be distinct"
                )
            }
        }
    }
}
