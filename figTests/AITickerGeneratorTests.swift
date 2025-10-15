//
//  AITickerGeneratorTests.swift
//  figTests
//
//  Unit tests for AI ticker generation
//

import XCTest
@testable import fig

@MainActor
final class AITickerGeneratorTests: XCTestCase {
    
    var aiGenerator: AITickerGenerator!
    var parser: TickerConfigurationParser!
    
    override func setUp() {
        super.setUp()
        aiGenerator = AITickerGenerator()
        parser = TickerConfigurationParser()
    }
    
    override func tearDown() {
        aiGenerator = nil
        parser = nil
        super.tearDown()
    }
    
    // MARK: - Time Parsing Tests
    
    func testTimeParsing_12HourFormat() async throws {
        let input = "Wake up at 7am every day"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.time.hour, 7)
        XCTAssertEqual(configuration.time.minute, 0)
    }
    
    func testTimeParsing_12HourFormatPM() async throws {
        let input = "Meeting at 2:30pm tomorrow"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.time.hour, 14)
        XCTAssertEqual(configuration.time.minute, 30)
    }
    
    func testTimeParsing_24HourFormat() async throws {
        let input = "Gym at 18:00 every weekday"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.time.hour, 18)
        XCTAssertEqual(configuration.time.minute, 0)
    }
    
    func testTimeParsing_WithMinutes() async throws {
        let input = "Coffee break at 3:15pm daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.time.hour, 15)
        XCTAssertEqual(configuration.time.minute, 15)
    }
    
    func testTimeParsing_NaturalExpressions() async throws {
        let testCases = [
            ("Meeting at noon", 12, 0),
            ("Wake up at midnight", 0, 0),
            ("Lunch at lunchtime", 12, 0),
            ("Exercise in the morning", 8, 0),
            ("Dinner in the evening", 18, 0),
            ("Bedtime at night", 20, 0)
        ]
        
        for (input, expectedHour, expectedMinute) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(configuration.time.hour, expectedHour, "Failed for input: \(input)")
            XCTAssertEqual(configuration.time.minute, expectedMinute, "Failed for input: \(input)")
        }
    }
    
    func testTimeParsing_FlexibleFormats() async throws {
        let testCases = [
            ("Meeting at 9:30 AM", 9, 30),
            ("Wake up at 7:00am", 7, 0),
            ("Lunch at 12.30pm", 12, 30),
            ("Gym at 6:45 PM", 18, 45),
            ("Coffee at 3:15", 15, 15),
            ("Dinner around 7pm", 19, 0)
        ]
        
        for (input, expectedHour, expectedMinute) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(configuration.time.hour, expectedHour, "Failed for input: \(input)")
            XCTAssertEqual(configuration.time.minute, expectedMinute, "Failed for input: \(input)")
        }
    }
    
    // MARK: - Repeat Pattern Tests
    
    func testRepeatPattern_Daily() async throws {
        let input = "Take medication at 9am every day"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        if case .daily = configuration.repeatOption {
            // Success
        } else {
            XCTFail("Expected daily repeat pattern")
        }
    }
    
    func testRepeatPattern_Weekdays() async throws {
        let input = "Wake up at 7am on weekdays"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        if case .weekdays(let weekdays) = configuration.repeatOption {
            XCTAssertEqual(weekdays, [.monday, .tuesday, .wednesday, .thursday, .friday])
        } else {
            XCTFail("Expected weekdays repeat pattern")
        }
    }
    
    func testRepeatPattern_SpecificDays() async throws {
        let input = "Yoga class every Monday and Wednesday at 7am"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        if case .weekdays(let weekdays) = configuration.repeatOption {
            XCTAssertTrue(weekdays.contains(.monday))
            XCTAssertTrue(weekdays.contains(.wednesday))
        } else {
            XCTFail("Expected specific weekdays repeat pattern")
        }
    }
    
    func testRepeatPattern_EnhancedVariations() async throws {
        let testCases = [
            ("Meeting every day", RepeatOption.daily),
            ("Wake up daily", RepeatOption.daily),
            ("Exercise each day", RepeatOption.daily),
            ("Work on weekdays", RepeatOption.weekdays([.monday, .tuesday, .wednesday, .thursday, .friday])),
            ("Gym on workdays", RepeatOption.weekdays([.monday, .tuesday, .wednesday, .thursday, .friday])),
            ("Yoga on Mondays and Wednesdays", RepeatOption.weekdays([.monday, .wednesday])),
            ("Meeting every 2 hours", RepeatOption.hourly(interval: 2)),
            ("Check every 3 hours", RepeatOption.hourly(interval: 3)),
            ("Biweekly meeting", RepeatOption.biweekly([.monday, .wednesday, .friday])),
            ("Monthly report on the 15th", RepeatOption.monthly(day: 15))
        ]
        
        for (input, expectedOption) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(String(describing: configuration.repeatOption), String(describing: expectedOption), "Failed for input: \(input)")
        }
    }
    
    func testRepeatPattern_NoRepeat() async throws {
        let input = "Doctor appointment at 2pm tomorrow"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        if case .noRepeat = configuration.repeatOption {
            // Success
        } else {
            XCTFail("Expected no repeat pattern")
        }
    }
    
    // MARK: - Activity Mapping Tests
    
    func testActivityMapping_Exercise() async throws {
        let input = "Morning yoga at 7am daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.label, "Yoga")
        XCTAssertEqual(configuration.icon, "figure.yoga")
        XCTAssertEqual(configuration.colorHex, "#84CC16")
    }
    
    func testActivityMapping_Medication() async throws {
        let input = "Take pills at 9am and 9pm daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.label, "Pills")
        XCTAssertEqual(configuration.icon, "pills")
        XCTAssertEqual(configuration.colorHex, "#EF4444")
    }
    
    func testActivityMapping_Work() async throws {
        let input = "Team meeting at 2pm every Tuesday"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.label, "Team Meeting")
        XCTAssertEqual(configuration.icon, "person.3")
        XCTAssertEqual(configuration.colorHex, "#3B82F6")
    }
    
    func testActivityMapping_Meals() async throws {
        let input = "Lunch break at 12pm daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.label, "Lunch")
        XCTAssertEqual(configuration.icon, "fork.knife")
        XCTAssertEqual(configuration.colorHex, "#10B981")
    }
    
    // MARK: - Countdown Tests
    
    func testCountdownParsing() async throws {
        let input = "Meeting at 2pm with 5 minute countdown"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertNotNil(configuration.countdown)
        XCTAssertEqual(configuration.countdown?.hours, 0)
        XCTAssertEqual(configuration.countdown?.minutes, 5)
        XCTAssertEqual(configuration.countdown?.seconds, 0)
    }
    
    func testCountdownParsing_NoCountdown() async throws {
        let input = "Wake up at 7am daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertNil(configuration.countdown)
    }
    
    func testCountdownParsing_EnhancedVariations() async throws {
        let testCases = [
            ("Meeting with 10 minute reminder", 0, 10, 0),
            ("Wake up with 5 min alert", 0, 5, 0),
            ("Gym with 1 hour countdown", 1, 0, 0),
            ("Lunch with 30 minute notice", 0, 30, 0),
            ("Meeting after 15 minutes", 0, 15, 0),
            ("Wake up in 2 hours", 2, 0, 0),
            ("Coffee with 1 hour and 30 minute countdown", 1, 30, 0),
            ("Meeting with 45 second countdown", 0, 0, 45)
        ]
        
        for (input, expectedHours, expectedMinutes, expectedSeconds) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertNotNil(configuration.countdown, "Failed for input: \(input)")
            XCTAssertEqual(configuration.countdown?.hours, expectedHours, "Failed for input: \(input)")
            XCTAssertEqual(configuration.countdown?.minutes, expectedMinutes, "Failed for input: \(input)")
            XCTAssertEqual(configuration.countdown?.seconds, expectedSeconds, "Failed for input: \(input)")
        }
    }
    
    // MARK: - Date Parsing Tests
    
    func testDateParsing_Tomorrow() async throws {
        let input = "Doctor appointment at 2pm tomorrow"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        XCTAssertEqual(calendar.component(.day, from: configuration.date), 
                      calendar.component(.day, from: tomorrow))
    }
    
    func testDateParsing_Today() async throws {
        let input = "Meeting at 3pm today"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        let calendar = Calendar.current
        let today = Date()
        
        XCTAssertEqual(calendar.component(.day, from: configuration.date), 
                      calendar.component(.day, from: today))
    }
    
    // MARK: - Complex Input Tests
    
    func testComplexInput_FullDescription() async throws {
        let input = "Morning yoga every Monday, Wednesday, Friday at 7am with 10 minute countdown"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        // Check time
        XCTAssertEqual(configuration.time.hour, 7)
        XCTAssertEqual(configuration.time.minute, 0)
        
        // Check repeat pattern
        if case .weekdays(let weekdays) = configuration.repeatOption {
            XCTAssertTrue(weekdays.contains(.monday))
            XCTAssertTrue(weekdays.contains(.wednesday))
            XCTAssertTrue(weekdays.contains(.friday))
        } else {
            XCTFail("Expected specific weekdays")
        }
        
        // Check activity
        XCTAssertEqual(configuration.label, "Yoga")
        XCTAssertEqual(configuration.icon, "figure.yoga")
        
        // Check countdown
        XCTAssertNotNil(configuration.countdown)
        XCTAssertEqual(configuration.countdown?.minutes, 10)
    }
    
    func testComplexInput_MedicationReminder() async throws {
        let input = "Remind me to take medication at 9am and 9pm daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        // Check activity
        XCTAssertEqual(configuration.label, "Medication")
        XCTAssertEqual(configuration.icon, "pills")
        XCTAssertEqual(configuration.colorHex, "#EF4444")
        
        // Check repeat pattern
        if case .daily = configuration.repeatOption {
            // Success
        } else {
            XCTFail("Expected daily repeat")
        }
    }
    
    // MARK: - Parser Integration Tests
    
    func testParserIntegration_ValidConfiguration() async throws {
        let input = "Wake up at 7am every weekday"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        let ticker = parser.parseToTicker(from: configuration)
        
        XCTAssertEqual(ticker.label, "Wake Up")
        XCTAssertTrue(ticker.isEnabled)
        XCTAssertNotNil(ticker.schedule)
        XCTAssertNotNil(ticker.tickerData)
    }
    
    func testParserIntegration_WithCountdown() async throws {
        let input = "Meeting at 2pm with 5 minute countdown"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        let ticker = parser.parseToTicker(from: configuration)
        
        XCTAssertNotNil(ticker.countdown)
        XCTAssertEqual(ticker.countdown?.preAlert?.minutes, 5)
    }
    
    // MARK: - Validation Tests
    
    func testValidation_ValidConfiguration() async throws {
        let input = "Wake up at 7am every weekday"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        let validation = parser.validateConfiguration(configuration)
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
    }
    
    func testValidation_InvalidTime() async throws {
        let input = "Wake up at 25am every day" // Invalid hour
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        let validation = parser.validateConfiguration(configuration)
        
        // The AI generator should handle this gracefully, but if it doesn't,
        // the validation should catch it
        if !validation.isValid {
            XCTAssertFalse(validation.errors.isEmpty)
        }
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCase_EmptyInput() async throws {
        do {
            _ = try await aiGenerator.generateTickerConfiguration(from: "")
            XCTFail("Should have thrown an error for empty input")
        } catch {
            // Expected to throw an error
        }
    }
    
    func testEdgeCase_UnclearInput() async throws {
        let input = "something random without time or activity"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        // Should provide reasonable defaults
        XCTAssertFalse(configuration.label.isEmpty)
        XCTAssertNotNil(configuration.schedule)
    }
    
    func testEdgeCase_AmbiguousTime() async throws {
        let input = "Meeting at noon"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        // Should default to 12:00 PM
        XCTAssertEqual(configuration.time.hour, 12)
        XCTAssertEqual(configuration.time.minute, 0)
    }
}
