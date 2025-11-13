//
//  AlarmConfigurationBuilderTests.swift
//  TickerCoreTests
//
//  Comprehensive unit tests for AlarmConfigurationBuilder
//  Tests that configurations are created successfully for various Ticker configurations
//
//  Note: AlarmConfiguration from AlarmKit is a completely opaque struct.
//  It does NOT expose any properties (schedule, stopIntent, countdownDuration,
//  sound, secondaryIntent, or even attributes) publicly.
//  These tests verify that configurations are created successfully.
//

import XCTest
@testable import TickerCore
import AlarmKit
import SwiftUI
import AppIntents

@available(iOS 26.0, *)
final class AlarmConfigurationBuilderTests: XCTestCase {

    var builder: AlarmConfigurationBuilder!

    override func setUp() {
        super.setUp()
        builder = AlarmConfigurationBuilder()
    }

    override func tearDown() {
        builder = nil
        super.tearDown()
    }

    // MARK: - Basic Configuration Tests

    func testBuildConfiguration_ReturnsNonNil() {
        // Given
        let ticker = Ticker.mockDailyMorning
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should not be nil")
    }

    func testBuildConfiguration_WithBasicDailyTicker() {
        // Given
        let ticker = Ticker.mockDailyMorning
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created for basic daily ticker")
    }

    // MARK: - Schedule Tests

    func testBuildConfiguration_OneTimeAlarm() {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let ticker = Ticker(
            label: "One Time",
            schedule: .oneTime(date: futureDate)
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created for one-time alarm")
    }

    func testBuildConfiguration_DailyAlarm() {
        // Given
        let ticker = Ticker.mockDailyMorning
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created for daily alarm")
    }

    func testBuildConfiguration_WithCountdown() {
        // Given
        let ticker = Ticker(
            label: "Countdown Alarm",
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            countdown: .init(
                preAlert: .init(hours: 0, minutes: 30, seconds: 0)
            )
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with countdown")
    }

    // MARK: - Countdown Variations

    func testBuildConfiguration_WithoutCountdown() {
        // Given
        let ticker = Ticker.mockDailyMorning // No countdown
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created without countdown")
    }

    func testBuildConfiguration_WithPreAlertOnly() {
        // Given
        let ticker = Ticker.mockWithPreAlert
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with preAlert")
    }

    func testBuildConfiguration_WithFullCountdown() {
        // Given
        let ticker = Ticker.mockWithFullCountdown
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with full countdown")
    }

    func testBuildConfiguration_WithSnoozePostAlert() {
        // Given
        let ticker = Ticker.mockWithFullCountdown
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with snooze")
    }

    func testBuildConfiguration_WithRepeatPostAlert() {
        // Given
        let ticker = Ticker.mockWithCountdownRepeat
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with repeat")
    }

    func testBuildConfiguration_WithOpenAppPostAlert() {
        // Given
        let ticker = Ticker.mockWithCountdownOpenApp
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with openApp behavior")
    }

    // MARK: - Presentation Variations

    func testBuildConfiguration_WithCountdownPresentation() {
        // Given
        let ticker = Ticker(
            label: "Repeat Alarm",
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init(secondaryButtonType: .countdown)
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with countdown presentation")
    }

    func testBuildConfiguration_WithOpenAppPresentation() {
        // Given
        let ticker = Ticker(
            label: "Open App Alarm",
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init(secondaryButtonType: .openApp)
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with openApp presentation")
    }

    func testBuildConfiguration_WithDefaultPresentation() {
        // Given
        let ticker = Ticker.mockDailyMorning // Default presentation
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with default presentation")
    }

    // MARK: - Metadata Tests

    func testBuildConfiguration_WithTickerData() {
        // Given
        let ticker = Ticker(
            label: "Test",
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            tickerData: .init(name: "Workout", icon: "figure.run", colorHex: "#FF5733")
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with tickerData")
    }

    func testBuildConfiguration_WithoutTickerData() {
        // Given
        let ticker = Ticker.mockDailyMorning // No tickerData
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created without tickerData")
    }

    func testBuildConfiguration_WithPartialTickerData() {
        // Given
        let ticker = Ticker(
            label: "Partial",
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            tickerData: .init(name: "Test", icon: nil, colorHex: nil)
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with partial tickerData")
    }

    // MARK: - Tint Color Tests

    func testBuildConfiguration_WithCustomHexColor() {
        // Given
        let ticker = Ticker(
            label: "Custom Color",
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            tickerData: .init(name: nil, icon: nil, colorHex: "#FF5733")
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with custom hex color")
    }

    func testBuildConfiguration_WithInvalidHexColor() {
        // Given
        let ticker = Ticker(
            label: "Invalid Color",
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            tickerData: .init(name: nil, icon: nil, colorHex: "INVALID_HEX")
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created even with invalid hex (falls back to default)")
    }

    func testBuildConfiguration_WithVariousHexFormats() {
        // Test various valid hex formats
        let hexFormats = ["#FF5733", "#F57", "#FF5733FF", "FF5733"]

        for hex in hexFormats {
            // Given
            let ticker = Ticker(
                label: "Hex Test",
                schedule: .daily(time: .init(hour: 9, minute: 0)),
                tickerData: .init(name: nil, icon: nil, colorHex: hex)
            )
            let occurrenceAlarmID = UUID()

            // When
            let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

            // Then
            XCTAssertNotNil(configuration, "Configuration should be created with hex format: \(hex)")
        }
    }

    // MARK: - Sound Tests

    func testBuildConfiguration_WithDefaultSound() {
        // Given
        let ticker = Ticker.mockWithDefaultSound
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with default sound")
    }

    func testBuildConfiguration_WithCustomSound() {
        // Given
        let ticker = Ticker.mockWithCustomSound
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with custom sound")
    }

    func testBuildConfiguration_WithMissingSound() {
        // Given
        let ticker = Ticker(
            label: "Missing Sound",
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            soundName: "nonexistent_sound.mp3"
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created (falls back to default when sound not found)")
    }

    // MARK: - Label Tests

    func testBuildConfiguration_WithEmptyLabel() {
        // Given
        let ticker = Ticker.mockEmptyLabel
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with empty label")
    }

    func testBuildConfiguration_WithLongLabel() {
        // Given
        let ticker = Ticker.mockLongLabel
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with long label")
    }

    func testBuildConfiguration_WithSpecialCharactersLabel() {
        // Given
        let ticker = Ticker.mockSpecialCharactersLabel
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created with special characters in label")
    }

    // MARK: - Comprehensive Integration Tests

    func testBuildConfiguration_ComplexTicker() {
        // Given
        let ticker = Ticker.mockComplex
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created for complex ticker")
    }

    func testBuildConfiguration_MinimalTicker() {
        // Given
        let ticker = Ticker(
            label: "Minimal",
            schedule: .daily(time: .init(hour: 9, minute: 0))
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created for minimal ticker")
    }

    func testBuildConfiguration_FullFeaturedTicker() {
        // Given
        let ticker = Ticker(
            label: "Full Featured",
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            countdown: .init(
                preAlert: .init(hours: 0, minutes: 30, seconds: 0),
                postAlert: .snooze(duration: .init(hours: 0, minutes: 10, seconds: 0))
            ),
            presentation: .init(
                tintColorHex: "#3498DB",
                secondaryButtonType: .countdown
            ),
            soundName: "custom_sound.mp3",
            tickerData: .init(
                name: "Workout",
                icon: "figure.run",
                colorHex: "#FF5733"
            )
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created for full-featured ticker")
    }

    // MARK: - Edge Cases

    func testBuildConfiguration_MultipleOccurrencesOfSameTicker() {
        // Given
        let ticker = Ticker.mockDailyMorning
        let occurrence1 = UUID()
        let occurrence2 = UUID()

        // When
        let config1 = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrence1)
        let config2 = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrence2)

        // Then
        XCTAssertNotNil(config1, "First configuration should be created")
        XCTAssertNotNil(config2, "Second configuration should be created")
    }

    func testBuildConfiguration_WithNilSchedule() {
        // Given
        let ticker = Ticker(
            label: "Timer",
            schedule: nil // Timer mode
        )
        let occurrenceAlarmID = UUID()

        // When
        let configuration = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(configuration, "Configuration should be created without schedule (timer mode)")
    }

    func testBuildConfiguration_WithAllMockTypes() {
        // Test all available mock tickers to ensure they all produce valid configurations
        let mocks: [Ticker] = [
            .mockDailyMorning,
            .mockWithPreAlert,
            .mockWithFullCountdown,
            .mockWithCountdownRepeat,
            .mockWithCountdownOpenApp,
            .mockWithDefaultSound,
            .mockWithCustomSound,
            .mockEmptyLabel,
            .mockLongLabel,
            .mockSpecialCharactersLabel,
            .mockComplex,
            .mockWithCustomPresentation
        ]

        for mock in mocks {
            // Given
            let occurrenceAlarmID = UUID()

            // When
            let configuration = builder.buildConfiguration(from: mock, occurrenceAlarmID: occurrenceAlarmID)

            // Then
            XCTAssertNotNil(configuration, "Configuration should be created for mock: \(mock.label)")
        }
    }

    // MARK: - Consistency Tests

    func testBuildConfiguration_SameInputProducesDifferentInstances() {
        // Given
        let ticker = Ticker.mockDailyMorning
        let occurrenceAlarmID = UUID()

        // When
        let config1 = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)
        let config2 = builder.buildConfiguration(from: ticker, occurrenceAlarmID: occurrenceAlarmID)

        // Then
        XCTAssertNotNil(config1, "First configuration should be created")
        XCTAssertNotNil(config2, "Second configuration should be created")
        // Note: We cannot test if they are different instances since AlarmConfiguration
        // doesn't conform to Equatable and has no accessible properties
    }

    func testBuildConfiguration_BuilderIsReusable() {
        // Given
        let ticker1 = Ticker.mockDailyMorning
        let ticker2 = Ticker.mockWithPreAlert
        let occurrenceAlarmID1 = UUID()
        let occurrenceAlarmID2 = UUID()

        // When
        let config1 = builder.buildConfiguration(from: ticker1, occurrenceAlarmID: occurrenceAlarmID1)
        let config2 = builder.buildConfiguration(from: ticker2, occurrenceAlarmID: occurrenceAlarmID2)

        // Then
        XCTAssertNotNil(config1, "First configuration should be created")
        XCTAssertNotNil(config2, "Second configuration should be created")
    }
}
